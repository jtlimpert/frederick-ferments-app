use async_graphql::*;
use chrono::{DateTime, Utc};
use bigdecimal::BigDecimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct InventoryItem {
    pub id: Uuid,
    pub name: String,
    pub category: String,
    pub unit: String,
    pub current_stock: BigDecimal,           // NOT NULL
    pub reserved_stock: BigDecimal,          // NOT NULL
    pub available_stock: BigDecimal,         // Generated column
    pub reorder_point: BigDecimal,           // NOT NULL
    pub cost_per_unit: Option<BigDecimal>,   // NULL allowed
    pub default_supplier_id: Option<Uuid>,   // NULL allowed
    pub shelf_life_days: Option<i32>,        // NULL allowed
    pub storage_requirements: Option<String>,// NULL allowed
    pub is_active: bool,                     // NOT NULL
    pub created_at: DateTime<Utc>,           // NOT NULL
    pub updated_at: DateTime<Utc>,           // NOT NULL
}

#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct Supplier {
    pub id: Uuid,
    pub name: String,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub address: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Add these to the top of your inventory.rs file, after the existing structs

#[derive(Debug, InputObject)]
pub struct CreatePurchaseInput {
    pub supplier_id: Uuid,
    pub items: Vec<PurchaseItemInput>,
    pub purchase_date: Option<DateTime<Utc>>, // Defaults to now if not provided
    pub notes: Option<String>,
}

#[derive(Debug, InputObject)]
pub struct PurchaseItemInput {
    pub inventory_id: Uuid,  // Which item you're buying
    pub quantity: BigDecimal,
    pub unit_cost: BigDecimal, // Cost per unit for this purchase
    pub expiry_date: Option<chrono::NaiveDate>,
    pub batch_number: Option<String>,
}

#[derive(Debug, SimpleObject)]
pub struct PurchaseResult {
    pub success: bool,
    pub message: String,
    pub updated_items: Vec<InventoryItem>,
}