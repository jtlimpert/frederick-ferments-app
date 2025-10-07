use async_graphql::*;
use bigdecimal::BigDecimal;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// Represents a production batch that converts ingredients into finished products.
///
/// A production batch tracks the consumption of ingredients and the creation
/// of finished goods, with full audit trail in inventory_logs.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct ProductionBatch {
    pub id: Uuid,
    pub batch_number: String,
    pub product_inventory_id: Uuid,
    pub recipe_template_id: Option<Uuid>,
    pub batch_size: BigDecimal,
    pub unit: String,
    pub start_date: DateTime<Utc>,
    pub estimated_completion_date: Option<DateTime<Utc>>,
    pub completion_date: Option<DateTime<Utc>>,
    pub production_date: DateTime<Utc>, // Legacy compatibility
    pub status: String,                 // 'in_progress', 'completed', 'failed'
    pub production_time_hours: Option<BigDecimal>,
    pub yield_percentage: Option<BigDecimal>,
    pub actual_yield: Option<BigDecimal>,
    pub quality_notes: Option<String>,
    pub storage_location: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Represents an ingredient used in a production batch.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct ProductionBatchIngredient {
    pub id: Uuid,
    pub batch_id: Uuid,
    pub ingredient_inventory_id: Uuid,
    pub quantity_used: BigDecimal,
    pub unit: String,
    pub notes: Option<String>,
}

/// Input for a single ingredient in a production batch.
#[derive(Debug, InputObject)]
pub struct IngredientInput {
    /// ID of the inventory item to consume
    pub inventory_id: Uuid,
    /// Quantity to consume from inventory
    pub quantity_used: BigDecimal,
}

/// Input for creating a new production batch.
#[derive(Debug, InputObject)]
pub struct CreateProductionBatchInput {
    /// ID of the product being created
    pub product_inventory_id: Uuid,
    /// Optional recipe template ID for auto-generating reminders (Phase 2)
    pub recipe_template_id: Option<Uuid>,
    /// Quantity of product expected to be created
    pub batch_size: BigDecimal,
    /// Unit of measurement for the product
    pub unit: String,
    /// Optional estimated completion date
    pub estimated_completion_date: Option<DateTime<Utc>>,
    /// Optional storage location for the batch
    pub storage_location: Option<String>,
    /// List of ingredients consumed in this batch
    pub ingredients: Vec<IngredientInput>,
    /// Optional notes about the production batch
    pub notes: Option<String>,
}

/// Input for completing a production batch.
#[derive(Debug, InputObject)]
pub struct CompleteProductionBatchInput {
    /// ID of the batch to complete
    pub batch_id: Uuid,
    /// Actual quantity produced (may differ from expected batch_size)
    pub actual_yield: BigDecimal,
    /// Optional quality notes about the finished product
    pub quality_notes: Option<String>,
}

/// Input for marking a production batch as failed.
#[derive(Debug, InputObject)]
pub struct FailProductionBatchInput {
    /// ID of the batch that failed
    pub batch_id: Uuid,
    /// Reason for the failure
    pub reason: String,
}

/// Result from creating a production batch.
#[derive(Debug, SimpleObject)]
pub struct ProductionBatchResult {
    /// Whether the operation succeeded
    pub success: bool,
    /// Result message (success or error details)
    pub message: String,
    /// ID of the created batch (if successful)
    pub batch_id: Option<Uuid>,
    /// Batch number (if successful)
    pub batch_number: Option<String>,
}

/// Represents a recipe template for repeatable production processes.
///
/// Recipe templates define the standard process for making a product,
/// including ingredient ratios and time-based reminders for each step.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct RecipeTemplate {
    pub id: Uuid,
    pub product_inventory_id: Uuid,
    pub template_name: String,
    pub description: Option<String>,
    pub default_batch_size: Option<BigDecimal>,
    pub default_unit: Option<String>,
    pub estimated_duration_hours: Option<BigDecimal>,
    /// JSONB field containing reminder schedule as array of objects
    /// Example: [{"type": "fold", "message": "First fold", "after_hours": 2}]
    pub reminder_schedule: Option<serde_json::Value>,
    /// JSONB field containing ingredient template as array of objects
    /// Example: [{"inventory_id": "uuid", "quantity_per_unit": 500, "unit": "g"}]
    pub ingredient_template: Option<serde_json::Value>,
    pub instructions: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Represents a time-based reminder for a production batch.
///
/// Reminders are auto-created when a batch is started from a recipe template,
/// and trigger at specific times relative to the batch start_date.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct ProductionReminder {
    pub id: Uuid,
    pub batch_id: Uuid,
    pub reminder_type: String,
    pub message: String,
    pub due_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub snoozed_until: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Input for snoozing a reminder.
#[derive(Debug, InputObject)]
pub struct SnoozeReminderInput {
    /// ID of the reminder to snooze
    pub reminder_id: Uuid,
    /// New time to trigger the reminder
    pub snooze_until: DateTime<Utc>,
}

/// Input for completing a reminder.
#[derive(Debug, InputObject)]
pub struct CompleteReminderInput {
    /// ID of the reminder to mark as completed
    pub reminder_id: Uuid,
    /// Optional notes about completing this step
    pub notes: Option<String>,
}

/// Result from a reminder operation.
#[derive(Debug, SimpleObject)]
pub struct ReminderResult {
    /// Whether the operation succeeded
    pub success: bool,
    /// Result message
    pub message: String,
}
