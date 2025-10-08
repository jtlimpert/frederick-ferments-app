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
}
