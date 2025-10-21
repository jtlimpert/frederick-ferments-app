import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _taxAmountController = TextEditingController(text: '0');
  final _discountAmountController = TextEditingController(text: '0');

  Customer? _selectedCustomer;
  String _paymentMethod = 'cash';
  DateTime _saleDate = DateTime.now();
  final List<SaleItemInput> _saleItems = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _taxAmountController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }

  void _addSaleItem() {
    setState(() {
      _saleItems.add(SaleItemInput(
        inventoryId: '',
        quantity: 1.0,
        unitPrice: 0.0,
        notes: null,
      ));
    });
  }

  void _removeSaleItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
  }

  double get _subtotal {
    return _saleItems.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  double get _taxAmount {
    return double.tryParse(_taxAmountController.text) ?? 0.0;
  }

  double get _discountAmount {
    return double.tryParse(_discountAmountController.text) ?? 0.0;
  }

  double get _totalAmount {
    return _subtotal + _taxAmount - _discountAmount;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the sale')),
      );
      return;
    }

    if (_saleItems.any((item) => item.inventoryId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item for all sale items')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final graphqlService = ref.read(graphqlServiceProvider.notifier);

      final input = CreateSaleInput(
        customerId: _selectedCustomer?.id,
        saleDate: _saleDate,
        taxAmount: _taxAmount,
        discountAmount: _discountAmount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _saleItems,
      );

      final result = await graphqlService.createSale(input);

      if (mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(salesProvider);
        ref.invalidate(inventoryItemsProvider);

        final message = result['message'] as String? ?? 'Sale created successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.of(context).pop();
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
    final customersAsync = ref.watch(customersProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sale'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sale Information Section
            Text(
              'Sale Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Customer Selection
            customersAsync.when(
              data: (customers) => DropdownButtonFormField<Customer>(
                initialValue: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Customer (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text(customer.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load customers'),
            ),
            const SizedBox(height: 16),

            // Sale Date
            ListTile(
              title: const Text('Sale Date'),
              subtitle: Text(_saleDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _saleDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _saleDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                DropdownMenuItem(value: 'check', child: Text('Check')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paymentMethod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Sale Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sale Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addSaleItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sale Items List
            if (_saleItems.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No items added. Click "Add Item" to start.'),
                  ),
                ),
              )
            else
              inventoryAsync.when(
                data: (inventory) => Column(
                  children: _saleItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _SaleItemRow(
                      key: ValueKey(index),
                      item: item,
                      index: index,
                      inventory: inventory,
                      onRemove: () => _removeSaleItem(index),
                      onChanged: (updatedItem) {
                        setState(() {
                          _saleItems[index] = updatedItem;
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load inventory'),
              ),

            const SizedBox(height: 24),

            // Financial Details Section
            Text(
              'Financial Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Subtotal (read-only)
            TextFormField(
              initialValue: _subtotal.toStringAsFixed(2),
              decoration: const InputDecoration(
                labelText: 'Subtotal',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Tax Amount
            TextFormField(
              controller: _taxAmountController,
              decoration: const InputDecoration(
                labelText: 'Tax Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Discount Amount
            TextFormField(
              controller: _discountAmountController,
              decoration: const InputDecoration(
                labelText: 'Discount Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Total (read-only)
            TextFormField(
              initialValue: _totalAmount.toStringAsFixed(2),
              decoration: InputDecoration(
                labelText: 'Total Amount',
                border: const OutlineInputBorder(),
                prefixText: '\$',
                filled: true,
                fillColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              enabled: false,
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit Button
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
                    : const Text('Record Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleItemRow extends StatefulWidget {
  const _SaleItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.inventory,
    required this.onRemove,
    required this.onChanged,
  });

  final SaleItemInput item;
  final int index;
  final List<InventoryItem> inventory;
  final VoidCallback onRemove;
  final ValueChanged<SaleItemInput> onChanged;

  @override
  State<_SaleItemRow> createState() => _SaleItemRowState();
}

class _SaleItemRowState extends State<_SaleItemRow> {
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _unitPriceController = TextEditingController(text: widget.item.unitPrice.toString());
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateItem() {
    widget.onChanged(
      SaleItemInput(
        inventoryId: widget.item.inventoryId,
        quantity: double.tryParse(_quantityController.text) ?? 0.0,
        unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.inventory
        .where((inv) => inv.id == widget.item.inventoryId)
        .firstOrNull;

    final lineTotal = widget.item.quantity * widget.item.unitPrice;

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
                Text(
                  'Item ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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

            // Inventory Item Selection
            DropdownButtonFormField<String>(
              initialValue: widget.item.inventoryId.isEmpty ? null : widget.item.inventoryId,
              decoration: const InputDecoration(
                labelText: 'Product *',
                border: OutlineInputBorder(),
              ),
              items: widget.inventory.map((inv) {
                return DropdownMenuItem(
                  value: inv.id,
                  child: Text('${inv.name} (Stock: ${inv.availableStock} ${inv.unit})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedInv = widget.inventory.firstWhere((inv) => inv.id == value);
                  // Auto-fill unit price if available
                  if (selectedInv.costPerUnit != null && selectedInv.costPerUnit! > 0) {
                    // Use 2x cost as suggested selling price
                    _unitPriceController.text = (selectedInv.costPerUnit! * 2).toStringAsFixed(2);
                  }
                  widget.onChanged(
                    SaleItemInput(
                      inventoryId: value,
                      quantity: widget.item.quantity,
                      unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
                      notes: widget.item.notes,
                    ),
                  );
                }
              },
            ),

            if (selectedItem != null && selectedItem.availableStock < widget.item.quantity)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Warning: Insufficient stock (available: ${selectedItem.availableStock} ${selectedItem.unit})',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Quantity and Unit Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      border: const OutlineInputBorder(),
                      suffixText: selectedItem?.unit ?? '',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                    ],
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price *',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => _updateItem(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Line Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Line Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => _updateItem(),
            ),
          ],
        ),
      ),
    );
  }
}
