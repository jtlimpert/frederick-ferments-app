/// Represents a supplier in the Frederick Ferments system.
///
/// Stores contact information, location coordinates, and relationship details
/// for inventory suppliers.
class Supplier {
  /// Creates a supplier.
  const Supplier({
    required this.id,
    required this.name,
    this.contactEmail,
    this.contactPhone,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a supplier from GraphQL JSON response.
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
      latitude: json['latitude'] != null
          ? _parseDouble(json['latitude'])
          : null,
      longitude: json['longitude'] != null
          ? _parseDouble(json['longitude'])
          : null,
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

  /// Supplier business name.
  final String name;

  /// Primary contact email address.
  final String? contactEmail;

  /// Primary contact phone number.
  final String? contactPhone;

  /// Street address (number and street name).
  final String? streetAddress;

  /// City name.
  final String? city;

  /// State code (2 letters, e.g., MD).
  final String? state;

  /// ZIP/Postal code.
  final String? zipCode;

  /// Country name (defaults to USA).
  final String? country;

  /// Latitude coordinate for map display.
  final double? latitude;

  /// Longitude coordinate for map display.
  final double? longitude;

  /// Additional notes about the supplier relationship.
  final String? notes;

  /// Timestamp when supplier was created.
  final DateTime createdAt;

  /// Timestamp when supplier was last updated.
  final DateTime updatedAt;

  /// Whether this supplier has valid coordinates for map display.
  bool get hasCoordinates => latitude != null && longitude != null;
}

/// Input for creating a new supplier.
class CreateSupplierInput {
  /// Creates a supplier input.
  const CreateSupplierInput({
    required this.name,
    this.contactEmail,
    this.contactPhone,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.notes,
  });

  /// Converts to GraphQL mutation variables format.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (notes != null) 'notes': notes,
    };
  }

  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? notes;
}

/// Input for updating an existing supplier.
class UpdateSupplierInput {
  /// Creates an update supplier input.
  const UpdateSupplierInput({
    required this.id,
    this.name,
    this.contactEmail,
    this.contactPhone,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.notes,
  });

  /// Converts to GraphQL mutation variables format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (notes != null) 'notes': notes,
    };
  }

  final String id;
  final String? name;
  final String? contactEmail;
  final String? contactPhone;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? notes;
}

/// Result from create/update supplier mutations.
class SupplierResult {
  /// Creates a supplier result.
  const SupplierResult({
    required this.success,
    required this.message,
    this.supplier,
  });

  /// Creates a result from GraphQL JSON response.
  factory SupplierResult.fromJson(Map<String, dynamic> json) {
    return SupplierResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      supplier: json['supplier'] != null
          ? Supplier.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool success;
  final String message;
  final Supplier? supplier;
}
