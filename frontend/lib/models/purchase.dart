/// Represents the input for creating a new purchase in the system.
///
/// Used when recording inventory purchases from suppliers.
class CreatePurchaseInput {
  /// Creates a purchase input.
  const CreatePurchaseInput({
    required this.supplierId,
    required this.items,
    this.purchaseDate,
    this.notes,
  });

  /// Converts to GraphQL mutation variables format.
  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'items': items.map((item) => item.toJson()).toList(),
      if (purchaseDate != null)
        'purchaseDate': purchaseDate!.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  /// ID of the supplier for this purchase.
  final String supplierId;

  /// List of items being purchased.
  final List<PurchaseItemInput> items;

  /// Date/time of purchase (defaults to now on backend if null).
  final DateTime? purchaseDate;

  /// Optional notes about the purchase.
  final String? notes;
}

/// Represents a single item in a purchase order.
class PurchaseItemInput {
  /// Creates a purchase item input.
  const PurchaseItemInput({
    required this.inventoryId,
    required this.quantity,
    required this.unitCost,
    this.expiryDate,
    this.batchNumber,
  });

  /// Converts to GraphQL mutation variables format.
  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'quantity': quantity.toString(),
      'unitCost': unitCost.toString(),
      if (expiryDate != null)
        'expiryDate': expiryDate!.toIso8601String().split('T')[0],
      if (batchNumber != null) 'batchNumber': batchNumber,
    };
  }

  /// ID of the inventory item being purchased.
  final String inventoryId;

  /// Quantity being purchased.
  final double quantity;

  /// Unit cost for this purchase.
  final double unitCost;

  /// Optional expiry date for the batch.
  final DateTime? expiryDate;

  /// Optional batch/lot number.
  final String? batchNumber;
}

/// Result from a purchase mutation.
class PurchaseResult {
  /// Creates a purchase result.
  const PurchaseResult({
    required this.success,
    required this.message,
    required this.updatedItems,
  });

  /// Creates a purchase result from GraphQL JSON response.
  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      updatedItems: (json['updatedItems'] as List<dynamic>?)
              ?.map((item) => UpdatedInventoryItem.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList() ??
          [],
    );
  }

  /// Whether the purchase was successful.
  final bool success;

  /// Result message from the backend.
  final String message;

  /// List of inventory items updated by this purchase.
  final List<UpdatedInventoryItem> updatedItems;
}

/// Simplified inventory item returned from purchase mutation.
class UpdatedInventoryItem {
  /// Creates an updated inventory item.
  const UpdatedInventoryItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.availableStock,
    this.costPerUnit,
  });

  /// Creates an updated item from GraphQL JSON response.
  factory UpdatedInventoryItem.fromJson(Map<String, dynamic> json) {
    return UpdatedInventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      currentStock: _parseDouble(json['currentStock']),
      availableStock: _parseDouble(json['availableStock']),
      costPerUnit: json['costPerUnit'] != null
          ? _parseDouble(json['costPerUnit'])
          : null,
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

  /// Unique identifier.
  final String id;

  /// Item name.
  final String name;

  /// Updated current stock.
  final double currentStock;

  /// Updated available stock.
  final double availableStock;

  /// Updated cost per unit.
  final double? costPerUnit;
}

/// Input for creating a new inventory item.
class CreateInventoryItemInput {
  /// Creates an inventory item input.
  const CreateInventoryItemInput({
    required this.name,
    required this.category,
    required this.unit,
    this.currentStock,
    this.reservedStock,
    this.reorderPoint,
    this.costPerUnit,
    this.defaultSupplierId,
    this.shelfLifeDays,
    this.storageRequirements,
  });

  /// Converts to GraphQL mutation variables format.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'unit': unit,
      if (currentStock != null) 'currentStock': currentStock.toString(),
      if (reservedStock != null) 'reservedStock': reservedStock.toString(),
      if (reorderPoint != null) 'reorderPoint': reorderPoint.toString(),
      if (costPerUnit != null) 'costPerUnit': costPerUnit.toString(),
      if (defaultSupplierId != null) 'defaultSupplierId': defaultSupplierId,
      if (shelfLifeDays != null) 'shelfLifeDays': shelfLifeDays,
      if (storageRequirements != null) 'storageRequirements': storageRequirements,
    };
  }

  final String name;
  final String category;
  final String unit;
  final double? currentStock;
  final double? reservedStock;
  final double? reorderPoint;
  final double? costPerUnit;
  final String? defaultSupplierId;
  final int? shelfLifeDays;
  final String? storageRequirements;
}

/// Input for updating an existing inventory item.
class UpdateInventoryItemInput {
  /// Creates an update inventory item input.
  const UpdateInventoryItemInput({
    required this.id,
    this.name,
    this.category,
    this.unit,
    this.currentStock,
    this.reservedStock,
    this.reorderPoint,
    this.costPerUnit,
    this.defaultSupplierId,
    this.shelfLifeDays,
    this.storageRequirements,
    this.isActive,
  });

  /// Converts to GraphQL mutation variables format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (currentStock != null) 'currentStock': currentStock.toString(),
      if (reservedStock != null) 'reservedStock': reservedStock.toString(),
      if (reorderPoint != null) 'reorderPoint': reorderPoint.toString(),
      if (costPerUnit != null) 'costPerUnit': costPerUnit.toString(),
      if (defaultSupplierId != null) 'defaultSupplierId': defaultSupplierId,
      if (shelfLifeDays != null) 'shelfLifeDays': shelfLifeDays,
      if (storageRequirements != null) 'storageRequirements': storageRequirements,
      if (isActive != null) 'isActive': isActive,
    };
  }

  final String id;
  final String? name;
  final String? category;
  final String? unit;
  final double? currentStock;
  final double? reservedStock;
  final double? reorderPoint;
  final double? costPerUnit;
  final String? defaultSupplierId;
  final int? shelfLifeDays;
  final String? storageRequirements;
  final bool? isActive;
}

/// Result from create/update inventory item mutations.
class InventoryItemResult {
  /// Creates an inventory item result.
  const InventoryItemResult({
    required this.success,
    required this.message,
    this.item,
  });

  /// Creates a result from GraphQL JSON response.
  factory InventoryItemResult.fromJson(Map<String, dynamic> json) {
    return InventoryItemResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      item: json['item'] != null
          ? ResultInventoryItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool success;
  final String message;
  final ResultInventoryItem? item;
}

/// Full inventory item returned from create/update mutations.
class ResultInventoryItem {
  /// Creates a result inventory item.
  const ResultInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.reservedStock,
    required this.availableStock,
    required this.reorderPoint,
    this.costPerUnit,
    this.defaultSupplierId,
    this.shelfLifeDays,
    this.storageRequirements,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates from GraphQL JSON response.
  factory ResultInventoryItem.fromJson(Map<String, dynamic> json) {
    return ResultInventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      currentStock: _parseDouble(json['currentStock']),
      reservedStock: _parseDouble(json['reservedStock']),
      availableStock: _parseDouble(json['availableStock']),
      reorderPoint: _parseDouble(json['reorderPoint']),
      costPerUnit: json['costPerUnit'] != null ? _parseDouble(json['costPerUnit']) : null,
      defaultSupplierId: json['defaultSupplierId'] as String?,
      shelfLifeDays: json['shelfLifeDays'] as int?,
      storageRequirements: json['storageRequirements'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Cannot parse $value to double');
  }

  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double reservedStock;
  final double availableStock;
  final double reorderPoint;
  final double? costPerUnit;
  final String? defaultSupplierId;
  final int? shelfLifeDays;
  final String? storageRequirements;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
