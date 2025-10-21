/// Represents a customer who purchases products.
class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? customerType;
  final bool taxExempt;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.customerType,
    required this.taxExempt,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Customer from JSON data returned by the GraphQL API.
  factory Customer.fromJson(Map<String, dynamic> json) {
    // Parse latitude/longitude - can be string or number from GraphQL
    double? parseLat(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
      latitude: parseLat(json['latitude']),
      longitude: parseLat(json['longitude']),
      customerType: json['customerType'] as String?,
      taxExempt: json['taxExempt'] as bool? ?? false,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts the Customer to JSON for GraphQL mutations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'customerType': customerType,
      'taxExempt': taxExempt,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns true if this customer has geographic coordinates.
  bool get hasCoordinates =>
      latitude != null && longitude != null;

  /// Returns the full address as a formatted string.
  String get fullAddress {
    final parts = <String>[];
    if (streetAddress != null && streetAddress!.isNotEmpty) {
      parts.add(streetAddress!);
    }
    final cityStateZip = <String>[];
    if (city != null && city!.isNotEmpty) cityStateZip.add(city!);
    if (state != null && state!.isNotEmpty) cityStateZip.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) cityStateZip.add(zipCode!);
    if (cityStateZip.isNotEmpty) {
      parts.add(cityStateZip.join(' '));
    }
    if (country != null && country!.isNotEmpty && country != 'USA') {
      parts.add(country!);
    }
    return parts.join(', ');
  }

  /// Returns a display-friendly customer type label.
  String get customerTypeLabel {
    if (customerType == null) return 'General';
    switch (customerType!.toLowerCase()) {
      case 'wholesale':
        return 'Wholesale';
      case 'retail':
        return 'Retail';
      case 'restaurant':
        return 'Restaurant';
      default:
        return customerType!;
    }
  }
}

/// Input for creating a new customer.
class CreateCustomerInput {
  final String name;
  final String? email;
  final String? phone;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? customerType;
  final bool? taxExempt;
  final String? notes;

  CreateCustomerInput({
    required this.name,
    this.email,
    this.phone,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.customerType,
    this.taxExempt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (customerType != null) 'customerType': customerType,
      if (taxExempt != null) 'taxExempt': taxExempt,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Input for updating an existing customer.
class UpdateCustomerInput {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? customerType;
  final bool? taxExempt;
  final String? notes;
  final bool? isActive;

  UpdateCustomerInput({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.customerType,
    this.taxExempt,
    this.notes,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (customerType != null) 'customerType': customerType,
      if (taxExempt != null) 'taxExempt': taxExempt,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'isActive': isActive,
    };
  }
}
