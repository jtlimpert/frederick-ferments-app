/// Represents an inventory item in the Frederick Ferments system.
///
/// Tracks stock levels, costs, supplier information, and storage
/// requirements for fermentation ingredients and products.
class InventoryItem {
  /// Creates an inventory item.
  const InventoryItem({
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

  /// Creates an inventory item from GraphQL JSON response.
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      reservedStock: (json['reservedStock'] as num).toDouble(),
      availableStock: (json['availableStock'] as num).toDouble(),
      reorderPoint: (json['reorderPoint'] as num).toDouble(),
      costPerUnit: json['costPerUnit'] != null
          ? (json['costPerUnit'] as num).toDouble()
          : null,
      defaultSupplierId: json['defaultSupplierId'] as String?,
      shelfLifeDays: json['shelfLifeDays'] as int?,
      storageRequirements: json['storageRequirements'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Unique identifier (UUID).
  final String id;

  /// Display name of the inventory item.
  final String name;

  /// Category for grouping items (e.g., "Grains", "Hops", "Cultures").
  final String category;

  /// Unit of measurement (e.g., "kg", "L", "units").
  final String unit;

  /// Total physical stock quantity.
  final double currentStock;

  /// Stock allocated for future use but not yet consumed.
  final double reservedStock;

  /// Stock available for use (currentStock - reservedStock).
  ///
  /// This is a computed field maintained by the database.
  final double availableStock;

  /// Minimum stock level that triggers reorder notification.
  final double reorderPoint;

  /// Cost per unit in the base currency.
  ///
  /// Updated to most recent purchase price when new stock is added.
  final double? costPerUnit;

  /// UUID of the preferred supplier for this item.
  final String? defaultSupplierId;

  /// Number of days until item expires from receipt date.
  final int? shelfLifeDays;

  /// Storage instructions (e.g., "Keep refrigerated at 2-4°C").
  final String? storageRequirements;

  /// Whether item is active in the system.
  ///
  /// Soft delete flag - false indicates item is archived.
  final bool isActive;

  /// Timestamp when item was created.
  final DateTime createdAt;

  /// Timestamp when item was last updated.
  final DateTime updatedAt;

  /// Checks if stock is below reorder point.
  bool get needsReorder => availableStock <= reorderPoint;
}
