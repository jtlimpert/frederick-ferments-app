import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';
import '../services/suppliers_provider.dart';

/// Screen for creating a new purchase order.
///
/// Allows selecting a supplier, adding items with quantities and costs,
/// and recording the purchase to update inventory levels.
class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() =>
      _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  Supplier? _selectedSupplier;
  DateTime _purchaseDate = DateTime.now();
  final List<_PurchaseItemEntry> _items = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_PurchaseItemEntry());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final input = CreatePurchaseInput(
        supplierId: _selectedSupplier!.id,
        items: _items
            .map(
              (item) => PurchaseItemInput(
                inventoryId: item.inventoryItem!.id,
                quantity: item.quantity,
                unitCost: item.unitCost,
                expiryDate: item.expiryDate,
                batchNumber:
                    item.batchNumber.isEmpty ? null : item.batchNumber,
              ),
            )
            .toList(),
        purchaseDate: _purchaseDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.createPurchase(input);

      if (!mounted) return;

      if (result.success) {
        // Invalidate inventory items to refresh the list
        ref.invalidate(inventoryItemsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create purchase: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    final suppliersAsync = ref.watch(suppliersProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: suppliersAsync.when(
        data: (suppliers) => inventoryAsync.when(
          data: (inventory) => _buildForm(context, suppliers, inventory),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error loading inventory: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading suppliers: $error')),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Supplier> suppliers,
    List<InventoryItem> inventory,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Supplier Selection
          DropdownButtonFormField<Supplier>(
            initialValue: _selectedSupplier,
            decoration: const InputDecoration(
              labelText: 'Supplier',
              border: OutlineInputBorder(),
            ),
            items: suppliers.map((supplier) {
              return DropdownMenuItem(
                value: supplier,
                child: Text(supplier.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSupplier = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a supplier' : null,
          ),

          const SizedBox(height: 16),

          // Purchase Date
          ListTile(
            title: const Text('Purchase Date'),
            subtitle: Text(
              '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _purchaseDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _purchaseDate = date;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Items List
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _PurchaseItemCard(
              key: ValueKey(item),
              item: item,
              inventory: inventory,
              onRemove: () => _removeItem(index),
            );
          }),

          const SizedBox(height: 24),

          // Submit Button
          FilledButton(
            onPressed: _isSubmitting ? null : _submitPurchase,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Purchase'),
          ),
        ],
      ),
    );
  }
}

/// Internal class to hold purchase item form data.
class _PurchaseItemEntry {
  InventoryItem? inventoryItem;
  double quantity = 0;
  double unitCost = 0;
  DateTime? expiryDate;
  String batchNumber = '';
}

/// Card widget for entering purchase item details.
class _PurchaseItemCard extends StatefulWidget {
  const _PurchaseItemCard({
    required this.item,
    required this.inventory,
    required this.onRemove,
    super.key,
  });

  final _PurchaseItemEntry item;
  final List<InventoryItem> inventory;
  final VoidCallback onRemove;

  @override
  State<_PurchaseItemCard> createState() => _PurchaseItemCardState();
}

class _PurchaseItemCardState extends State<_PurchaseItemCard> {
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _batchController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<InventoryItem>(
                    initialValue: widget.item.inventoryItem,
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.inventory.map((inv) {
                      return DropdownMenuItem(
                        value: inv,
                        child: Text('${inv.name} (${inv.unit})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        widget.item.inventoryItem = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select an item' : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onRemove,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: const OutlineInputBorder(),
                      suffix: Text(widget.item.inventoryItem?.unit ?? ''),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      widget.item.quantity = double.tryParse(value) ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitCostController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      widget.item.unitCost = double.tryParse(value) ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch # (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      widget.item.batchNumber = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('Expiry Date'),
                    subtitle: Text(
                      widget.item.expiryDate != null
                          ? '${widget.item.expiryDate!.year}-${widget.item.expiryDate!.month.toString().padLeft(2, '0')}-${widget.item.expiryDate!.day.toString().padLeft(2, '0')}'
                          : 'Not set',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: widget.item.expiryDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setState(() {
                          widget.item.expiryDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
