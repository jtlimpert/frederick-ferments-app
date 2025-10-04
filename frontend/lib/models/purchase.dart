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
