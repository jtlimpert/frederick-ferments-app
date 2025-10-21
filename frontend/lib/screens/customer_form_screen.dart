import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/graphql_service.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? customer; // null for create, non-null for edit

  const CustomerFormScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _streetAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _notesController;

  String _customerType = 'retail';
  bool _taxExempt = false;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;

    _nameController = TextEditingController(text: customer?.name ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _streetAddressController = TextEditingController(text: customer?.streetAddress ?? '');
    _cityController = TextEditingController(text: customer?.city ?? '');
    _stateController = TextEditingController(text: customer?.state ?? '');
    _zipCodeController = TextEditingController(text: customer?.zipCode ?? '');
    _countryController = TextEditingController(text: customer?.country ?? 'USA');
    _latitudeController = TextEditingController(text: customer?.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: customer?.longitude?.toString() ?? '');
    _notesController = TextEditingController(text: customer?.notes ?? '');

    if (customer != null) {
      _customerType = customer.customerType ?? 'retail';
      _taxExempt = customer.taxExempt;
      _isActive = customer.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final graphqlService = ref.read(graphqlServiceProvider.notifier);

      if (widget.customer == null) {
        // Create new customer
        final input = CreateCustomerInput(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          streetAddress: _streetAddressController.text.trim().isEmpty ? null : _streetAddressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          latitude: _latitudeController.text.trim().isEmpty ? null : double.tryParse(_latitudeController.text.trim()),
          longitude: _longitudeController.text.trim().isEmpty ? null : double.tryParse(_longitudeController.text.trim()),
          customerType: _customerType,
          taxExempt: _taxExempt,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        final result = await graphqlService.createCustomer(input);

        if (mounted) {
          // Invalidate the customers provider to refresh the list
          ref.invalidate(customersProvider);

          final message = result['message'] as String? ?? 'Customer created successfully';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Update existing customer
        final input = UpdateCustomerInput(
          id: widget.customer!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          streetAddress: _streetAddressController.text.trim().isEmpty ? null : _streetAddressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          latitude: _latitudeController.text.trim().isEmpty ? null : double.tryParse(_latitudeController.text.trim()),
          longitude: _longitudeController.text.trim().isEmpty ? null : double.tryParse(_longitudeController.text.trim()),
          customerType: _customerType,
          taxExempt: _taxExempt,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          isActive: _isActive,
        );

        final result = await graphqlService.updateCustomer(input);

        if (mounted) {
          // Invalidate the customers provider to refresh the list
          ref.invalidate(customersProvider);

          final message = result['message'] as String? ?? 'Customer updated successfully';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.of(context).pop();
        }
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'New Customer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Basic email validation
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Address Section
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _streetAddressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
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
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP Code',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location Coordinates Section
            Text(
              'Location Coordinates (for map display)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

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
                      if (value != null && value.trim().isNotEmpty) {
                        final lat = double.tryParse(value.trim());
                        if (lat == null || lat < -90 || lat > 90) {
                          return 'Must be between -90 and 90';
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
                      if (value != null && value.trim().isNotEmpty) {
                        final lng = double.tryParse(value.trim());
                        if (lng == null || lng < -180 || lng > 180) {
                          return 'Must be between -180 and 180';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Details Section
            Text(
              'Customer Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _customerType,
              decoration: const InputDecoration(
                labelText: 'Customer Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'retail', child: Text('Retail')),
                DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                DropdownMenuItem(value: 'distributor', child: Text('Distributor')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _customerType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Tax Exempt'),
              value: _taxExempt,
              onChanged: (value) {
                setState(() {
                  _taxExempt = value;
                });
              },
            ),

            if (isEditing)
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Customer' : 'Create Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
