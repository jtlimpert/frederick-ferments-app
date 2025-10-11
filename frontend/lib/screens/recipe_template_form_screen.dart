// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe_template.dart';
import '../services/graphql_service.dart';
import '../services/inventory_provider.dart';

/// Screen for creating or editing a recipe template.
class RecipeTemplateFormScreen extends ConsumerStatefulWidget {
  const RecipeTemplateFormScreen({
    super.key,
    this.recipe,
  });

  final RecipeTemplate? recipe;

  @override
  ConsumerState<RecipeTemplateFormScreen> createState() =>
      _RecipeTemplateFormScreenState();
}

/// Helper class to manage ingredient row state
class _IngredientRow {
  String? inventoryId;
  final TextEditingController quantityController;
  String? unit;

  _IngredientRow({
    this.inventoryId,
    String? initialQuantity,
    this.unit,
  }) : quantityController = TextEditingController(text: initialQuantity);

  void dispose() {
    quantityController.dispose();
  }
}

class _RecipeTemplateFormScreenState
    extends ConsumerState<RecipeTemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _batchSizeController = TextEditingController();
  final _unitController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  String? _selectedProductId;
  final List<_IngredientRow> _ingredients = [];
  bool _isLoading = false;

  bool get _isEditMode => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields();
    } else {
      // Start with one empty ingredient row
      _addIngredientRow();
    }
  }

  void _populateFields() {
    final recipe = widget.recipe!;
    _templateNameController.text = recipe.templateName;
    _descriptionController.text = recipe.description ?? '';
    _batchSizeController.text = recipe.defaultBatchSize?.toString() ?? '';
    _unitController.text = recipe.defaultUnit ?? '';
    _durationController.text = recipe.estimatedDurationHours?.toString() ?? '';
    _instructionsController.text = recipe.instructions ?? '';
    _selectedProductId = recipe.productInventoryId;

    // Populate ingredients from recipe
    final ingredients = recipe.ingredients;
    if (ingredients.isNotEmpty) {
      for (final ingredient in ingredients) {
        _ingredients.add(_IngredientRow(
          inventoryId: ingredient.inventoryId,
          initialQuantity: ingredient.quantityPerBatch.toString(),
          unit: ingredient.unit,
        ));
      }
    } else {
      _addIngredientRow();
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _descriptionController.dispose();
    _batchSizeController.dispose();
    _unitController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(_IngredientRow());
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate at least one ingredient
    final validIngredients = _ingredients.where((i) =>
        i.inventoryId != null &&
        i.quantityController.text.isNotEmpty &&
        i.unit != null);

    if (validIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);

      // Build ingredient list
      final ingredients = validIngredients
          .map((i) => IngredientTemplateItem(
                inventoryId: i.inventoryId!,
                quantityPerBatch: double.parse(i.quantityController.text),
                unit: i.unit!,
              ))
          .toList();

      final RecipeTemplateResult result;

      if (_isEditMode) {
        // Update existing recipe
        result = await service.updateRecipeTemplate(
          UpdateRecipeTemplateInput(
            id: widget.recipe!.id,
            productInventoryId: _selectedProductId,
            templateName: _templateNameController.text.trim().isEmpty
                ? null
                : _templateNameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            defaultBatchSize: _batchSizeController.text.isEmpty
                ? null
                : double.parse(_batchSizeController.text),
            defaultUnit: _unitController.text.trim().isEmpty
                ? null
                : _unitController.text.trim(),
            estimatedDurationHours: _durationController.text.isEmpty
                ? null
                : double.parse(_durationController.text),
            ingredients: ingredients,
            instructions: _instructionsController.text.trim().isEmpty
                ? null
                : _instructionsController.text.trim(),
          ),
        );
      } else {
        // Create new recipe
        result = await service.createRecipeTemplate(
          CreateRecipeTemplateInput(
            productInventoryId: _selectedProductId!,
            templateName: _templateNameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            defaultBatchSize: _batchSizeController.text.isEmpty
                ? null
                : double.parse(_batchSizeController.text),
            defaultUnit: _unitController.text.trim().isEmpty
                ? null
                : _unitController.text.trim(),
            estimatedDurationHours: _durationController.text.isEmpty
                ? null
                : double.parse(_durationController.text),
            ingredients: ingredients,
            instructions: _instructionsController.text.trim().isEmpty
                ? null
                : _instructionsController.text.trim(),
          ),
        );
      }

      if (result.success && mounted) {
        // Invalidate recipe templates provider to refresh list
        ref.invalidate(recipeTemplatesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    final finishedProductsAsync = ref.watch(finishedProductsProvider);
    final inventoryItemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Recipe Template' : 'New Recipe Template'),
      ),
      body: finishedProductsAsync.when(
        data: (products) {
          // Note: We continue even if products.isEmpty since recipes can be product-less
          return inventoryItemsAsync.when(
            data: (allItems) {
              // Filter out finished products from ingredient list
              final ingredientItems = allItems
                  .where((item) => item.category != 'finished_product')
                  .toList();

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Product Selection (optional for intermediate/experimental recipes)
                    DropdownButtonFormField<String>(
                      value: products.any((p) => p.id == _selectedProductId)
                          ? _selectedProductId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Product (optional)',
                        helperText: 'Leave empty for intermediate/experimental recipes',
                        border: OutlineInputBorder(),
                      ),
                      items: products.map((product) {
                        return DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProductId = value;
                        });
                      },
                      // No validator - product is now optional
                    ),
                    const SizedBox(height: 16),

                    // Template Name
                    TextFormField(
                      controller: _templateNameController,
                      decoration: const InputDecoration(
                        labelText: 'Template Name *',
                        hintText: 'e.g., Basic Sourdough Bread',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a template name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Batch Size and Unit
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _batchSizeController,
                            decoration: const InputDecoration(
                              labelText: 'Default Batch Size',
                              hintText: 'e.g., 2',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              hintText: 'e.g., loaves',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Estimated Duration
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Duration (hours)',
                        hintText: 'e.g., 24',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 24),

                    // Ingredients Section
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    // Ingredient Rows
                    ...List.generate(_ingredients.length, (index) {
                      final ingredient = _ingredients[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Ingredient ${index + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                    if (_ingredients.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () =>
                                            _removeIngredientRow(index),
                                        tooltip: 'Remove ingredient',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Ingredient Dropdown
                                DropdownButtonFormField<String>(
                                  value: ingredientItems.any(
                                          (i) => i.id == ingredient.inventoryId)
                                      ? ingredient.inventoryId
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Item',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ingredientItems.map((item) {
                                    return DropdownMenuItem(
                                      value: item.id,
                                      child: Text(item.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      ingredient.inventoryId = value;
                                      // Auto-set unit from selected item
                                      if (value != null) {
                                        final selectedItem = ingredientItems
                                            .firstWhere((i) => i.id == value);
                                        ingredient.unit = selectedItem.unit;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Quantity and Unit
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: ingredient.quantityController,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantity per Batch',
                                          hintText: 'e.g., 0.5',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: ingredient.unit,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          ingredient.unit = value;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Add Ingredient Button
                    OutlinedButton.icon(
                      onPressed: _addIngredientRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Ingredient'),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        hintText: 'Step-by-step instructions...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditMode ? 'Update Recipe' : 'Create Recipe'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading ingredients: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading products: $error'),
        ),
      ),
    );
  }
}
