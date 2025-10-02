/// Represents a supplier in the Frederick Ferments system.
///
/// Stores contact information and relationship details
/// for inventory suppliers.
class Supplier {
  /// Creates a supplier.
  const Supplier({
    required this.id,
    required this.name,
    this.contactEmail,
    this.contactPhone,
    this.address,
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
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Unique identifier (UUID).
  final String id;

  /// Supplier business name.
  final String name;

  /// Primary contact email address.
  final String? contactEmail;

  /// Primary contact phone number.
  final String? contactPhone;

  /// Physical or mailing address.
  final String? address;

  /// Additional notes about the supplier relationship.
  final String? notes;

  /// Timestamp when supplier was created.
  final DateTime createdAt;

  /// Timestamp when supplier was last updated.
  final DateTime updatedAt;
}
