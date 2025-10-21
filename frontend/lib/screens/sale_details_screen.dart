import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/inventory_item.dart';
import '../models/customer.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';

/// Provider for fetching sale details.
final saleDetailsProvider = FutureProvider.family<SaleWithItems?, String>((ref, saleId) async {
  final graphqlService = ref.read(graphqlServiceProvider.notifier);
  return await graphqlService.getSaleDetails(saleId);
});

class SaleDetailsScreen extends ConsumerWidget {
  final String saleId;

  const SaleDetailsScreen({super.key, required this.saleId});

  String formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleDetailsAsync = ref.watch(saleDetailsProvider(saleId));
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
      ),
      body: saleDetailsAsync.when(
        data: (saleWithItems) {
          if (saleWithItems == null) {
            return const Center(
              child: Text('Sale not found'),
            );
          }

          final sale = saleWithItems.sale;
          final items = saleWithItems.items;
          final customerData = saleWithItems.customer;
          Customer? customer;
          if (customerData != null && customerData is Map<String, dynamic>) {
            customer = Customer.fromJson(customerData);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sale Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sale.saleNumber,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          _PaymentStatusChip(status: sale.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatDate(sale.saleDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (sale.paymentMethod != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Payment: ${_formatPaymentMethod(sale.paymentMethod!)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer Information
              if (customer != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Customer',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (customer.email != null && customer.email!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(customer.email!),
                        ],
                        if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(customer.phone!),
                        ],
                        if (customer.fullAddress.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(customer.fullAddress),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Sale Items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Items (${items.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      inventoryAsync.when(
                        data: (inventory) => Column(
                          children: items.map((item) {
                            final inventoryItem = inventory
                                .where((inv) => inv.id == item.inventoryId)
                                .firstOrNull;
                            return _SaleItemRow(
                              item: item,
                              inventoryItem: inventoryItem,
                            );
                          }).toList(),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Column(
                          children: items.map((item) {
                            return _SaleItemRow(
                              item: item,
                              inventoryItem: null,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Financial Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FinancialRow(
                        label: 'Subtotal',
                        amount: sale.subtotal,
                      ),
                      if (sale.taxAmount > 0) ...[
                        const SizedBox(height: 8),
                        _FinancialRow(
                          label: 'Tax',
                          amount: sale.taxAmount,
                        ),
                      ],
                      if (sale.discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _FinancialRow(
                          label: 'Discount',
                          amount: -sale.discountAmount,
                          color: Colors.green,
                        ),
                      ],
                      const Divider(height: 24),
                      _FinancialRow(
                        label: 'Total',
                        amount: sale.totalAmount,
                        isBold: true,
                        fontSize: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Notes
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notes, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Notes',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(sale.notes!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(saleDetailsProvider(saleId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Credit/Debit Card';
      case 'check':
        return 'Check';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method[0].toUpperCase() + method.substring(1);
    }
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final String status;

  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case 'refunded':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
    }

    return Chip(
      label: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _SaleItemRow extends StatelessWidget {
  final SaleItem item;
  final InventoryItem? inventoryItem;

  const _SaleItemRow({
    required this.item,
    this.inventoryItem,
  });

  @override
  Widget build(BuildContext context) {
    final productName = inventoryItem?.name ?? 'Unknown Product';
    final unit = inventoryItem?.unit ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} $unit @ \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '\$${item.lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _FinancialRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.fontSize = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }
}
