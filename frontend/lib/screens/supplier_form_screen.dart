import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supplier.dart';
import '../services/graphql_service.dart';
import '../services/suppliers_provider.dart';

/// Screen for creating or editing a supplier.
class SupplierFormScreen extends ConsumerStatefulWidget {
  const SupplierFormScreen({
    super.key,
    this.supplier,
  });

  /// If provided, screen is in edit mode. Otherwise, create mode.
  final Supplier? supplier;

  @override
  ConsumerState<SupplierFormScreen> createState() =>
      _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditMode => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.supplier!);
    }
  }

  void _populateFields(Supplier supplier) {
    _nameController.text = supplier.name;
    if (supplier.contactEmail != null) {
      _contactEmailController.text = supplier.contactEmail!;
    }
    if (supplier.contactPhone != null) {
      _contactPhoneController.text = supplier.contactPhone!;
    }
    if (supplier.streetAddress != null) {
      _streetAddressController.text = supplier.streetAddress!;
    }
    if (supplier.city != null) {
      _cityController.text = supplier.city!;
    }
    if (supplier.state != null) {
      _stateController.text = supplier.state!;
    }
    if (supplier.zipCode != null) {
      _zipCodeController.text = supplier.zipCode!;
    }
    if (supplier.country != null) {
      _countryController.text = supplier.country!;
    }
    if (supplier.latitude != null) {
      _latitudeController.text = supplier.latitude!.toString();
    }
    if (supplier.longitude != null) {
      _longitudeController.text = supplier.longitude!.toString();
    }
    if (supplier.notes != null) {
      _notesController.text = supplier.notes!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Supplier' : 'New Supplier'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., Frederick Flour Mill',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact Information Section
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Email and Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        // Basic email validation
                        if (!value.contains('@')) {
                          return 'Invalid email';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _contactPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address Section
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Street Address
            TextFormField(
              controller: _streetAddressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // City, State, ZIP in a row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      hintText: 'MD',
                      border: OutlineInputBorder(),
                      counterText: '', // Hide character counter
                    ),
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 2) {
                          return '2 letters';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP',
                      hintText: '21701',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Country
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                hintText: 'USA',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Location Coordinates Section
            Text(
              'Location Coordinates (for map display)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Latitude and Longitude
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g., 39.4143',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lat = double.tryParse(value);
                        if (lat == null) {
                          return 'Invalid number';
                        }
                        if (lat < -90 || lat > 90) {
                          return 'Must be -90 to 90';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g., -77.4105',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lon = double.tryParse(value);
                        if (lon == null) {
                          return 'Invalid number';
                        }
                        if (lon < -180 || lon > 180) {
                          return 'Must be -180 to 180';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional supplier notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? 'Update Supplier' : 'Create Supplier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);

      final SupplierResult result;

      if (_isEditMode) {
        // Update existing supplier
        result = await service.updateSupplier(
          UpdateSupplierInput(
            id: widget.supplier!.id,
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            contactEmail: _contactEmailController.text.trim().isEmpty
                ? null
                : _contactEmailController.text.trim(),
            contactPhone: _contactPhoneController.text.trim().isEmpty
                ? null
                : _contactPhoneController.text.trim(),
            streetAddress: _streetAddressController.text.trim().isEmpty
                ? null
                : _streetAddressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            state: _stateController.text.trim().isEmpty
                ? null
                : _stateController.text.trim().toUpperCase(),
            zipCode: _zipCodeController.text.trim().isEmpty
                ? null
                : _zipCodeController.text.trim(),
            country: _countryController.text.trim().isEmpty
                ? null
                : _countryController.text.trim(),
            latitude: _latitudeController.text.isEmpty
                ? null
                : double.parse(_latitudeController.text),
            longitude: _longitudeController.text.isEmpty
                ? null
                : double.parse(_longitudeController.text),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
      } else {
        // Create new supplier
        result = await service.createSupplier(
          CreateSupplierInput(
            name: _nameController.text.trim(),
            contactEmail: _contactEmailController.text.trim().isEmpty
                ? null
                : _contactEmailController.text.trim(),
            contactPhone: _contactPhoneController.text.trim().isEmpty
                ? null
                : _contactPhoneController.text.trim(),
            streetAddress: _streetAddressController.text.trim().isEmpty
                ? null
                : _streetAddressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            state: _stateController.text.trim().isEmpty
                ? null
                : _stateController.text.trim().toUpperCase(),
            zipCode: _zipCodeController.text.trim().isEmpty
                ? null
                : _zipCodeController.text.trim(),
            country: _countryController.text.trim().isEmpty
                ? null
                : _countryController.text.trim(),
            latitude: _latitudeController.text.isEmpty
                ? null
                : double.parse(_latitudeController.text),
            longitude: _longitudeController.text.isEmpty
                ? null
                : double.parse(_longitudeController.text),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
      }

      if (result.success && mounted) {
        // Invalidate suppliers provider to refresh list
        ref.invalidate(suppliersProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
