use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::models::{InventoryItem, Supplier};

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
}
