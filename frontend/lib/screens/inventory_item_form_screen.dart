import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../models/purchase.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';
import '../services/suppliers_provider.dart';

/// Screen for creating or editing an inventory item.
class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({
    super.key,
    this.item,
  });

  /// If provided, screen is in edit mode. Otherwise, create mode.
  final InventoryItem? item;

  @override
  ConsumerState<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState
    extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _reservedStockController = TextEditingController();
  final _reorderPointController = TextEditingController();
  final _costPerUnitController = TextEditingController();
  final _shelfLifeDaysController = TextEditingController();
  final _storageRequirementsController = TextEditingController();

  String? _selectedSupplierId;
  bool _isLoading = false;
  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.item!);
    }
  }

  void _populateFields(InventoryItem item) {
    _nameController.text = item.name;
    _categoryController.text = item.category;
    _unitController.text = item.unit;
    _currentStockController.text = item.currentStock.toString();
    _reservedStockController.text = item.reservedStock.toString();
    _reorderPointController.text = item.reorderPoint.toString();
    if (item.costPerUnit != null) {
      _costPerUnitController.text = item.costPerUnit!.toString();
    }
    _selectedSupplierId = item.defaultSupplierId;
    if (item.shelfLifeDays != null) {
      _shelfLifeDaysController.text = item.shelfLifeDays!.toString();
    }
    if (item.storageRequirements != null) {
      _storageRequirementsController.text = item.storageRequirements!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _currentStockController.dispose();
    _reservedStockController.dispose();
    _reorderPointController.dispose();
    _costPerUnitController.dispose();
    _shelfLifeDaysController.dispose();
    _storageRequirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Inventory Item' : 'New Inventory Item'),
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
                hintText: 'e.g., Organic Wheat Flour',
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

            // Category and Unit (row)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g., Grains',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      hintText: 'e.g., kg',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock levels section
            Text(
              'Stock Levels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currentStockController,
                    decoration: const InputDecoration(
                      labelText: 'Current Stock',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _reservedStockController,
                    decoration: const InputDecoration(
                      labelText: 'Reserved Stock',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reorder point and cost
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _reorderPointController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Point',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costPerUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Cost Per Unit',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Supplier dropdown
            suppliersAsync.when(
              data: (suppliers) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedSupplierId,
                  decoration: const InputDecoration(
                    labelText: 'Default Supplier',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    ...suppliers.map((supplier) {
                      return DropdownMenuItem(
                        value: supplier.id,
                        child: Text(supplier.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplierId = value;
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text('Error loading suppliers: $error'),
            ),
            const SizedBox(height: 16),

            // Shelf life
            TextFormField(
              controller: _shelfLifeDaysController,
              decoration: const InputDecoration(
                labelText: 'Shelf Life (days)',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Storage requirements
            TextFormField(
              controller: _storageRequirementsController,
              decoration: const InputDecoration(
                labelText: 'Storage Requirements',
                hintText: 'e.g., Keep in cool, dry place',
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
                  : Text(_isEditMode ? 'Update Item' : 'Create Item'),
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

      final InventoryItemResult result;

      if (_isEditMode) {
        // Update existing item
        result = await service.updateInventoryItem(
          UpdateInventoryItemInput(
            id: widget.item!.id,
            name: _nameController.text.trim(),
            category: _categoryController.text.trim(),
            unit: _unitController.text.trim(),
            currentStock: _currentStockController.text.isEmpty
                ? null
                : double.parse(_currentStockController.text),
            reservedStock: _reservedStockController.text.isEmpty
                ? null
                : double.parse(_reservedStockController.text),
            reorderPoint: _reorderPointController.text.isEmpty
                ? null
                : double.parse(_reorderPointController.text),
            costPerUnit: _costPerUnitController.text.isEmpty
                ? null
                : double.parse(_costPerUnitController.text),
            defaultSupplierId: _selectedSupplierId,
            shelfLifeDays: _shelfLifeDaysController.text.isEmpty
                ? null
                : int.parse(_shelfLifeDaysController.text),
            storageRequirements: _storageRequirementsController.text.isEmpty
                ? null
                : _storageRequirementsController.text,
          ),
        );
      } else {
        // Create new item
        result = await service.createInventoryItem(
          CreateInventoryItemInput(
            name: _nameController.text.trim(),
            category: _categoryController.text.trim(),
            unit: _unitController.text.trim(),
            currentStock: _currentStockController.text.isEmpty
                ? null
                : double.parse(_currentStockController.text),
            reservedStock: _reservedStockController.text.isEmpty
                ? null
                : double.parse(_reservedStockController.text),
            reorderPoint: _reorderPointController.text.isEmpty
                ? null
                : double.parse(_reorderPointController.text),
            costPerUnit: _costPerUnitController.text.isEmpty
                ? null
                : double.parse(_costPerUnitController.text),
            defaultSupplierId: _selectedSupplierId,
            shelfLifeDays: _shelfLifeDaysController.text.isEmpty
                ? null
                : int.parse(_shelfLifeDaysController.text),
            storageRequirements: _storageRequirementsController.text.isEmpty
                ? null
                : _storageRequirementsController.text,
          ),
        );
      }

      if (result.success && mounted) {
        // Invalidate inventory provider to refresh list
        ref.invalidate(inventoryItemsProvider);

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
