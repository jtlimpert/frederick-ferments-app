import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/production_batch.dart';
import '../services/graphql_service.dart';
import 'complete_production_batch_screen.dart';
import 'create_production_batch_screen.dart';

/// Main production screen showing active batches, makeable products, and history.
class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBatchesAsync = ref.watch(activeBatchesProvider);
    final productionHistoryAsync = ref.watch(
      productionHistoryProvider(productInventoryId: null, limit: 10),
    );
    final finishedProductsAsync = ref.watch(finishedProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProductionBatchScreen(),
            ),
          );
          // Refresh data when returning from create screen
          ref.invalidate(activeBatchesProvider);
          ref.invalidate(productionHistoryProvider);
          ref.invalidate(finishedProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Start Production'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBatchesProvider);
          ref.invalidate(productionHistoryProvider);
          ref.invalidate(finishedProductsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Section 1: In Progress Batches
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'In Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            activeBatchesAsync.when(
              data: (batches) {
                if (batches.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No active batches'),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final batch = batches[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.factory),
                              title: Text(batch.batchNumber),
                              subtitle: Text(
                                '${batch.batchSize} ${batch.unit} • Started ${_formatTimeAgo(batch.startDate)}',
                              ),
                            ),
                            OverflowBar(
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompleteProductionBatchScreen(
                                          batch: batch,
                                        ),
                                      ),
                                    );
                                    // Refresh data when returning from complete screen
                                    ref.invalidate(activeBatchesProvider);
                                    ref.invalidate(productionHistoryProvider);
                                    ref.invalidate(finishedProductsProvider);
                                  },
                                  child: const Text('Complete'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _showFailDialog(context, ref, batch.id);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  child: const Text('Mark Failed'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: batches.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ),

            // Section 2: What Can I Make?
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline),
                    SizedBox(width: 8),
                    Text(
                      'What Can I Make?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            finishedProductsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No finished products configured.\nAdd items with category "finished_product" in inventory.',
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      final hasStock = product.currentStock > 0;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2),
                          title: Text(product.name),
                          subtitle: Text(
                            hasStock
                                ? 'Current stock: ${product.currentStock} ${product.unit}'
                                : 'Out of stock',
                          ),
                          trailing: FilledButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CreateProductionBatchScreen(
                                    preSelectedProduct: product,
                                  ),
                                ),
                              );
                              // Refresh data when returning from create screen
                              ref.invalidate(activeBatchesProvider);
                              ref.invalidate(productionHistoryProvider);
                              ref.invalidate(finishedProductsProvider);
                            },
                            child: const Text('Make'),
                          ),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ),

            // Section 3: Recent Batches
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Text(
                  'Recent Batches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            productionHistoryAsync.when(
              data: (batches) {
                if (batches.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No production history yet'),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final batch = batches[index];
                      return ListTile(
                        leading: Icon(
                          _getStatusIcon(batch.status),
                          color: _getStatusColor(context, batch.status),
                        ),
                        title: Text(batch.batchNumber),
                        subtitle: Text(
                          '${batch.batchSize} ${batch.unit} • ${_formatDate(batch.startDate)}',
                        ),
                        trailing: batch.yieldPercentage != null
                            ? Chip(
                                label: Text('${batch.yieldPercentage!.toStringAsFixed(0)}%'),
                                backgroundColor: _getYieldColor(
                                  context,
                                  batch.yieldPercentage!,
                                ),
                              )
                            : Chip(
                                label: Text(batch.status),
                                backgroundColor: _getStatusColor(
                                  context,
                                  batch.status,
                                ),
                              ),
                      );
                    },
                    childCount: batches.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ),
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'in_progress':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'completed':
        return colorScheme.primaryContainer;
      case 'failed':
        return colorScheme.errorContainer;
      case 'in_progress':
        return colorScheme.secondaryContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getYieldColor(BuildContext context, double yieldPercentage) {
    final colorScheme = Theme.of(context).colorScheme;
    if (yieldPercentage >= 90) {
      return colorScheme.primaryContainer;
    } else if (yieldPercentage >= 70) {
      return colorScheme.tertiaryContainer;
    } else {
      return colorScheme.errorContainer;
    }
  }

  void _showFailDialog(BuildContext context, WidgetRef ref, String batchId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Batch as Failed'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for failure',
            hintText: 'e.g., Starter wasn\'t active',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final service = ref.read(graphqlServiceProvider.notifier);
                final result = await service.failProductionBatch(
                  FailProductionBatchInput(
                    batchId: batchId,
                    reason: reasonController.text.trim(),
                  ),
                );

                if (result.success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                  ref.invalidate(activeBatchesProvider);
                  ref.invalidate(productionHistoryProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Mark Failed'),
          ),
        ],
      ),
    );
  }
}
