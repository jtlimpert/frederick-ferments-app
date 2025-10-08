use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::models::{InventoryItem, ProductionBatch, RecipeTemplate, Supplier};

pub struct QueryRoot;

#[derive(async_graphql::SimpleObject)]
pub struct HealthCheck {
    pub status: String,
    pub timestamp: DateTime<Utc>,
    pub database_connected: bool,
    pub version: String,
    pub uptime_seconds: f64,
}

#[Object]
impl QueryRoot {
    /// Health Check
    async fn health_check(&self, ctx: &Context<'_>) -> Result<HealthCheck> {
        let pool = ctx.data::<PgPool>()?;
        // ✅ This handles the borrowing correctly
        let uptime = match ctx.data::<std::time::Instant>() {
            Ok(start_time) => start_time.elapsed().as_secs_f64(),
            Err(_) => 0.0, // Fallback if start_time not available
        };

        // Test database connection
        let database_connected = sqlx::query("SELECT 1").fetch_one(pool).await.is_ok();

        Ok(HealthCheck {
            status: if database_connected {
                "healthy".to_string()
            } else {
                "unhealthy".to_string()
            },
            timestamp: Utc::now(),
            database_connected,
            version: env!("CARGO_PKG_VERSION").to_string(),
            uptime_seconds: uptime,
        })
    }

    async fn ping(&self) -> String {
        "pong".to_string()
    }
    /// Get all inventory items
    async fn inventory_items(&self, ctx: &Context<'_>) -> Result<Vec<InventoryItem>> {
        let pool = ctx.data::<PgPool>()?;

        let items = sqlx::query_as!(
            InventoryItem,
            "SELECT
                id,
                name,
                category,
                unit,
                current_stock,
                reserved_stock,
                available_stock as \"available_stock!: BigDecimal\",
                reorder_point,
                cost_per_unit,
                default_supplier_id,
                shelf_life_days,
                storage_requirements,
                is_active,
                created_at,
                updated_at
            FROM inventory
            WHERE is_active = true
            ORDER BY name"
        )
        .fetch_all(pool)
        .await?;

        Ok(items)
    }

    /// Get all suppliers
    async fn suppliers(&self, ctx: &Context<'_>) -> Result<Vec<Supplier>> {
        let pool = ctx.data::<PgPool>()?;

        let suppliers = sqlx::query_as!(
            Supplier,
            "SELECT id, name, contact_email, contact_phone, address, latitude, longitude, notes, created_at, updated_at FROM suppliers ORDER BY name"
        )
        .fetch_all(pool)
        .await?;

        Ok(suppliers)
    }

    /// Get all active production batches (in_progress status)
    async fn active_batches(&self, ctx: &Context<'_>) -> Result<Vec<ProductionBatch>> {
        let pool = ctx.data::<PgPool>()?;

        let batches = sqlx::query_as!(
            ProductionBatch,
            r#"
            SELECT
                id, batch_number, product_inventory_id, recipe_template_id,
                batch_size, unit, start_date, estimated_completion_date,
                completion_date, production_date, status,
                production_time_hours, yield_percentage, actual_yield,
                quality_notes, storage_location, notes,
                created_at, updated_at
            FROM production_batches
            WHERE status = 'in_progress'
            ORDER BY start_date DESC
            "#
        )
        .fetch_all(pool)
        .await?;

        Ok(batches)
    }

    /// Get a specific production batch by ID
    async fn production_batch(
        &self,
        ctx: &Context<'_>,
        id: uuid::Uuid,
    ) -> Result<Option<ProductionBatch>> {
        let pool = ctx.data::<PgPool>()?;

        let batch = sqlx::query_as!(
            ProductionBatch,
            r#"
            SELECT
                id, batch_number, product_inventory_id, recipe_template_id,
                batch_size, unit, start_date, estimated_completion_date,
                completion_date, production_date, status,
                production_time_hours, yield_percentage, actual_yield,
                quality_notes, storage_location, notes,
                created_at, updated_at
            FROM production_batches
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(pool)
        .await?;

        Ok(batch)
    }

    /// Get production history with optional filters
    async fn production_history(
        &self,
        ctx: &Context<'_>,
        product_inventory_id: Option<uuid::Uuid>,
        limit: Option<i32>,
    ) -> Result<Vec<ProductionBatch>> {
        let pool = ctx.data::<PgPool>()?;
        let limit = limit.unwrap_or(50).min(500); // Default 50, max 500

        let batches = if let Some(product_id) = product_inventory_id {
            sqlx::query_as!(
                ProductionBatch,
                r#"
                SELECT
                    id, batch_number, product_inventory_id, recipe_template_id,
                    batch_size, unit, start_date, estimated_completion_date,
                    completion_date, production_date, status,
                    production_time_hours, yield_percentage, actual_yield,
                    quality_notes, storage_location, notes,
                    created_at, updated_at
                FROM production_batches
                WHERE product_inventory_id = $1
                ORDER BY start_date DESC
                LIMIT $2
                "#,
                product_id,
                limit as i64
            )
            .fetch_all(pool)
            .await?
        } else {
            sqlx::query_as!(
                ProductionBatch,
                r#"
                SELECT
                    id, batch_number, product_inventory_id, recipe_template_id,
                    batch_size, unit, start_date, estimated_completion_date,
                    completion_date, production_date, status,
                    production_time_hours, yield_percentage, actual_yield,
                    quality_notes, storage_location, notes,
                    created_at, updated_at
                FROM production_batches
                ORDER BY start_date DESC
                LIMIT $1
                "#,
                limit as i64
            )
            .fetch_all(pool)
            .await?
        };

        Ok(batches)
    }

    /// Get all active recipe templates
    async fn recipe_templates(&self, ctx: &Context<'_>) -> Result<Vec<RecipeTemplate>> {
        let pool = ctx.data::<PgPool>()?;

        let templates = sqlx::query_as!(
            RecipeTemplate,
            r#"
            SELECT
                id, product_inventory_id, template_name, description,
                default_batch_size, default_unit, estimated_duration_hours,
                ingredient_template, instructions,
                is_active as "is_active!", created_at, updated_at
            FROM recipe_templates
            WHERE is_active = true
            ORDER BY template_name
            "#
        )
        .fetch_all(pool)
        .await?;

        Ok(templates)
    }

    /// Get a specific recipe template by ID
    async fn recipe_template(
        &self,
        ctx: &Context<'_>,
        id: uuid::Uuid,
    ) -> Result<Option<RecipeTemplate>> {
        let pool = ctx.data::<PgPool>()?;

        let template = sqlx::query_as!(
            RecipeTemplate,
            r#"
            SELECT
                id, product_inventory_id, template_name, description,
                default_batch_size, default_unit, estimated_duration_hours,
                ingredient_template, instructions,
                is_active as "is_active!", created_at, updated_at
            FROM recipe_templates
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(pool)
        .await?;

        Ok(template)
    }
}
