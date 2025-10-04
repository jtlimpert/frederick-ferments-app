use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::Utc;
use sqlx::PgPool;

use crate::models::{CreatePurchaseInput, InventoryItem, PurchaseResult};

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
            // 1. Add entry to inventory_log
            sqlx::query(
                r#"
                INSERT INTO inventory_log (
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
}
