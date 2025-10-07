import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/production_batch.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';

/// Screen for completing a production batch.
class CompleteProductionBatchScreen extends ConsumerStatefulWidget {
  const CompleteProductionBatchScreen({
    super.key,
    required this.batch,
  });

  final ProductionBatch batch;

  @override
  ConsumerState<CompleteProductionBatchScreen> createState() =>
      _CompleteProductionBatchScreenState();
}

class _CompleteProductionBatchScreenState
    extends ConsumerState<CompleteProductionBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualYieldController = TextEditingController();
  final _qualityNotesController = TextEditingController();

  bool _isLoading = false;
  double? _yieldPercentage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with expected batch size
    _actualYieldController.text = widget.batch.batchSize.toString();
    _calculateYieldPercentage();

    _actualYieldController.addListener(_calculateYieldPercentage);
  }

  @override
  void dispose() {
    _actualYieldController.dispose();
    _qualityNotesController.dispose();
    super.dispose();
  }

  void _calculateYieldPercentage() {
    final actualYield = double.tryParse(_actualYieldController.text);
    if (actualYield != null && widget.batch.batchSize > 0) {
      setState(() {
        _yieldPercentage = (actualYield / widget.batch.batchSize) * 100;
      });
    } else {
      setState(() {
        _yieldPercentage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Batch'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Batch Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.batch.batchNumber,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expected: ${widget.batch.batchSize} ${widget.batch.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Started: ${_formatDate(widget.batch.startDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actual Yield Input
            TextFormField(
              controller: _actualYieldController,
              decoration: InputDecoration(
                labelText: 'Actual Yield',
                hintText: 'How many did you actually make?',
                border: const OutlineInputBorder(),
                suffixText: widget.batch.unit,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter actual yield';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Yield Percentage Display
            if (_yieldPercentage != null)
              Card(
                color: _getYieldColor(context, _yieldPercentage!),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _getYieldIcon(_yieldPercentage!),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yield',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_yieldPercentage!.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _getYieldLabel(_yieldPercentage!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Quality Notes
            TextFormField(
              controller: _qualityNotesController,
              decoration: const InputDecoration(
                labelText: 'Quality Notes (optional)',
                hintText: 'e.g., Great oven spring, crispy crust',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Complete Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _completeBatch,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('Complete Batch'),
            ),
            const SizedBox(height: 16),

            // Mark as Failed Button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _showFailDialog(context),
              icon: const Icon(Icons.error_outline),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              label: const Text('Mark as Failed'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  IconData _getYieldIcon(double yieldPercentage) {
    if (yieldPercentage >= 90) {
      return Icons.sentiment_very_satisfied;
    } else if (yieldPercentage >= 70) {
      return Icons.sentiment_neutral;
    } else {
      return Icons.sentiment_dissatisfied;
    }
  }

  String _getYieldLabel(double yieldPercentage) {
    if (yieldPercentage >= 90) {
      return 'Excellent';
    } else if (yieldPercentage >= 70) {
      return 'Good';
    } else {
      return 'Low';
    }
  }

  Future<void> _completeBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.completeProductionBatch(
        CompleteProductionBatchInput(
          batchId: widget.batch.id,
          actualYield: double.parse(_actualYieldController.text),
          qualityNotes: _qualityNotesController.text.isEmpty
              ? null
              : _qualityNotesController.text,
        ),
      );

      if (result.success && mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(activeBatchesProvider);
        ref.invalidate(inventoryItemsProvider);
        ref.invalidate(productionHistoryProvider);

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

  void _showFailDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Batch as Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will mark the batch as failed without adding product to inventory.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for failure',
                hintText: 'e.g., Starter wasn\'t active enough',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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

              // Capture context before async gap
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              setState(() {
                _isLoading = true;
              });

              try {
                final service = ref.read(graphqlServiceProvider.notifier);
                final result = await service.failProductionBatch(
                  FailProductionBatchInput(
                    batchId: widget.batch.id,
                    reason: reasonController.text.trim(),
                  ),
                );

                if (!mounted) return;

                if (result.success) {
                  ref.invalidate(activeBatchesProvider);
                  ref.invalidate(productionHistoryProvider);

                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                  navigator.pop();
                }
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
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
