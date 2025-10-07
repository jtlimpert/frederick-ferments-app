/// Represents a production batch in the Frederick Ferments system.
///
/// Tracks the conversion of ingredients into finished products,
/// with full audit trail and yield tracking.
class ProductionBatch {
  /// Creates a production batch.
  const ProductionBatch({
    required this.id,
    required this.batchNumber,
    required this.productInventoryId,
    this.recipeTemplateId,
    required this.batchSize,
    required this.unit,
    required this.startDate,
    this.estimatedCompletionDate,
    this.completionDate,
    required this.productionDate,
    required this.status,
    this.productionTimeHours,
    this.yieldPercentage,
    this.actualYield,
    this.qualityNotes,
    this.storageLocation,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a production batch from GraphQL JSON response.
  factory ProductionBatch.fromJson(Map<String, dynamic> json) {
    return ProductionBatch(
      id: json['id'] as String,
      batchNumber: json['batchNumber'] as String,
      productInventoryId: json['productInventoryId'] as String,
      recipeTemplateId: json['recipeTemplateId'] as String?,
      batchSize: _parseDouble(json['batchSize']),
      unit: json['unit'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      estimatedCompletionDate: json['estimatedCompletionDate'] != null
          ? DateTime.parse(json['estimatedCompletionDate'] as String)
          : null,
      completionDate: json['completionDate'] != null
          ? DateTime.parse(json['completionDate'] as String)
          : null,
      productionDate: DateTime.parse(json['productionDate'] as String),
      status: json['status'] as String,
      productionTimeHours: json['productionTimeHours'] != null
          ? _parseDouble(json['productionTimeHours'])
          : null,
      yieldPercentage: json['yieldPercentage'] != null
          ? _parseDouble(json['yieldPercentage'])
          : null,
      actualYield: json['actualYield'] != null
          ? _parseDouble(json['actualYield'])
          : null,
      qualityNotes: json['qualityNotes'] as String?,
      storageLocation: json['storageLocation'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parses a value to double, handling both String and num types.
  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Cannot parse $value to double');
  }

  /// Unique identifier (UUID).
  final String id;

  /// Unique batch number (e.g., BATCH-20251006-001).
  final String batchNumber;

  /// UUID of the product being created.
  final String productInventoryId;

  /// UUID of the recipe template (for Phase 2 reminders).
  final String? recipeTemplateId;

  /// Expected quantity to produce.
  final double batchSize;

  /// Unit of measurement for the batch.
  final String unit;

  /// When production batch was started.
  final DateTime startDate;

  /// Estimated completion date (optional).
  final DateTime? estimatedCompletionDate;

  /// When production batch was completed or failed.
  final DateTime? completionDate;

  /// Legacy production date field.
  final DateTime productionDate;

  /// Batch status: 'in_progress', 'completed', 'failed'.
  final String status;

  /// Actual production time in hours.
  final double? productionTimeHours;

  /// Yield percentage (actualYield / batchSize * 100).
  final double? yieldPercentage;

  /// Actual quantity produced.
  final double? actualYield;

  /// Quality notes about the finished product.
  final String? qualityNotes;

  /// Storage location for the batch.
  final String? storageLocation;

  /// General notes about the production batch.
  final String? notes;

  /// Timestamp when batch was created.
  final DateTime createdAt;

  /// Timestamp when batch was last updated.
  final DateTime updatedAt;

  /// Whether the batch is currently in progress.
  bool get isInProgress => status == 'in_progress';

  /// Whether the batch is completed.
  bool get isCompleted => status == 'completed';

  /// Whether the batch failed.
  bool get isFailed => status == 'failed';
}

/// Input for creating a new production batch.
class CreateProductionBatchInput {
  /// Creates production batch input.
  const CreateProductionBatchInput({
    required this.productInventoryId,
    this.recipeTemplateId,
    required this.batchSize,
    required this.unit,
    this.estimatedCompletionDate,
    this.storageLocation,
    required this.ingredients,
    this.notes,
  });

  /// UUID of the product being created.
  final String productInventoryId;

  /// Optional recipe template ID for auto-generating reminders.
  final String? recipeTemplateId;

  /// Quantity of product expected to be created.
  final double batchSize;

  /// Unit of measurement for the product.
  final String unit;

  /// Optional estimated completion date.
  final DateTime? estimatedCompletionDate;

  /// Optional storage location for the batch.
  final String? storageLocation;

  /// List of ingredients consumed in this batch.
  final List<IngredientInput> ingredients;

  /// Optional notes about the production batch.
  final String? notes;

  /// Converts to JSON for GraphQL mutation.
  Map<String, dynamic> toJson() {
    return {
      'productInventoryId': productInventoryId,
      if (recipeTemplateId != null) 'recipeTemplateId': recipeTemplateId,
      'batchSize': batchSize,
      'unit': unit,
      if (estimatedCompletionDate != null)
        'estimatedCompletionDate': estimatedCompletionDate!.toIso8601String(),
      if (storageLocation != null) 'storageLocation': storageLocation,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Input for a single ingredient in a production batch.
class IngredientInput {
  /// Creates ingredient input.
  const IngredientInput({
    required this.inventoryId,
    required this.quantityUsed,
  });

  /// ID of the inventory item to consume.
  final String inventoryId;

  /// Quantity to consume from inventory.
  final double quantityUsed;

  /// Converts to JSON for GraphQL mutation.
  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'quantityUsed': quantityUsed,
    };
  }
}

/// Input for completing a production batch.
class CompleteProductionBatchInput {
  /// Creates complete batch input.
  const CompleteProductionBatchInput({
    required this.batchId,
    required this.actualYield,
    this.qualityNotes,
  });

  /// ID of the batch to complete.
  final String batchId;

  /// Actual quantity produced.
  final double actualYield;

  /// Optional quality notes about the finished product.
  final String? qualityNotes;

  /// Converts to JSON for GraphQL mutation.
  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'actualYield': actualYield,
      if (qualityNotes != null) 'qualityNotes': qualityNotes,
    };
  }
}

/// Input for marking a production batch as failed.
class FailProductionBatchInput {
  /// Creates fail batch input.
  const FailProductionBatchInput({
    required this.batchId,
    required this.reason,
  });

  /// ID of the batch that failed.
  final String batchId;

  /// Reason for the failure.
  final String reason;

  /// Converts to JSON for GraphQL mutation.
  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'reason': reason,
    };
  }
}

/// Result from creating/completing/failing a production batch.
class ProductionBatchResult {
  /// Creates production batch result.
  const ProductionBatchResult({
    required this.success,
    required this.message,
    this.batchId,
    this.batchNumber,
  });

  /// Creates result from GraphQL JSON response.
  factory ProductionBatchResult.fromJson(Map<String, dynamic> json) {
    return ProductionBatchResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      batchId: json['batchId'] as String?,
      batchNumber: json['batchNumber'] as String?,
    );
  }

  /// Whether the operation succeeded.
  final bool success;

  /// Result message (success or error details).
  final String message;

  /// ID of the created/updated batch (if successful).
  final String? batchId;

  /// Batch number (if successful).
  final String? batchNumber;
}
