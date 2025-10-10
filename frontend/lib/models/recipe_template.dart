class RecipeTemplate {
  final String id;
  final String productInventoryId;
  final String templateName;
  final String? description;
  final double? defaultBatchSize;
  final String? defaultUnit;
  final double? estimatedDurationHours;
  final Map<String, dynamic>? ingredientTemplate;
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeTemplate({
    required this.id,
    required this.productInventoryId,
    required this.templateName,
    this.description,
    this.defaultBatchSize,
    this.defaultUnit,
    this.estimatedDurationHours,
    this.ingredientTemplate,
    this.instructions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeTemplate.fromJson(Map<String, dynamic> json) {
    return RecipeTemplate(
      id: json['id'] as String,
      productInventoryId: json['productInventoryId'] as String,
      templateName: json['templateName'] as String,
      description: json['description'] as String?,
      defaultBatchSize: json['defaultBatchSize'] != null
          ? double.parse(json['defaultBatchSize'].toString())
          : null,
      defaultUnit: json['defaultUnit'] as String?,
      estimatedDurationHours: json['estimatedDurationHours'] != null
          ? double.parse(json['estimatedDurationHours'].toString())
          : null,
      ingredientTemplate: json['ingredientTemplate'] as Map<String, dynamic>?,
      instructions: json['instructions'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productInventoryId': productInventoryId,
      'templateName': templateName,
      'description': description,
      'defaultBatchSize': defaultBatchSize,
      'defaultUnit': defaultUnit,
      'estimatedDurationHours': estimatedDurationHours,
      'ingredientTemplate': ingredientTemplate,
      'instructions': instructions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get list of ingredients from JSONB template
  List<IngredientTemplateItem> get ingredients {
    if (ingredientTemplate == null) return [];
    final ingredientsList =
        ingredientTemplate!['ingredients'] as List<dynamic>?;
    if (ingredientsList == null) return [];

    return ingredientsList
        .map((item) =>
            IngredientTemplateItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// Represents a single ingredient in a recipe template
class IngredientTemplateItem {
  final String inventoryId;
  final double quantityPerBatch;
  final String unit;

  IngredientTemplateItem({
    required this.inventoryId,
    required this.quantityPerBatch,
    required this.unit,
  });

  factory IngredientTemplateItem.fromJson(Map<String, dynamic> json) {
    return IngredientTemplateItem(
      inventoryId: json['inventory_id'] as String,
      quantityPerBatch: double.parse(json['quantity_per_batch'].toString()),
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_id': inventoryId,
      'quantity_per_batch': quantityPerBatch,
      'unit': unit,
    };
  }
}

/// Input for creating a new recipe template
class CreateRecipeTemplateInput {
  final String productInventoryId;
  final String templateName;
  final String? description;
  final double? defaultBatchSize;
  final String? defaultUnit;
  final double? estimatedDurationHours;
  final List<IngredientTemplateItem>? ingredients;
  final String? instructions;

  CreateRecipeTemplateInput({
    required this.productInventoryId,
    required this.templateName,
    this.description,
    this.defaultBatchSize,
    this.defaultUnit,
    this.estimatedDurationHours,
    this.ingredients,
    this.instructions,
  });

  Map<String, dynamic> toJson() {
    final ingredientTemplate = ingredients != null && ingredients!.isNotEmpty
        ? {'ingredients': ingredients!.map((i) => i.toJson()).toList()}
        : null;

    return {
      'productInventoryId': productInventoryId,
      'templateName': templateName,
      if (description != null) 'description': description,
      if (defaultBatchSize != null) 'defaultBatchSize': defaultBatchSize,
      if (defaultUnit != null) 'defaultUnit': defaultUnit,
      if (estimatedDurationHours != null)
        'estimatedDurationHours': estimatedDurationHours,
      if (ingredientTemplate != null) 'ingredientTemplate': ingredientTemplate,
      if (instructions != null) 'instructions': instructions,
    };
  }
}

/// Input for updating an existing recipe template
class UpdateRecipeTemplateInput {
  final String id;
  final String? productInventoryId;
  final String? templateName;
  final String? description;
  final double? defaultBatchSize;
  final String? defaultUnit;
  final double? estimatedDurationHours;
  final List<IngredientTemplateItem>? ingredients;
  final String? instructions;

  UpdateRecipeTemplateInput({
    required this.id,
    this.productInventoryId,
    this.templateName,
    this.description,
    this.defaultBatchSize,
    this.defaultUnit,
    this.estimatedDurationHours,
    this.ingredients,
    this.instructions,
  });

  Map<String, dynamic> toJson() {
    final ingredientTemplate = ingredients != null
        ? {'ingredients': ingredients!.map((i) => i.toJson()).toList()}
        : null;

    return {
      'id': id,
      if (productInventoryId != null) 'productInventoryId': productInventoryId,
      if (templateName != null) 'templateName': templateName,
      if (description != null) 'description': description,
      if (defaultBatchSize != null) 'defaultBatchSize': defaultBatchSize,
      if (defaultUnit != null) 'defaultUnit': defaultUnit,
      if (estimatedDurationHours != null)
        'estimatedDurationHours': estimatedDurationHours,
      if (ingredientTemplate != null) 'ingredientTemplate': ingredientTemplate,
      if (instructions != null) 'instructions': instructions,
    };
  }
}

/// Result from creating or updating a recipe template
class RecipeTemplateResult {
  final bool success;
  final String message;
  final RecipeTemplate? recipe;

  RecipeTemplateResult({
    required this.success,
    required this.message,
    this.recipe,
  });

  factory RecipeTemplateResult.fromJson(Map<String, dynamic> json) {
    return RecipeTemplateResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      recipe: json['recipe'] != null
          ? RecipeTemplate.fromJson(json['recipe'] as Map<String, dynamic>)
          : null,
    );
  }
}
