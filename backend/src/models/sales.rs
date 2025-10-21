use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use crate::models::InventoryItem;

/// Represents a customer who purchases products.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct Customer {
    pub id: Uuid,
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub street_address: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip_code: Option<String>,
    pub country: Option<String>,
    pub latitude: Option<BigDecimal>,
    pub longitude: Option<BigDecimal>,
    pub customer_type: Option<String>, // 'retail', 'wholesale', 'restaurant', etc.
    pub tax_exempt: bool,
    pub notes: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Represents a sale transaction.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct Sale {
    pub id: Uuid,
    pub sale_number: String, // Format: SALE-YYYYMMDD-NNN
    pub customer_id: Option<Uuid>,
    pub sale_date: DateTime<Utc>,
    pub subtotal: BigDecimal,
    pub tax_amount: BigDecimal,
    pub discount_amount: BigDecimal,
    pub total_amount: BigDecimal,
    pub payment_method: Option<String>, // 'cash', 'card', 'check', 'invoice', etc.
    pub payment_status: String,         // 'completed', 'pending', 'refunded'
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Represents a line item in a sale.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct SaleItem {
    pub id: Uuid,
    pub sale_id: Uuid,
    pub inventory_id: Uuid,
    pub quantity: BigDecimal,
    pub unit_price: BigDecimal,
    pub line_total: BigDecimal,
    pub notes: Option<String>,
}

/// Sale with embedded items for convenient querying.
#[derive(Debug, SimpleObject)]
pub struct SaleWithItems {
    pub sale: Sale,
    pub items: Vec<SaleItem>,
    pub customer: Option<Customer>,
}

/// Input for creating a new customer.
#[derive(Debug, InputObject)]
pub struct CreateCustomerInput {
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub street_address: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip_code: Option<String>,
    pub country: Option<String>,
    pub latitude: Option<BigDecimal>,
    pub longitude: Option<BigDecimal>,
    pub customer_type: Option<String>,
    pub tax_exempt: Option<bool>,
    pub notes: Option<String>,
}

/// Input for updating an existing customer.
#[derive(Debug, InputObject)]
pub struct UpdateCustomerInput {
    pub id: Uuid,
    pub name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub street_address: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip_code: Option<String>,
    pub country: Option<String>,
    pub latitude: Option<BigDecimal>,
    pub longitude: Option<BigDecimal>,
    pub customer_type: Option<String>,
    pub tax_exempt: Option<bool>,
    pub notes: Option<String>,
    pub is_active: Option<bool>,
}

/// Result from customer operations.
#[derive(Debug, SimpleObject)]
pub struct CustomerResult {
    pub success: bool,
    pub message: String,
    pub customer: Option<Customer>,
}

/// Input for a single item in a sale.
#[derive(Debug, InputObject)]
pub struct SaleItemInput {
    /// ID of the inventory item being sold
    pub inventory_id: Uuid,
    /// Quantity sold
    pub quantity: BigDecimal,
    /// Price per unit at time of sale
    pub unit_price: BigDecimal,
    /// Optional notes for this line item
    pub notes: Option<String>,
}

/// Input for creating a new sale.
#[derive(Debug, InputObject)]
pub struct CreateSaleInput {
    /// Optional customer ID (can be anonymous sale)
    pub customer_id: Option<Uuid>,
    /// Sale date (defaults to now if not provided)
    pub sale_date: Option<DateTime<Utc>>,
    /// List of items being sold
    pub items: Vec<SaleItemInput>,
    /// Optional tax amount
    pub tax_amount: Option<BigDecimal>,
    /// Optional discount amount
    pub discount_amount: Option<BigDecimal>,
    /// Payment method
    pub payment_method: Option<String>,
    /// Payment status (defaults to 'completed')
    pub payment_status: Option<String>,
    /// Optional notes about the sale
    pub notes: Option<String>,
}

/// Result from creating a sale.
#[derive(Debug, SimpleObject)]
pub struct SaleResult {
    /// Whether the operation succeeded
    pub success: bool,
    /// Human-readable message
    pub message: String,
    /// ID of the created sale
    pub sale_id: Option<Uuid>,
    /// Sale number (e.g., SALE-20251015-001)
    pub sale_number: Option<String>,
    /// Inventory items that were updated (stock decremented)
    pub updated_items: Vec<InventoryItem>,
}
