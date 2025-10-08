import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';
import '../widgets/inventory_item_card.dart';
import 'create_purchase_screen.dart';

/// Main screen displaying the list of inventory items.
///
/// Shows items with their stock levels, categories, and reorder status.
/// Supports pull-to-refresh to reload data.
class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    final body = inventoryAsync.when(
      data: (items) => _buildInventoryList(context, ref, items),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );

    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Frederick Ferments Inventory'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(inventoryItemsProvider);
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreatePurchaseScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('New Purchase'),
        ),
      );
    }

    // When embedded in navigation, show title bar without full AppBar
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(inventoryItemsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreatePurchaseScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Purchase'),
      ),
    );
  }

  /// Builds the list of inventory items.
  Widget _buildInventoryList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inventoryItemsProvider);
        // Wait for the refresh to complete
        await ref.read(inventoryItemsProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index] as InventoryItem;
          return InventoryItemCard(
            item: item,
            onDelete: () => _showDeleteConfirmation(context, ref, item),
          );
        },
      ),
    );
  }

  /// Shows a confirmation dialog before deleting an item.
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${item.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(context, ref, item);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Deletes an inventory item.
  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    // Capture context values before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.deleteInventoryItem(
        DeleteInventoryItemInput(inventoryId: item.id),
      );

      if (result.success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        // Refresh the inventory list
        ref.invalidate(inventoryItemsProvider);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  /// Builds the loading state with shimmer effect.
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading inventory...'),
        ],
      ),
    );
  }

  /// Builds the error state with retry button.
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load inventory',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(inventoryItemsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state when no items exist.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No inventory items found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
