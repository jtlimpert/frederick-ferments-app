import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

/// A card widget that displays an inventory item's key information.
///
/// Shows the item name, category, stock levels, and visual indicators
/// for reorder status.
class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    required this.item,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  final InventoryItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  /// Determines the stock status based on available stock vs reorder point.
  StockStatus get _stockStatus {
    if (item.availableStock <= item.reorderPoint) {
      return StockStatus.critical;
    } else if (item.availableStock <= item.reorderPoint * 1.2) {
      return StockStatus.low;
    }
    return StockStatus.healthy;
  }

  /// Gets the color for the stock status indicator.
  Color _getStatusColor(BuildContext context) {
    switch (_stockStatus) {
      case StockStatus.critical:
        return Colors.red.shade700;
      case StockStatus.low:
        return Colors.orange.shade700;
      case StockStatus.healthy:
        return Colors.green.shade700;
    }
  }

  /// Gets the icon for the stock status indicator.
  IconData _getStatusIcon() {
    switch (_stockStatus) {
      case StockStatus.critical:
        return Icons.error;
      case StockStatus.low:
        return Icons.warning;
      case StockStatus.healthy:
        return Icons.check_circle;
    }
  }

  /// Gets the status message text.
  String? _getStatusMessage() {
    switch (_stockStatus) {
      case StockStatus.critical:
        return 'Reorder needed!';
      case StockStatus.low:
        return 'Running low';
      case StockStatus.healthy:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, status icon, and delete button
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  _getStatusIcon(),
                  color: statusColor,
                  size: 28,
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Edit item',
                    iconSize: 24,
                    color: theme.colorScheme.primary,
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: 'Delete item',
                    iconSize: 24,
                    color: theme.colorScheme.error,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Category badge
            Chip(
              label: Text(
                item.category,
                style: theme.textTheme.bodySmall,
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 12),

            // Stock information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Stock',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.availableStock.toStringAsFixed(1)} ${item.unit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.reservedStock > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reserved',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.reservedStock.toStringAsFixed(1)} ${item.unit}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Stock progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.reorderPoint > 0
                    ? (item.availableStock / (item.reorderPoint * 2))
                        .clamp(0.0, 1.0)
                    : 1.0,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Additional info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.costPerUnit != null)
                  Text(
                    'Cost: \$${item.costPerUnit!.toStringAsFixed(2)}/${item.unit}',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  const SizedBox.shrink(),
                if (_getStatusMessage() != null)
                  Text(
                    _getStatusMessage()!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
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

/// Represents the stock status of an inventory item.
enum StockStatus {
  /// Stock is at or below reorder point.
  critical,

  /// Stock is within 20% above reorder point.
  low,

  /// Stock is healthy.
  healthy,
}
