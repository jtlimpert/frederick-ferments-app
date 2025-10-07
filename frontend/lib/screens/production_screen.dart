import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/production_batch.dart';
import '../models/production_reminder.dart';
import '../services/graphql_service.dart';
import 'complete_production_batch_screen.dart';
import 'create_production_batch_screen.dart';

/// Main production screen showing active batches, makeable products, and history.
class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBatchesAsync = ref.watch(activeBatchesProvider);
    final pendingRemindersAsync = ref.watch(pendingRemindersProvider);
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
          ref.invalidate(pendingRemindersProvider);
          ref.invalidate(productionHistoryProvider);
          ref.invalidate(finishedProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Start Production'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBatchesProvider);
          ref.invalidate(pendingRemindersProvider);
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
                                    ref.invalidate(pendingRemindersProvider);
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

            // Section 1.5: Pending Reminders
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reminders',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            pendingRemindersAsync.when(
              data: (reminders) {
                // Filter to show due and upcoming reminders (not snoozed)
                final activeReminders = reminders.where((r) => !r.isSnoozed).toList();

                if (activeReminders.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'No pending reminders',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reminder = activeReminders[index];
                      final isDue = reminder.isDue;

                      // Find the batch for this reminder
                      ProductionBatch? batch;
                      try {
                        batch = activeBatchesAsync.value?.firstWhere(
                          (b) => b.id == reminder.batchId,
                        );
                      } catch (e) {
                        // Batch not found in active batches
                        batch = null;
                      }
                      final batchNumber = batch?.batchNumber ?? 'Unknown Batch';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: isDue
                            ? Colors.orange.shade50
                            : null,
                        child: ListTile(
                          leading: Icon(
                            isDue ? Icons.alarm : Icons.schedule,
                            color: isDue ? Colors.orange : Colors.blue,
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(reminder.message)),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  batchNumber,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                isDue
                                    ? 'Due ${_formatTimeAgo(reminder.dueAt)}'
                                    : 'Due ${_formatUpcomingTime(reminder.dueAt)}',
                                style: TextStyle(
                                  color: isDue ? Colors.orange.shade700 : null,
                                  fontWeight: isDue ? FontWeight.w600 : null,
                                ),
                              ),
                              Text(
                                'Type: ${reminder.reminderType}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Snooze button
                              IconButton(
                                icon: const Icon(Icons.snooze, size: 20),
                                tooltip: 'Snooze',
                                onPressed: () => _showSnoozeDialog(
                                  context,
                                  ref,
                                  reminder,
                                ),
                              ),
                              // Complete button
                              IconButton(
                                icon: const Icon(Icons.check_circle, size: 20),
                                tooltip: 'Complete',
                                color: Colors.green,
                                onPressed: () => _completeReminder(
                                  context,
                                  ref,
                                  reminder,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: activeReminders.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading reminders: $error'),
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
                              ref.invalidate(pendingRemindersProvider);
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

  // Helper method to format date time for upcoming reminders
  static String _formatUpcomingTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hours';
    } else if (difference.inDays == 0) {
      return 'today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'tomorrow at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return 'in ${difference.inDays} days';
    }
  }

  // Show snooze dialog
  static void _showSnoozeDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionReminder reminder,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15 minutes'),
              onTap: () {
                Navigator.pop(context);
                _snoozeReminder(
                  context,
                  ref,
                  reminder,
                  DateTime.now().add(const Duration(minutes: 15)),
                );
              },
            ),
            ListTile(
              title: const Text('1 hour'),
              onTap: () {
                Navigator.pop(context);
                _snoozeReminder(
                  context,
                  ref,
                  reminder,
                  DateTime.now().add(const Duration(hours: 1)),
                );
              },
            ),
            ListTile(
              title: const Text('4 hours'),
              onTap: () {
                Navigator.pop(context);
                _snoozeReminder(
                  context,
                  ref,
                  reminder,
                  DateTime.now().add(const Duration(hours: 4)),
                );
              },
            ),
            ListTile(
              title: const Text('Tomorrow'),
              onTap: () {
                Navigator.pop(context);
                _snoozeReminder(
                  context,
                  ref,
                  reminder,
                  DateTime.now().add(const Duration(days: 1)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Snooze reminder
  static Future<void> _snoozeReminder(
    BuildContext context,
    WidgetRef ref,
    ProductionReminder reminder,
    DateTime snoozeUntil,
  ) async {
    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.snoozeReminder(
        SnoozeReminderInput(
          reminderId: reminder.id,
          snoozeUntil: snoozeUntil,
        ),
      );

      if (result.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        ref.invalidate(pendingRemindersProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Complete reminder
  static Future<void> _completeReminder(
    BuildContext context,
    WidgetRef ref,
    ProductionReminder reminder,
  ) async {
    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.completeReminder(
        CompleteReminderInput(
          reminderId: reminder.id,
        ),
      );

      if (result.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        ref.invalidate(pendingRemindersProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
