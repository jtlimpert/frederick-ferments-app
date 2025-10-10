use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::Utc;
use sqlx::PgPool;

use crate::models::{
    CompleteProductionBatchInput, CreateInventoryItemInput, CreateProductionBatchInput,
    CreatePurchaseInput, CreateRecipeTemplateInput, CreateSupplierInput, DeleteInventoryItemInput,
    DeleteRecipeTemplateInput, DeleteResult, FailProductionBatchInput, InventoryItem,
    InventoryItemResult, ProductionBatchResult, PurchaseResult, RecipeTemplate,
    RecipeTemplateResult, Supplier, SupplierResult, UpdateInventoryItemInput,
    UpdateRecipeTemplateInput, UpdateSupplierInput,
};

pub struct MutationRoot;

#[Object]
impl MutationRoot {
    /// Create a new purchase and update inventory
    async fn create_purchase(
        &self,
        ctx: &Context<'_>,
        input: CreatePurchaseInput,
    ) -> Result<PurchaseResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        let purchase_date = input.purchase_date.unwrap_or_else(Utc::now);
        let mut updated_items = Vec::new();

        // Process each item in the purchase
        for item_input in input.items {
            // 1. Add entry to inventory_logs
            sqlx::query(
                r#"
                INSERT INTO inventory_logs (
                    inventory_id, movement_type, quantity, unit_cost,
                    reason, batch_number, expiry_date, created_at
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                "#,
            )
            .bind(item_input.inventory_id)
            .bind("purchase")
            .bind(&item_input.quantity)
            .bind(&item_input.unit_cost)
            .bind(input.notes.as_deref().unwrap_or("Purchase"))
            .bind(&item_input.batch_number)
            .bind(item_input.expiry_date)
            .bind(purchase_date)
            .execute(&mut *tx)
            .await?;

            // 2. Update inventory stock and cost
            let updated_item = sqlx::query_as!(
                InventoryItem,
                r#"
                UPDATE inventory
                SET
                    current_stock = current_stock + $1,
                    cost_per_unit = $2,
                    updated_at = $3
                WHERE id = $4
                RETURNING
                    id,
                    name,
                    category,
                    unit,
                    current_stock as "current_stock!: BigDecimal",
                    reserved_stock as "reserved_stock!: BigDecimal",
                    available_stock as "available_stock!: BigDecimal",
                    reorder_point as "reorder_point!: BigDecimal",
                    cost_per_unit as "cost_per_unit?: BigDecimal",
                    default_supplier_id,
                    shelf_life_days,
                    storage_requirements,
                    is_active,
                    created_at,
                    updated_at
                "#,
                item_input.quantity,
                Some(item_input.unit_cost),
                purchase_date,
                item_input.inventory_id
            )
            .fetch_one(&mut *tx)
            .await?;

            updated_items.push(updated_item);
        }

        // Commit the transaction
        tx.commit().await?;

        Ok(PurchaseResult {
            success: true,
            message: format!(
                "Successfully processed purchase of {} items",
                updated_items.len()
            ),
            updated_items,
        })
    }

    /// Create a new production batch that consumes ingredients and produces finished goods
    async fn create_production_batch(
        &self,
        ctx: &Context<'_>,
        input: CreateProductionBatchInput,
    ) -> Result<ProductionBatchResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // Validate batch size is positive
        if input.batch_size <= BigDecimal::from(0) {
            return Ok(ProductionBatchResult {
                success: false,
                message: "Batch size must be greater than 0".to_string(),
                batch_id: None,
                batch_number: None,
            });
        }

        // Validate at least one ingredient
        if input.ingredients.is_empty() {
            return Ok(ProductionBatchResult {
                success: false,
                message: "At least one ingredient is required".to_string(),
                batch_id: None,
                batch_number: None,
            });
        }

        // 1. Validate product exists
        let product = sqlx::query!(
            "SELECT name FROM inventory WHERE id = $1 AND is_active = true",
            input.product_inventory_id
        )
        .fetch_optional(&mut *tx)
        .await?;

        if product.is_none() {
            return Ok(ProductionBatchResult {
                success: false,
                message: "Product not found or is inactive".to_string(),
                batch_id: None,
                batch_number: None,
            });
        }

        // 2. Validate all ingredients exist and have sufficient stock
        for ingredient in &input.ingredients {
            if ingredient.quantity_used <= BigDecimal::from(0) {
                return Ok(ProductionBatchResult {
                    success: false,
                    message: "All ingredient quantities must be greater than 0".to_string(),
                    batch_id: None,
                    batch_number: None,
                });
            }

            let inv = sqlx::query!(
                "SELECT name, current_stock FROM inventory WHERE id = $1 AND is_active = true",
                ingredient.inventory_id
            )
            .fetch_optional(&mut *tx)
            .await?;

            match inv {
                None => {
                    return Ok(ProductionBatchResult {
                        success: false,
                        message: format!(
                            "Ingredient with ID {} not found or is inactive",
                            ingredient.inventory_id
                        ),
                        batch_id: None,
                        batch_number: None,
                    });
                }
                Some(inv_item) => {
                    if inv_item.current_stock < ingredient.quantity_used {
                        return Ok(ProductionBatchResult {
                            success: false,
                            message: format!(
                                "Insufficient stock for {}: need {}, have {}",
                                inv_item.name, ingredient.quantity_used, inv_item.current_stock
                            ),
                            batch_id: None,
                            batch_number: None,
                        });
                    }
                }
            }
        }

        // 3. Generate batch number (format: BATCH-YYYYMMDD-NNN)
        let today = Utc::now();
        let date_prefix = today.format("%Y%m%d").to_string();
        let batch_prefix = format!("BATCH-{}", date_prefix);

        // Find the next sequence number for today
        let last_batch = sqlx::query!(
            "SELECT batch_number FROM production_batches WHERE batch_number LIKE $1 ORDER BY batch_number DESC LIMIT 1",
            format!("{}-%", batch_prefix)
        )
        .fetch_optional(&mut *tx)
        .await?;

        let sequence = match last_batch {
            Some(batch) => {
                // Extract sequence number from BATCH-YYYYMMDD-NNN
                let parts: Vec<&str> = batch.batch_number.split('-').collect();
                if parts.len() == 3 {
                    parts[2].parse::<i32>().unwrap_or(0) + 1
                } else {
                    1
                }
            }
            None => 1,
        };

        let batch_number = format!("{}-{:03}", batch_prefix, sequence);

        // 4. Create production_batch record
        let batch_id = sqlx::query_scalar!(
            r#"
            INSERT INTO production_batches (
                batch_number, product_inventory_id, recipe_template_id, batch_size, unit,
                start_date, estimated_completion_date, production_date, status,
                storage_location, notes
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING id
            "#,
            batch_number,
            input.product_inventory_id,
            input.recipe_template_id,
            input.batch_size,
            input.unit,
            today,
            input.estimated_completion_date,
            today,         // Legacy field
            "in_progress", // Start as in-progress, complete manually later
            input.storage_location,
            input.notes
        )
        .fetch_one(&mut *tx)
        .await?;

        // 5. Process each ingredient: consume stock and log
        for ingredient in &input.ingredients {
            // Get ingredient unit
            let inv = sqlx::query!(
                "SELECT unit FROM inventory WHERE id = $1",
                ingredient.inventory_id
            )
            .fetch_one(&mut *tx)
            .await?;

            // Create production_batch_ingredients record
            sqlx::query!(
                "INSERT INTO production_batch_ingredients (batch_id, ingredient_inventory_id, quantity_used, unit) VALUES ($1, $2, $3, $4)",
                batch_id,
                ingredient.inventory_id,
                ingredient.quantity_used,
                inv.unit
            )
            .execute(&mut *tx)
            .await?;

            // Decrease ingredient stock
            sqlx::query!(
                "UPDATE inventory SET current_stock = current_stock - $1, updated_at = $2 WHERE id = $3",
                ingredient.quantity_used,
                today,
                ingredient.inventory_id
            )
            .execute(&mut *tx)
            .await?;

            // Log ingredient consumption
            sqlx::query!(
                r#"
                INSERT INTO inventory_logs (
                    inventory_id, movement_type, quantity, reason, batch_number, created_at
                ) VALUES ($1, $2, $3, $4, $5, $6)
                "#,
                ingredient.inventory_id,
                "production_use",
                -ingredient.quantity_used.clone(), // Negative because it's consumption
                format!("Used in production batch {}", batch_number),
                batch_number,
                today
            )
            .execute(&mut *tx)
            .await?;
        }

        // 6. Commit transaction (product will be added when batch is completed)
        tx.commit().await?;

        Ok(ProductionBatchResult {
            success: true,
            message: format!(
                "Successfully created production batch {} with {} ingredients",
                batch_number,
                input.ingredients.len()
            ),
            batch_id: Some(batch_id),
            batch_number: Some(batch_number),
        })
    }

    /// Complete a production batch and add finished product to inventory
    async fn complete_production_batch(
        &self,
        ctx: &Context<'_>,
        input: CompleteProductionBatchInput,
    ) -> Result<ProductionBatchResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // 1. Get batch details
        let batch = sqlx::query!(
            r#"
            SELECT batch_number, product_inventory_id, batch_size, status, start_date
            FROM production_batches
            WHERE id = $1
            "#,
            input.batch_id
        )
        .fetch_optional(&mut *tx)
        .await?;

        let batch = match batch {
            Some(b) => b,
            None => {
                return Ok(ProductionBatchResult {
                    success: false,
                    message: "Production batch not found".to_string(),
                    batch_id: None,
                    batch_number: None,
                });
            }
        };

        if batch.status != "in_progress" {
            return Ok(ProductionBatchResult {
                success: false,
                message: format!("Batch is already {}", batch.status),
                batch_id: None,
                batch_number: Some(batch.batch_number.clone()),
            });
        }

        // 2. Calculate yield percentage and production time
        let yield_pct = if batch.batch_size > BigDecimal::from(0) {
            (&input.actual_yield / &batch.batch_size) * BigDecimal::from(100)
        } else {
            BigDecimal::from(100)
        };

        let now = Utc::now();
        let duration_hours = BigDecimal::from((now - batch.start_date).num_hours().max(0));

        // 3. Update batch status
        sqlx::query!(
            r#"
            UPDATE production_batches
            SET status = 'completed',
                completion_date = $1,
                actual_yield = $2,
                yield_percentage = $3,
                production_time_hours = $4,
                quality_notes = $5,
                updated_at = $1
            WHERE id = $6
            "#,
            now,
            input.actual_yield,
            yield_pct,
            duration_hours,
            input.quality_notes,
            input.batch_id
        )
        .execute(&mut *tx)
        .await?;

        // 4. Add finished product to inventory
        sqlx::query!(
            "UPDATE inventory SET current_stock = current_stock + $1, updated_at = $2 WHERE id = $3",
            input.actual_yield,
            now,
            batch.product_inventory_id
        )
        .execute(&mut *tx)
        .await?;

        // 5. Log production output
        sqlx::query!(
            r#"
            INSERT INTO inventory_logs (
                inventory_id, movement_type, quantity, reason, batch_number, created_at
            ) VALUES ($1, $2, $3, $4, $5, $6)
            "#,
            batch.product_inventory_id,
            "production_output",
            input.actual_yield,
            format!("Produced in batch {}", batch.batch_number),
            batch.batch_number,
            now
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(ProductionBatchResult {
            success: true,
            message: format!(
                "Successfully completed production batch {}. Yield: {:.1}%",
                batch.batch_number, yield_pct
            ),
            batch_id: Some(input.batch_id),
            batch_number: Some(batch.batch_number),
        })
    }

    /// Mark a production batch as failed
    async fn fail_production_batch(
        &self,
        ctx: &Context<'_>,
        input: FailProductionBatchInput,
    ) -> Result<ProductionBatchResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // 1. Get batch details
        let batch = sqlx::query!(
            r#"
            SELECT batch_number, status
            FROM production_batches
            WHERE id = $1
            "#,
            input.batch_id
        )
        .fetch_optional(&mut *tx)
        .await?;

        let batch = match batch {
            Some(b) => b,
            None => {
                return Ok(ProductionBatchResult {
                    success: false,
                    message: "Production batch not found".to_string(),
                    batch_id: None,
                    batch_number: None,
                });
            }
        };

        if batch.status != "in_progress" {
            return Ok(ProductionBatchResult {
                success: false,
                message: format!("Batch is already {}", batch.status),
                batch_id: None,
                batch_number: Some(batch.batch_number.clone()),
            });
        }

        // 2. Update batch status
        let now = Utc::now();
        sqlx::query!(
            r#"
            UPDATE production_batches
            SET status = 'failed',
                completion_date = $1,
                quality_notes = $2,
                updated_at = $1
            WHERE id = $3
            "#,
            now,
            input.reason,
            input.batch_id
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(ProductionBatchResult {
            success: true,
            message: format!("Production batch {} marked as failed", batch.batch_number),
            batch_id: Some(input.batch_id),
            batch_number: Some(batch.batch_number),
        })
    }

    /// Create a new inventory item
    async fn create_inventory_item(
        &self,
        ctx: &Context<'_>,
        input: CreateInventoryItemInput,
    ) -> Result<InventoryItemResult> {
        let pool = ctx.data::<PgPool>()?;

        // Check if name already exists
        let existing = sqlx::query!(
            "SELECT id FROM inventory WHERE name = $1 AND is_active = true",
            input.name
        )
        .fetch_optional(pool)
        .await?;

        if existing.is_some() {
            return Ok(InventoryItemResult {
                success: false,
                message: format!("An item with the name '{}' already exists", input.name),
                item: None,
            });
        }

        // Validate supplier_id if provided
        if let Some(supplier_id) = input.default_supplier_id {
            let supplier_exists =
                sqlx::query!("SELECT id FROM suppliers WHERE id = $1", supplier_id)
                    .fetch_optional(pool)
                    .await?;

            if supplier_exists.is_none() {
                return Ok(InventoryItemResult {
                    success: false,
                    message: "Supplier not found".to_string(),
                    item: None,
                });
            }
        }

        let now = Utc::now();
        let current_stock = input.current_stock.unwrap_or(BigDecimal::from(0));
        let reserved_stock = input.reserved_stock.unwrap_or(BigDecimal::from(0));
        let reorder_point = input.reorder_point.unwrap_or(BigDecimal::from(0));

        // Create the inventory item
        let item = sqlx::query_as!(
            InventoryItem,
            r#"
            INSERT INTO inventory (
                name, category, unit, current_stock, reserved_stock, reorder_point,
                cost_per_unit, default_supplier_id, shelf_life_days, storage_requirements,
                is_active, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, true, $11, $11)
            RETURNING
                id,
                name,
                category,
                unit,
                current_stock as "current_stock!: BigDecimal",
                reserved_stock as "reserved_stock!: BigDecimal",
                available_stock as "available_stock!: BigDecimal",
                reorder_point as "reorder_point!: BigDecimal",
                cost_per_unit as "cost_per_unit?: BigDecimal",
                default_supplier_id,
                shelf_life_days,
                storage_requirements,
                is_active,
                created_at,
                updated_at
            "#,
            input.name,
            input.category,
            input.unit,
            current_stock,
            reserved_stock,
            reorder_point,
            input.cost_per_unit,
            input.default_supplier_id,
            input.shelf_life_days,
            input.storage_requirements,
            now
        )
        .fetch_one(pool)
        .await?;

        Ok(InventoryItemResult {
            success: true,
            message: format!("Successfully created '{}'", item.name),
            item: Some(item),
        })
    }

    /// Update an existing inventory item
    async fn update_inventory_item(
        &self,
        ctx: &Context<'_>,
        input: UpdateInventoryItemInput,
    ) -> Result<InventoryItemResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // Check if item exists
        let existing = sqlx::query!("SELECT name FROM inventory WHERE id = $1", input.id)
            .fetch_optional(&mut *tx)
            .await?;

        if existing.is_none() {
            return Ok(InventoryItemResult {
                success: false,
                message: "Inventory item not found".to_string(),
                item: None,
            });
        }

        // Check if new name conflicts with existing items (if name is being changed)
        if let Some(ref new_name) = input.name {
            let name_conflict = sqlx::query!(
                "SELECT id FROM inventory WHERE name = $1 AND id != $2 AND is_active = true",
                new_name,
                input.id
            )
            .fetch_optional(&mut *tx)
            .await?;

            if name_conflict.is_some() {
                return Ok(InventoryItemResult {
                    success: false,
                    message: format!("An item with the name '{}' already exists", new_name),
                    item: None,
                });
            }
        }

        // Validate supplier_id if provided
        if let Some(supplier_id) = input.default_supplier_id {
            let supplier_exists =
                sqlx::query!("SELECT id FROM suppliers WHERE id = $1", supplier_id)
                    .fetch_optional(&mut *tx)
                    .await?;

            if supplier_exists.is_none() {
                return Ok(InventoryItemResult {
                    success: false,
                    message: "Supplier not found".to_string(),
                    item: None,
                });
            }
        }

        let now = Utc::now();

        // Build update query dynamically based on provided fields
        // For simplicity, we'll use COALESCE to keep existing values if new ones aren't provided
        let item = sqlx::query_as!(
            InventoryItem,
            r#"
            UPDATE inventory
            SET
                name = COALESCE($2, name),
                category = COALESCE($3, category),
                unit = COALESCE($4, unit),
                current_stock = COALESCE($5, current_stock),
                reserved_stock = COALESCE($6, reserved_stock),
                reorder_point = COALESCE($7, reorder_point),
                cost_per_unit = COALESCE($8, cost_per_unit),
                default_supplier_id = COALESCE($9, default_supplier_id),
                shelf_life_days = COALESCE($10, shelf_life_days),
                storage_requirements = COALESCE($11, storage_requirements),
                is_active = COALESCE($12, is_active),
                updated_at = $13
            WHERE id = $1
            RETURNING
                id,
                name,
                category,
                unit,
                current_stock as "current_stock!: BigDecimal",
                reserved_stock as "reserved_stock!: BigDecimal",
                available_stock as "available_stock!: BigDecimal",
                reorder_point as "reorder_point!: BigDecimal",
                cost_per_unit as "cost_per_unit?: BigDecimal",
                default_supplier_id,
                shelf_life_days,
                storage_requirements,
                is_active,
                created_at,
                updated_at
            "#,
            input.id,
            input.name,
            input.category,
            input.unit,
            input.current_stock,
            input.reserved_stock,
            input.reorder_point,
            input.cost_per_unit,
            input.default_supplier_id,
            input.shelf_life_days,
            input.storage_requirements,
            input.is_active,
            now
        )
        .fetch_one(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(InventoryItemResult {
            success: true,
            message: format!("Successfully updated '{}'", item.name),
            item: Some(item),
        })
    }

    /// Delete an inventory item (hard delete)
    /// Use this for accidental additions or items that have gone completely bad
    async fn delete_inventory_item(
        &self,
        ctx: &Context<'_>,
        input: DeleteInventoryItemInput,
    ) -> Result<DeleteResult> {
        let pool = ctx.data::<PgPool>()?;

        // Begin transaction
        let mut tx = pool.begin().await?;

        // Check if item exists and has no dependencies
        let item = sqlx::query!(
            "SELECT name FROM inventory WHERE id = $1",
            input.inventory_id
        )
        .fetch_optional(&mut *tx)
        .await?;

        let item = match item {
            Some(i) => i,
            None => {
                return Ok(DeleteResult {
                    success: false,
                    message: "Inventory item not found".to_string(),
                });
            }
        };

        // Check for active production batches using this item
        let active_batches = sqlx::query!(
            r#"
            SELECT COUNT(*) as count
            FROM production_batch_ingredients
            JOIN production_batches ON production_batch_ingredients.batch_id = production_batches.id
            WHERE production_batch_ingredients.ingredient_inventory_id = $1
                AND production_batches.status = 'in_progress'
            "#,
            input.inventory_id
        )
        .fetch_one(&mut *tx)
        .await?;

        if active_batches.count.unwrap_or(0) > 0 {
            return Ok(DeleteResult {
                success: false,
                message: format!(
                    "Cannot delete '{}': item is used in active production batches",
                    item.name
                ),
            });
        }

        // Delete the inventory item (cascading will handle related records)
        sqlx::query!("DELETE FROM inventory WHERE id = $1", input.inventory_id)
            .execute(&mut *tx)
            .await?;

        // Commit transaction
        tx.commit().await?;

        Ok(DeleteResult {
            success: true,
            message: format!("Successfully deleted '{}'", item.name),
        })
    }

    /// Create a new supplier
    async fn create_supplier(
        &self,
        ctx: &Context<'_>,
        input: CreateSupplierInput,
    ) -> Result<SupplierResult> {
        let pool = ctx.data::<PgPool>()?;

        // Check if name already exists
        let existing = sqlx::query!("SELECT id FROM suppliers WHERE name = $1", input.name)
            .fetch_optional(pool)
            .await?;

        if existing.is_some() {
            return Ok(SupplierResult {
                success: false,
                message: format!("A supplier with the name '{}' already exists", input.name),
                supplier: None,
            });
        }

        let now = Utc::now();

        // Create the supplier
        let supplier = sqlx::query_as!(
            Supplier,
            r#"
            INSERT INTO suppliers (
                name, contact_email, contact_phone, street_address, city, state, zip_code, country,
                latitude, longitude, notes, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $12)
            RETURNING
                id,
                name,
                contact_email,
                contact_phone,
                street_address,
                city,
                state,
                zip_code,
                country,
                latitude as "latitude?: BigDecimal",
                longitude as "longitude?: BigDecimal",
                notes,
                created_at,
                updated_at
            "#,
            input.name,
            input.contact_email,
            input.contact_phone,
            input.street_address,
            input.city,
            input.state,
            input.zip_code,
            input.country,
            input.latitude,
            input.longitude,
            input.notes,
            now
        )
        .fetch_one(pool)
        .await?;

        Ok(SupplierResult {
            success: true,
            message: format!("Successfully created '{}'", supplier.name),
            supplier: Some(supplier),
        })
    }

    /// Update an existing supplier
    async fn update_supplier(
        &self,
        ctx: &Context<'_>,
        input: UpdateSupplierInput,
    ) -> Result<SupplierResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // Check if supplier exists
        let existing = sqlx::query!("SELECT name FROM suppliers WHERE id = $1", input.id)
            .fetch_optional(&mut *tx)
            .await?;

        if existing.is_none() {
            return Ok(SupplierResult {
                success: false,
                message: "Supplier not found".to_string(),
                supplier: None,
            });
        }

        // Check if new name conflicts with existing suppliers (if name is being changed)
        if let Some(ref new_name) = input.name {
            let name_conflict = sqlx::query!(
                "SELECT id FROM suppliers WHERE name = $1 AND id != $2",
                new_name,
                input.id
            )
            .fetch_optional(&mut *tx)
            .await?;

            if name_conflict.is_some() {
                return Ok(SupplierResult {
                    success: false,
                    message: format!("A supplier with the name '{}' already exists", new_name),
                    supplier: None,
                });
            }
        }

        let now = Utc::now();

        // Build update query dynamically based on provided fields
        let supplier = sqlx::query_as!(
            Supplier,
            r#"
            UPDATE suppliers
            SET
                name = COALESCE($2, name),
                contact_email = COALESCE($3, contact_email),
                contact_phone = COALESCE($4, contact_phone),
                street_address = COALESCE($5, street_address),
                city = COALESCE($6, city),
                state = COALESCE($7, state),
                zip_code = COALESCE($8, zip_code),
                country = COALESCE($9, country),
                latitude = COALESCE($10, latitude),
                longitude = COALESCE($11, longitude),
                notes = COALESCE($12, notes),
                updated_at = $13
            WHERE id = $1
            RETURNING
                id,
                name,
                contact_email,
                contact_phone,
                street_address,
                city,
                state,
                zip_code,
                country,
                latitude as "latitude?: BigDecimal",
                longitude as "longitude?: BigDecimal",
                notes,
                created_at,
                updated_at
            "#,
            input.id,
            input.name,
            input.contact_email,
            input.contact_phone,
            input.street_address,
            input.city,
            input.state,
            input.zip_code,
            input.country,
            input.latitude,
            input.longitude,
            input.notes,
            now
        )
        .fetch_one(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(SupplierResult {
            success: true,
            message: format!("Successfully updated '{}'", supplier.name),
            supplier: Some(supplier),
        })
    }

    /// Create a new recipe template
    async fn create_recipe_template(
        &self,
        ctx: &Context<'_>,
        input: CreateRecipeTemplateInput,
    ) -> Result<RecipeTemplateResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // Validate product exists and is active
        let product = sqlx::query!(
            r#"SELECT id, name FROM inventory WHERE id = $1 AND is_active = true"#,
            input.product_inventory_id
        )
        .fetch_optional(&mut *tx)
        .await?;

        if product.is_none() {
            return Ok(RecipeTemplateResult {
                success: false,
                message: "Product not found or is inactive".to_string(),
                recipe: None,
            });
        }

        // Insert new recipe template
        let recipe = sqlx::query_as!(
            RecipeTemplate,
            r#"
            INSERT INTO recipe_templates (
                product_inventory_id, template_name, description,
                default_batch_size, default_unit, estimated_duration_hours,
                ingredient_template, instructions, is_active
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)
            RETURNING
                id, product_inventory_id, template_name, description,
                default_batch_size, default_unit, estimated_duration_hours,
                ingredient_template, instructions,
                is_active as "is_active!", created_at, updated_at
            "#,
            input.product_inventory_id,
            input.template_name,
            input.description,
            input.default_batch_size,
            input.default_unit,
            input.estimated_duration_hours,
            input.ingredient_template,
            input.instructions
        )
        .fetch_one(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(RecipeTemplateResult {
            success: true,
            message: format!("Successfully created recipe '{}'", recipe.template_name),
            recipe: Some(recipe),
        })
    }

    /// Update an existing recipe template
    async fn update_recipe_template(
        &self,
        ctx: &Context<'_>,
        input: UpdateRecipeTemplateInput,
    ) -> Result<RecipeTemplateResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // Check if recipe exists
        let existing = sqlx::query!(r#"SELECT id FROM recipe_templates WHERE id = $1"#, input.id)
            .fetch_optional(&mut *tx)
            .await?;

        if existing.is_none() {
            return Ok(RecipeTemplateResult {
                success: false,
                message: "Recipe template not found".to_string(),
                recipe: None,
            });
        }

        // If updating product, validate it exists and is active
        if let Some(product_id) = input.product_inventory_id {
            let product = sqlx::query!(
                r#"SELECT id FROM inventory WHERE id = $1 AND is_active = true"#,
                product_id
            )
            .fetch_optional(&mut *tx)
            .await?;

            if product.is_none() {
                return Ok(RecipeTemplateResult {
                    success: false,
                    message: "Product not found or is inactive".to_string(),
                    recipe: None,
                });
            }
        }

        let now = Utc::now();

        // Update recipe template
        let recipe = sqlx::query_as!(
            RecipeTemplate,
            r#"
            UPDATE recipe_templates
            SET
                product_inventory_id = COALESCE($2, product_inventory_id),
                template_name = COALESCE($3, template_name),
                description = COALESCE($4, description),
                default_batch_size = COALESCE($5, default_batch_size),
                default_unit = COALESCE($6, default_unit),
                estimated_duration_hours = COALESCE($7, estimated_duration_hours),
                ingredient_template = COALESCE($8, ingredient_template),
                instructions = COALESCE($9, instructions),
                updated_at = $10
            WHERE id = $1
            RETURNING
                id, product_inventory_id, template_name, description,
                default_batch_size, default_unit, estimated_duration_hours,
                ingredient_template, instructions,
                is_active as "is_active!", created_at, updated_at
            "#,
            input.id,
            input.product_inventory_id,
            input.template_name,
            input.description,
            input.default_batch_size,
            input.default_unit,
            input.estimated_duration_hours,
            input.ingredient_template,
            input.instructions,
            now
        )
        .fetch_one(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(RecipeTemplateResult {
            success: true,
            message: format!("Successfully updated recipe '{}'", recipe.template_name),
            recipe: Some(recipe),
        })
    }

    /// Delete a recipe template (soft delete by setting is_active to false)
    async fn delete_recipe_template(
        &self,
        ctx: &Context<'_>,
        input: DeleteRecipeTemplateInput,
    ) -> Result<DeleteResult> {
        let pool = ctx.data::<PgPool>()?;
        let mut tx = pool.begin().await?;

        // Check if recipe exists
        let existing = sqlx::query!(
            r#"SELECT template_name FROM recipe_templates WHERE id = $1"#,
            input.id
        )
        .fetch_optional(&mut *tx)
        .await?;

        let Some(recipe) = existing else {
            return Ok(DeleteResult {
                success: false,
                message: "Recipe template not found".to_string(),
            });
        };

        // Check if any active production batches reference this recipe
        let active_batches = sqlx::query!(
            r#"
            SELECT COUNT(*) as count
            FROM production_batches
            WHERE recipe_template_id = $1 AND status = 'in_progress'
            "#,
            input.id
        )
        .fetch_one(&mut *tx)
        .await?;

        if active_batches.count.unwrap_or(0) > 0 {
            return Ok(DeleteResult {
                success: false,
                message: format!(
                    "Cannot delete recipe '{}': {} active production batch(es) reference it",
                    recipe.template_name,
                    active_batches.count.unwrap_or(0)
                ),
            });
        }

        // Soft delete by setting is_active to false
        sqlx::query!(
            r#"UPDATE recipe_templates SET is_active = false WHERE id = $1"#,
            input.id
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(DeleteResult {
            success: true,
            message: format!("Successfully deleted recipe '{}'", recipe.template_name),
        })
    }
}
