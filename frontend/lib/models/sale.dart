/// Represents a sale transaction.
class Sale {
  final String id;
  final String saleNumber;
  final String? customerId;
  final DateTime saleDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.saleNumber,
    this.customerId,
    required this.saleDate,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Sale from JSON data returned by the GraphQL API.
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      saleNumber: json['saleNumber'] as String,
      customerId: json['customerId'] as String?,
      saleDate: DateTime.parse(json['saleDate'] as String),
      subtotal: _parseDecimal(json['subtotal']),
      taxAmount: _parseDecimal(json['taxAmount']),
      discountAmount: _parseDecimal(json['discountAmount']),
      totalAmount: _parseDecimal(json['totalAmount']),
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String? ?? 'completed',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Helper to parse decimal values from API (can be String or num).
  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Returns a color for the payment status.
  String get statusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'refunded':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Returns a display-friendly payment status label.
  String get statusLabel {
    return paymentStatus[0].toUpperCase() + paymentStatus.substring(1);
  }
}

/// Represents a line item in a sale.
class SaleItem {
  final String id;
  final String saleId;
  final String inventoryId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String? notes;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.inventoryId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.notes,
  });

  /// Creates a SaleItem from JSON data returned by the GraphQL API.
  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      inventoryId: json['inventoryId'] as String,
      quantity: _parseDecimal(json['quantity']),
      unitPrice: _parseDecimal(json['unitPrice']),
      lineTotal: _parseDecimal(json['lineTotal']),
      notes: json['notes'] as String?,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Represents a sale with its items and customer information.
class SaleWithItems {
  final Sale sale;
  final List<SaleItem> items;
  final dynamic customer; // Can be Customer or null

  SaleWithItems({
    required this.sale,
    required this.items,
    this.customer,
  });

  /// Creates a SaleWithItems from JSON data returned by the GraphQL API.
  factory SaleWithItems.fromJson(Map<String, dynamic> json) {
    return SaleWithItems(
      sale: Sale.fromJson(json['sale'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      customer: json['customer'],
    );
  }
}

/// Input for a single item in a sale.
class SaleItemInput {
  final String inventoryId;
  final double quantity;
  final double unitPrice;
  final String? notes;

  SaleItemInput({
    required this.inventoryId,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'quantity': quantity.toString(),
      'unitPrice': unitPrice.toStringAsFixed(2),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Input for creating a new sale.
class CreateSaleInput {
  final String? customerId;
  final DateTime? saleDate;
  final List<SaleItemInput> items;
  final double? taxAmount;
  final double? discountAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? notes;

  CreateSaleInput({
    this.customerId,
    this.saleDate,
    required this.items,
    this.taxAmount,
    this.discountAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
  });

  /// Calculates the subtotal from all items.
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  /// Calculates the total amount.
  double get totalAmount {
    return subtotal + (taxAmount ?? 0.0) - (discountAmount ?? 0.0);
  }

  Map<String, dynamic> toJson() {
    return {
      if (customerId != null) 'customerId': customerId,
      if (saleDate != null) 'saleDate': saleDate!.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      if (taxAmount != null) 'taxAmount': taxAmount!.toStringAsFixed(2),
      if (discountAmount != null) 'discountAmount': discountAmount!.toStringAsFixed(2),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (notes != null) 'notes': notes,
    };
  }
}
