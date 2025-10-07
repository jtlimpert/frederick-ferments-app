import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../models/production_batch.dart';
import '../models/recipe_template.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';

/// Screen for creating a new production batch.
class CreateProductionBatchScreen extends ConsumerStatefulWidget {
  const CreateProductionBatchScreen({
    super.key,
    this.preSelectedProduct,
  });

  final InventoryItem? preSelectedProduct;

  @override
  ConsumerState<CreateProductionBatchScreen> createState() =>
      _CreateProductionBatchScreenState();
}

class _CreateProductionBatchScreenState
    extends ConsumerState<CreateProductionBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchSizeController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _notesController = TextEditingController();

  InventoryItem? _selectedProduct;
  RecipeTemplate? _selectedRecipe;
  bool _isLoading = false;

  // Ingredient inputs (can be pre-populated from recipe template)
  final Map<String, TextEditingController> _ingredientControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.preSelectedProduct;
  }

  @override
  void dispose() {
    _batchSizeController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    for (final controller in _ingredientControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finishedProductsAsync = ref.watch(finishedProductsProvider);
    final inventoryItemsAsync = ref.watch(inventoryItemsProvider);
    final recipeTemplatesAsync = ref.watch(recipeTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Production Batch'),
      ),
      body: finishedProductsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No finished products available.\nAdd items with category "finished_product" in inventory.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Product Selection
                DropdownButtonFormField<InventoryItem>(
                  initialValue: _selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    border: OutlineInputBorder(),
                  ),
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      _selectedProduct = product;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a product';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Recipe Template Selection (Optional)
                recipeTemplatesAsync.when(
                  data: (templates) {
                    // Filter templates by selected product
                    final matchingTemplates = _selectedProduct != null
                        ? templates.where((t) => t.productInventoryId == _selectedProduct!.id).toList()
                        : <RecipeTemplate>[];

                    if (matchingTemplates.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<RecipeTemplate>(
                          initialValue: _selectedRecipe,
                          decoration: const InputDecoration(
                            labelText: 'Recipe Template (Optional)',
                            helperText: 'Select a recipe to auto-create reminders',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None'),
                            ),
                            ...matchingTemplates.map((template) {
                              return DropdownMenuItem(
                                value: template,
                                child: Text(template.templateName),
                              );
                            }),
                          ],
                          onChanged: (template) {
                            setState(() {
                              _selectedRecipe = template;
                              // Pre-fill batch size if recipe has default
                              if (template?.defaultBatchSize != null) {
                                _batchSizeController.text = template!.defaultBatchSize.toString();
                              }
                              // Pre-fill ingredient quantities from template
                              if (template?.ingredientTemplate != null) {
                                final ingredients = template!.ingredientTemplate!['ingredients'] as List?;
                                if (ingredients != null) {
                                  for (final ingredient in ingredients) {
                                    final inventoryId = ingredient['inventory_id'] as String?;
                                    final quantityPerBatch = ingredient['quantity_per_batch'];
                                    if (inventoryId != null && quantityPerBatch != null) {
                                      if (_ingredientControllers.containsKey(inventoryId)) {
                                        _ingredientControllers[inventoryId]!.text =
                                            quantityPerBatch.toString();
                                      }
                                    }
                                  }
                                }
                              }
                            });
                          },
                        ),
                        if (_selectedRecipe != null && _selectedRecipe!.description != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _selectedRecipe!.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Batch Size
                TextFormField(
                  controller: _batchSizeController,
                  decoration: InputDecoration(
                    labelText: 'Batch Size',
                    border: const OutlineInputBorder(),
                    suffixText: _selectedProduct?.unit ?? '',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter batch size';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Ingredients Section
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add the ingredients you\'ll use for this batch:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Dynamic ingredient inputs
                inventoryItemsAsync.when(
                  data: (allItems) {
                    // Show all items except finished products
                    final ingredients = allItems
                        .where((item) => item.category != 'finished_product')
                        .toList();

                    return Column(
                      children: [
                        ...ingredients.map((ingredient) {
                          if (!_ingredientControllers.containsKey(ingredient.id)) {
                            _ingredientControllers[ingredient.id] =
                                TextEditingController();
                          }
                          final controller = _ingredientControllers[ingredient.id]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ingredient.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      suffixText: ingredient.unit,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ ${ingredient.currentStock}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error loading ingredients: $error'),
                ),

                const SizedBox(height: 24),

                // Storage Location
                TextFormField(
                  controller: _storageLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location (optional)',
                    hintText: 'e.g., Fridge #2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any special notes about this batch',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton(
                  onPressed: _isLoading ? null : _createBatch,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Production'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    // Collect ingredients with non-zero quantities
    final ingredients = <IngredientInput>[];
    _ingredientControllers.forEach((inventoryId, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final quantity = double.tryParse(text);
        if (quantity != null && quantity > 0) {
          ingredients.add(IngredientInput(
            inventoryId: inventoryId,
            quantityUsed: quantity,
          ));
        }
      }
    });

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.createProductionBatch(
        CreateProductionBatchInput(
          productInventoryId: _selectedProduct!.id,
          recipeTemplateId: _selectedRecipe?.id,
          batchSize: double.parse(_batchSizeController.text),
          unit: _selectedProduct!.unit,
          storageLocation: _storageLocationController.text.isEmpty
              ? null
              : _storageLocationController.text,
          ingredients: ingredients,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        ),
      );

      if (result.success && mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(activeBatchesProvider);
        ref.invalidate(pendingRemindersProvider);
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
}
