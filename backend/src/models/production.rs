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
    /// Optional recipe template ID
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
/// including ingredient ratios.
#[derive(Debug, Clone, FromRow, SimpleObject, Serialize, Deserialize)]
pub struct RecipeTemplate {
    pub id: Uuid,
    pub product_inventory_id: Uuid,
    pub template_name: String,
    pub description: Option<String>,
    pub default_batch_size: Option<BigDecimal>,
    pub default_unit: Option<String>,
    pub estimated_duration_hours: Option<BigDecimal>,
    /// JSONB field containing ingredient template as array of objects
    /// Example: [{"inventory_id": "uuid", "quantity_per_unit": 500, "unit": "g"}]
    pub ingredient_template: Option<serde_json::Value>,
    pub instructions: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Input for creating a new recipe template.
#[derive(Debug, InputObject)]
pub struct CreateRecipeTemplateInput {
    /// ID of the product this recipe creates
    pub product_inventory_id: Uuid,
    /// Name of the recipe template
    pub template_name: String,
    /// Optional description of the recipe
    pub description: Option<String>,
    /// Default batch size for this recipe
    pub default_batch_size: Option<BigDecimal>,
    /// Unit of measurement for the default batch size
    pub default_unit: Option<String>,
    /// Estimated time to complete in hours
    pub estimated_duration_hours: Option<BigDecimal>,
    /// JSONB ingredient template structure
    /// Format: {"ingredients": [{"inventory_id": "uuid", "quantity_per_batch": 0.5, "unit": "kg"}]}
    pub ingredient_template: Option<serde_json::Value>,
    /// Step-by-step instructions
    pub instructions: Option<String>,
}

/// Input for updating an existing recipe template.
#[derive(Debug, InputObject)]
pub struct UpdateRecipeTemplateInput {
    /// ID of the recipe template to update
    pub id: Uuid,
    /// Optional new product ID
    pub product_inventory_id: Option<Uuid>,
    /// Optional new template name
    pub template_name: Option<String>,
    /// Optional new description
    pub description: Option<String>,
    /// Optional new default batch size
    pub default_batch_size: Option<BigDecimal>,
    /// Optional new unit
    pub default_unit: Option<String>,
    /// Optional new estimated duration
    pub estimated_duration_hours: Option<BigDecimal>,
    /// Optional new ingredient template
    pub ingredient_template: Option<serde_json::Value>,
    /// Optional new instructions
    pub instructions: Option<String>,
}

/// Input for deleting a recipe template.
#[derive(Debug, InputObject)]
pub struct DeleteRecipeTemplateInput {
    /// ID of the recipe template to delete
    pub id: Uuid,
}

/// Result from creating or updating a recipe template.
#[derive(Debug, SimpleObject)]
pub struct RecipeTemplateResult {
    /// Whether the operation succeeded
    pub success: bool,
    /// Result message (success or error details)
    pub message: String,
    /// The created or updated recipe template (if successful)
    pub recipe: Option<RecipeTemplate>,
}
