use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::Utc;
use sqlx::PgPool;

use crate::models::{
    CompleteProductionBatchInput, CreateProductionBatchInput, CreatePurchaseInput,
    DeleteInventoryItemInput, DeleteResult, FailProductionBatchInput, InventoryItem,
    ProductionBatchResult, PurchaseResult,
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
}
