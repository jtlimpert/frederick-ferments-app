import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/customer.dart';
import '../models/inventory_item.dart';
import '../models/production_batch.dart';
import '../models/purchase.dart';
import '../models/recipe_template.dart';
import '../models/sale.dart';
import '../models/supplier.dart';

part 'graphql_service.g.dart';

/// Returns the appropriate GraphQL endpoint URL based on the platform.
///
/// - Android emulator: Uses 10.0.2.2 to reach host machine's localhost
/// - iOS simulator/macOS/Web: Uses localhost
/// - Production: Should use environment variable or config
String _getGraphqlEndpoint() {
  if (kIsWeb) {
    // Web uses localhost
    return 'http://localhost:4000/graphql';
  }

  if (Platform.isAndroid) {
    // Android emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:4000/graphql';
  }

  // iOS simulator, macOS, and other platforms use localhost
  return 'http://localhost:4000/graphql';
}

/// Provides a configured GraphQL client instance.
@riverpod
GraphQLClient graphqlClient(Ref ref) {
  final httpLink = HttpLink(_getGraphqlEndpoint());

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: httpLink,
  );
}

/// Service for interacting with the Frederick Ferments GraphQL API.
///
/// Provides methods for querying inventory, suppliers,
/// and executing mutations.
@riverpod
class GraphqlService extends _$GraphqlService {
  @override
  void build() {
    // Service is stateless
  }

  GraphQLClient get _client => ref.read(graphqlClientProvider);

  /// GraphQL query to fetch all inventory items.
  static const _inventoryItemsQuery = r'''
    query GetInventoryItems {
      inventoryItems {
        id
        name
        category
        unit
        currentStock
        reservedStock
        availableStock
        reorderPoint
        costPerUnit
        defaultSupplierId
        shelfLifeDays
        storageRequirements
        isActive
        createdAt
        updatedAt
      }
    }
  ''';

  /// GraphQL query to fetch all suppliers.
  static const _suppliersQuery = r'''
    query GetSuppliers {
      suppliers {
        id
        name
        contactEmail
        contactPhone
        streetAddress
        city
        state
        zipCode
        country
        latitude
        longitude
        notes
        createdAt
        updatedAt
      }
    }
  ''';

  /// GraphQL query to check API health.
  static const _healthCheckQuery = r'''
    query HealthCheck {
      healthCheck {
        status
        timestamp
        databaseConnected
        version
        uptimeSeconds
      }
    }
  ''';

  /// GraphQL query to ping the API.
  static const _pingQuery = r'''
    query Ping {
      ping
    }
  ''';

  /// GraphQL mutation to create a purchase.
  static const _createPurchaseMutation = r'''
    mutation CreatePurchase($input: CreatePurchaseInput!) {
      createPurchase(input: $input) {
        success
        message
        updatedItems {
          id
          name
          currentStock
          availableStock
          costPerUnit
        }
      }
    }
  ''';

  static const _deleteInventoryItemMutation = r'''
    mutation DeleteInventoryItem($input: DeleteInventoryItemInput!) {
      deleteInventoryItem(input: $input) {
        success
        message
      }
    }
  ''';

  static const _createInventoryItemMutation = r'''
    mutation CreateInventoryItem($input: CreateInventoryItemInput!) {
      createInventoryItem(input: $input) {
        success
        message
        item {
          id
          name
          category
          unit
          currentStock
          reservedStock
          availableStock
          reorderPoint
          costPerUnit
          defaultSupplierId
          shelfLifeDays
          storageRequirements
          isActive
          createdAt
          updatedAt
        }
      }
    }
  ''';

  static const _updateInventoryItemMutation = r'''
    mutation UpdateInventoryItem($input: UpdateInventoryItemInput!) {
      updateInventoryItem(input: $input) {
        success
        message
        item {
          id
          name
          category
          unit
          currentStock
          reservedStock
          availableStock
          reorderPoint
          costPerUnit
          defaultSupplierId
          shelfLifeDays
          storageRequirements
          isActive
          createdAt
          updatedAt
        }
      }
    }
  ''';

  static const _createSupplierMutation = r'''
    mutation CreateSupplier($input: CreateSupplierInput!) {
      createSupplier(input: $input) {
        success
        message
        supplier {
          id
          name
          contactEmail
          contactPhone
          streetAddress
          city
          state
          zipCode
          country
          latitude
          longitude
          notes
          createdAt
          updatedAt
        }
      }
    }
  ''';

  static const _updateSupplierMutation = r'''
    mutation UpdateSupplier($input: UpdateSupplierInput!) {
      updateSupplier(input: $input) {
        success
        message
        supplier {
          id
          name
          contactEmail
          contactPhone
          streetAddress
          city
          state
          zipCode
          country
          latitude
          longitude
          notes
          createdAt
          updatedAt
        }
      }
    }
  ''';

  /// GraphQL query to fetch active production batches.
  static const _activeBatchesQuery = r'''
    query GetActiveBatches {
      activeBatches {
        id
        batchNumber
        productInventoryId
        recipeTemplateId
        batchSize
        unit
        startDate
        estimatedCompletionDate
        completionDate
        productionDate
        status
        productionTimeHours
        yieldPercentage
        actualYield
        qualityNotes
        storageLocation
        notes
        createdAt
        updatedAt
      }
    }
  ''';

  /// GraphQL query to fetch production history.
  static const _productionHistoryQuery = r'''
    query GetProductionHistory($productInventoryId: UUID, $limit: Int) {
      productionHistory(productInventoryId: $productInventoryId, limit: $limit) {
        id
        batchNumber
        productInventoryId
        recipeTemplateId
        batchSize
        unit
        startDate
        estimatedCompletionDate
        completionDate
        productionDate
        status
        productionTimeHours
        yieldPercentage
        actualYield
        qualityNotes
        storageLocation
        notes
        createdAt
        updatedAt
      }
    }
  ''';

  /// GraphQL query to fetch a specific production batch.
  static const _productionBatchQuery = r'''
    query GetProductionBatch($id: UUID!) {
      productionBatch(id: $id) {
        id
        batchNumber
        productInventoryId
        recipeTemplateId
        batchSize
        unit
        startDate
        estimatedCompletionDate
        completionDate
        productionDate
        status
        productionTimeHours
        yieldPercentage
        actualYield
        qualityNotes
        storageLocation
        notes
        createdAt
        updatedAt
      }
    }
  ''';

  /// GraphQL mutation to create a production batch.
  static const _createProductionBatchMutation = r'''
    mutation CreateProductionBatch($input: CreateProductionBatchInput!) {
      createProductionBatch(input: $input) {
        success
        message
        batchId
        batchNumber
      }
    }
  ''';

  /// GraphQL mutation to complete a production batch.
  static const _completeProductionBatchMutation = r'''
    mutation CompleteProductionBatch($input: CompleteProductionBatchInput!) {
      completeProductionBatch(input: $input) {
        success
        message
        batchId
        batchNumber
      }
    }
  ''';

  /// GraphQL mutation to fail a production batch.
  static const _failProductionBatchMutation = r'''
    mutation FailProductionBatch($input: FailProductionBatchInput!) {
      failProductionBatch(input: $input) {
        success
        message
        batchId
        batchNumber
      }
    }
  ''';

  static const _createRecipeTemplateMutation = r'''
    mutation CreateRecipeTemplate($input: CreateRecipeTemplateInput!) {
      createRecipeTemplate(input: $input) {
        success
        message
        recipe {
          id
          productInventoryId
          templateName
          description
          defaultBatchSize
          defaultUnit
          estimatedDurationHours
          ingredientTemplate
          instructions
          isActive
          createdAt
          updatedAt
        }
      }
    }
  ''';

  static const _updateRecipeTemplateMutation = r'''
    mutation UpdateRecipeTemplate($input: UpdateRecipeTemplateInput!) {
      updateRecipeTemplate(input: $input) {
        success
        message
        recipe {
          id
          productInventoryId
          templateName
          description
          defaultBatchSize
          defaultUnit
          estimatedDurationHours
          ingredientTemplate
          instructions
          isActive
          createdAt
          updatedAt
        }
      }
    }
  ''';

  static const _deleteRecipeTemplateMutation = r'''
    mutation DeleteRecipeTemplate($input: DeleteRecipeTemplateInput!) {
      deleteRecipeTemplate(input: $input) {
        success
        message
      }
    }
  ''';

  /// Fetches all active inventory items from the API.
  ///
  /// Throws an exception if the request fails.
  Future<List<InventoryItem>> getInventoryItems() async {
    try {
      final result = await _client.query(
        QueryOptions(document: gql(_inventoryItemsQuery)),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch inventory items',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final items = result.data?['inventoryItems'] as List<dynamic>? ?? [];
      return items
          .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getInventoryItems',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches all suppliers from the API.
  ///
  /// Throws an exception if the request fails.
  Future<List<Supplier>> getSuppliers() async {
    try {
      final result = await _client.query(
        QueryOptions(document: gql(_suppliersQuery)),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch suppliers',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final suppliers = result.data?['suppliers'] as List<dynamic>? ?? [];
      return suppliers
          .map((supplier) => Supplier.fromJson(supplier as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getSuppliers',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Checks the health of the GraphQL API.
  ///
  /// Returns a map containing health status information.
  /// Throws an exception if the request fails.
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final result = await _client.query(
        QueryOptions(document: gql(_healthCheckQuery)),
      );

      if (result.hasException) {
        developer.log(
          'Health check failed',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      return result.data?['healthCheck'] as Map<String, dynamic>? ?? {};
    } catch (e, s) {
      developer.log(
        'Error in healthCheck',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Pings the GraphQL API to verify connectivity.
  ///
  /// Returns "pong" if successful.
  /// Throws an exception if the request fails.
  Future<String> ping() async {
    try {
      final result = await _client.query(
        QueryOptions(document: gql(_pingQuery)),
      );

      if (result.hasException) {
        developer.log(
          'Ping failed',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      return result.data?['ping'] as String? ?? '';
    } catch (e, s) {
      developer.log(
        'Error in ping',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a purchase and updates inventory stock levels.
  ///
  /// Records a purchase from a supplier, adding stock to inventory items
  /// and logging the transaction in the inventory_log table.
  ///
  /// Returns a [PurchaseResult] with success status and updated items.
  /// Throws an exception if the request fails.
  Future<PurchaseResult> createPurchase(CreatePurchaseInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createPurchaseMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create purchase',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final purchaseData = result.data?['createPurchase'] as Map<String, dynamic>?;
      if (purchaseData == null) {
        throw Exception('No data returned from createPurchase mutation');
      }

      return PurchaseResult.fromJson(purchaseData);
    } catch (e, s) {
      developer.log(
        'Error in createPurchase',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a new inventory item.
  ///
  /// Returns an [InventoryItemResult] with the created item.
  /// Throws an exception if the request fails.
  Future<InventoryItemResult> createInventoryItem(CreateInventoryItemInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createInventoryItemMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create inventory item',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final itemData = result.data?['createInventoryItem'] as Map<String, dynamic>?;
      if (itemData == null) {
        throw Exception('No data returned from createInventoryItem mutation');
      }

      return InventoryItemResult.fromJson(itemData);
    } catch (e, s) {
      developer.log(
        'Error in createInventoryItem',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Updates an existing inventory item.
  ///
  /// Returns an [InventoryItemResult] with the updated item.
  /// Throws an exception if the request fails.
  Future<InventoryItemResult> updateInventoryItem(UpdateInventoryItemInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_updateInventoryItemMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to update inventory item',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final itemData = result.data?['updateInventoryItem'] as Map<String, dynamic>?;
      if (itemData == null) {
        throw Exception('No data returned from updateInventoryItem mutation');
      }

      return InventoryItemResult.fromJson(itemData);
    } catch (e, s) {
      developer.log(
        'Error in updateInventoryItem',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Deletes an inventory item from the database.
  ///
  /// Throws an exception if the request fails or if the item is in use.
  Future<DeleteResult> deleteInventoryItem(DeleteInventoryItemInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_deleteInventoryItemMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to delete inventory item',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final deleteData = result.data?['deleteInventoryItem'] as Map<String, dynamic>?;
      if (deleteData == null) {
        throw Exception('No data returned from deleteInventoryItem mutation');
      }

      return DeleteResult.fromJson(deleteData);
    } catch (e, s) {
      developer.log(
        'Error in deleteInventoryItem',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a new supplier.
  ///
  /// Returns a [SupplierResult] with the created supplier.
  /// Throws an exception if the request fails.
  Future<SupplierResult> createSupplier(CreateSupplierInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createSupplierMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create supplier',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final supplierData = result.data?['createSupplier'] as Map<String, dynamic>?;
      if (supplierData == null) {
        throw Exception('No data returned from createSupplier mutation');
      }

      return SupplierResult.fromJson(supplierData);
    } catch (e, s) {
      developer.log(
        'Error in createSupplier',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Updates an existing supplier.
  ///
  /// Returns a [SupplierResult] with the updated supplier.
  /// Throws an exception if the request fails.
  Future<SupplierResult> updateSupplier(UpdateSupplierInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_updateSupplierMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to update supplier',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final supplierData = result.data?['updateSupplier'] as Map<String, dynamic>?;
      if (supplierData == null) {
        throw Exception('No data returned from updateSupplier mutation');
      }

      return SupplierResult.fromJson(supplierData);
    } catch (e, s) {
      developer.log(
        'Error in updateSupplier',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a new recipe template.
  ///
  /// Throws an exception if the request fails.
  Future<RecipeTemplateResult> createRecipeTemplate(
      CreateRecipeTemplateInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createRecipeTemplateMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create recipe template',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final recipeData =
          result.data?['createRecipeTemplate'] as Map<String, dynamic>?;
      if (recipeData == null) {
        throw Exception('No data returned from createRecipeTemplate mutation');
      }

      return RecipeTemplateResult.fromJson(recipeData);
    } catch (e, s) {
      developer.log(
        'Error in createRecipeTemplate',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Updates an existing recipe template.
  ///
  /// Throws an exception if the request fails.
  Future<RecipeTemplateResult> updateRecipeTemplate(
      UpdateRecipeTemplateInput input) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_updateRecipeTemplateMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to update recipe template',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final recipeData =
          result.data?['updateRecipeTemplate'] as Map<String, dynamic>?;
      if (recipeData == null) {
        throw Exception('No data returned from updateRecipeTemplate mutation');
      }

      return RecipeTemplateResult.fromJson(recipeData);
    } catch (e, s) {
      developer.log(
        'Error in updateRecipeTemplate',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Deletes a recipe template (soft delete).
  ///
  /// Throws an exception if the request fails.
  Future<DeleteResult> deleteRecipeTemplate(String id) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_deleteRecipeTemplateMutation),
          variables: {
            'input': {'id': id}
          },
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to delete recipe template',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final deleteData =
          result.data?['deleteRecipeTemplate'] as Map<String, dynamic>?;
      if (deleteData == null) {
        throw Exception('No data returned from deleteRecipeTemplate mutation');
      }

      return DeleteResult.fromJson(deleteData);
    } catch (e, s) {
      developer.log(
        'Error in deleteRecipeTemplate',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches all active production batches from the API.
  ///
  /// Returns batches with status 'in_progress'.
  /// Throws an exception if the request fails.
  Future<List<ProductionBatch>> getActiveBatches() async {
    try {
      final result = await _client.query(
        QueryOptions(document: gql(_activeBatchesQuery)),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch active batches',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final batches = result.data?['activeBatches'] as List<dynamic>? ?? [];
      return batches
          .map((batch) => ProductionBatch.fromJson(batch as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getActiveBatches',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches production history from the API.
  ///
  /// Optionally filter by product ID and limit number of results.
  /// Throws an exception if the request fails.
  Future<List<ProductionBatch>> getProductionHistory({
    String? productInventoryId,
    int limit = 50,
  }) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_productionHistoryQuery),
          variables: {
            if (productInventoryId != null) 'productInventoryId': productInventoryId,
            'limit': limit,
          },
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch production history',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final batches = result.data?['productionHistory'] as List<dynamic>? ?? [];
      return batches
          .map((batch) => ProductionBatch.fromJson(batch as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getProductionHistory',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches a specific production batch by ID.
  ///
  /// Returns null if not found.
  /// Throws an exception if the request fails.
  Future<ProductionBatch?> getProductionBatch(String id) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_productionBatchQuery),
          variables: {'id': id},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch production batch',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final batchData = result.data?['productionBatch'] as Map<String, dynamic>?;
      if (batchData == null) {
        return null;
      }

      return ProductionBatch.fromJson(batchData);
    } catch (e, s) {
      developer.log(
        'Error in getProductionBatch',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a production batch and consumes ingredients.
  ///
  /// Records ingredient consumption in inventory_log and decrements stock.
  /// Returns a [ProductionBatchResult] with success status and batch info.
  /// Throws an exception if the request fails.
  Future<ProductionBatchResult> createProductionBatch(
    CreateProductionBatchInput input,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createProductionBatchMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create production batch',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final batchData = result.data?['createProductionBatch'] as Map<String, dynamic>?;
      if (batchData == null) {
        throw Exception('No data returned from createProductionBatch mutation');
      }

      return ProductionBatchResult.fromJson(batchData);
    } catch (e, s) {
      developer.log(
        'Error in createProductionBatch',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Completes a production batch and adds finished product to inventory.
  ///
  /// Records production output in inventory_log and increments stock.
  /// Returns a [ProductionBatchResult] with success status.
  /// Throws an exception if the request fails.
  Future<ProductionBatchResult> completeProductionBatch(
    CompleteProductionBatchInput input,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_completeProductionBatchMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to complete production batch',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final batchData = result.data?['completeProductionBatch'] as Map<String, dynamic>?;
      if (batchData == null) {
        throw Exception('No data returned from completeProductionBatch mutation');
      }

      return ProductionBatchResult.fromJson(batchData);
    } catch (e, s) {
      developer.log(
        'Error in completeProductionBatch',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Marks a production batch as failed.
  ///
  /// Returns a [ProductionBatchResult] with success status.
  /// Throws an exception if the request fails.
  Future<ProductionBatchResult> failProductionBatch(
    FailProductionBatchInput input,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_failProductionBatchMutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fail production batch',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final batchData = result.data?['failProductionBatch'] as Map<String, dynamic>?;
      if (batchData == null) {
        throw Exception('No data returned from failProductionBatch mutation');
      }

      return ProductionBatchResult.fromJson(batchData);
    } catch (e, s) {
      developer.log(
        'Error in failProductionBatch',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches all active recipe templates from the API.
  ///
  /// Throws an exception if the request fails.
  Future<List<RecipeTemplate>> getRecipeTemplates() async {
    const query = '''
      query GetRecipeTemplates {
        recipeTemplates {
          id
          productInventoryId
          templateName
          description
          defaultBatchSize
          defaultUnit
          estimatedDurationHours
          ingredientTemplate
          instructions
          isActive
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(document: gql(query)),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch recipe templates',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final templates = result.data?['recipeTemplates'] as List<dynamic>? ?? [];
      return templates
          .map((template) => RecipeTemplate.fromJson(template as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getRecipeTemplates',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // =========================================================================
  // Customer Methods
  // =========================================================================

  /// Fetches all active customers from the API.
  Future<List<Customer>> getCustomers() async {
    const query = '''
      query GetCustomers {
        customers {
          id
          name
          email
          phone
          streetAddress
          city
          state
          zipCode
          country
          latitude
          longitude
          customerType
          taxExempt
          notes
          isActive
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final result = await _client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        developer.log(
          'Failed to fetch customers',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final customers = result.data?['customers'] as List<dynamic>? ?? [];
      return customers
          .map((customer) => Customer.fromJson(customer as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getCustomers',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a new customer.
  Future<Map<String, dynamic>> createCustomer(CreateCustomerInput input) async {
    const mutation = '''
      mutation CreateCustomer(\$input: CreateCustomerInput!) {
        createCustomer(input: \$input) {
          success
          message
          customer {
            id
            name
            email
            phone
            streetAddress
            city
            state
            zipCode
            country
            latitude
            longitude
            customerType
            taxExempt
            notes
            isActive
            createdAt
            updatedAt
          }
        }
      }
    ''';

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create customer',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final customerData =
          result.data?['createCustomer'] as Map<String, dynamic>?;
      if (customerData == null) {
        throw Exception('No data returned from createCustomer mutation');
      }

      return customerData;
    } catch (e, s) {
      developer.log(
        'Error in createCustomer',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Updates an existing customer.
  Future<Map<String, dynamic>> updateCustomer(UpdateCustomerInput input) async {
    const mutation = '''
      mutation UpdateCustomer(\$input: UpdateCustomerInput!) {
        updateCustomer(input: \$input) {
          success
          message
          customer {
            id
            name
            email
            phone
            streetAddress
            city
            state
            zipCode
            country
            latitude
            longitude
            customerType
            taxExempt
            notes
            isActive
            createdAt
            updatedAt
          }
        }
      }
    ''';

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to update customer',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final customerData =
          result.data?['updateCustomer'] as Map<String, dynamic>?;
      if (customerData == null) {
        throw Exception('No data returned from updateCustomer mutation');
      }

      return customerData;
    } catch (e, s) {
      developer.log(
        'Error in updateCustomer',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // =========================================================================
  // Sales Methods
  // =========================================================================

  /// Fetches sales with optional filters.
  Future<List<Sale>> getSales({
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    const query = '''
      query GetSales(\$customerId: UUID, \$startDate: DateTime, \$endDate: DateTime, \$limit: Int) {
        sales(customerId: \$customerId, startDate: \$startDate, endDate: \$endDate, limit: \$limit) {
          id
          saleNumber
          customerId
          saleDate
          subtotal
          taxAmount
          discountAmount
          totalAmount
          paymentMethod
          paymentStatus
          notes
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {
            if (customerId != null) 'customerId': customerId,
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
            'limit': limit,
          },
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch sales',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final sales = result.data?['sales'] as List<dynamic>? ?? [];
      return sales
          .map((sale) => Sale.fromJson(sale as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getSales',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches full sale details including items and customer.
  Future<SaleWithItems?> getSaleDetails(String saleId) async {
    const query = '''
      query GetSaleDetails(\$saleId: UUID!) {
        saleDetails(saleId: \$saleId) {
          sale {
            id
            saleNumber
            customerId
            saleDate
            subtotal
            taxAmount
            discountAmount
            totalAmount
            paymentMethod
            paymentStatus
            notes
            createdAt
            updatedAt
          }
          items {
            id
            saleId
            inventoryId
            quantity
            unitPrice
            lineTotal
            notes
          }
          customer {
            id
            name
            email
            phone
            streetAddress
            city
            state
            zipCode
            country
            customerType
            taxExempt
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'saleId': saleId},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch sale details',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final saleDetailsData = result.data?['saleDetails'] as Map<String, dynamic>?;
      if (saleDetailsData == null) {
        return null;
      }

      return SaleWithItems.fromJson(saleDetailsData);
    } catch (e, s) {
      developer.log(
        'Error in getSaleDetails',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Creates a new sale.
  Future<Map<String, dynamic>> createSale(CreateSaleInput input) async {
    const mutation = '''
      mutation CreateSale(\$input: CreateSaleInput!) {
        createSale(input: \$input) {
          success
          message
          saleId
          saleNumber
          updatedItems {
            id
            name
            currentStock
            availableStock
          }
        }
      }
    ''';

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'input': input.toJson()},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to create sale',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final saleData = result.data?['createSale'] as Map<String, dynamic>?;
      if (saleData == null) {
        throw Exception('No data returned from createSale mutation');
      }

      return saleData;
    } catch (e, s) {
      developer.log(
        'Error in createSale',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}

/// Riverpod provider for active production batches.
@riverpod
Future<List<ProductionBatch>> activeBatches(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getActiveBatches();
}

/// Riverpod provider for production history.
@riverpod
Future<List<ProductionBatch>> productionHistory(
  Ref ref, {
  String? productInventoryId,
  int limit = 50,
}) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getProductionHistory(
    productInventoryId: productInventoryId,
    limit: limit,
  );
}

/// Riverpod provider for finished products (filtered inventory items).
@riverpod
Future<List<InventoryItem>> finishedProducts(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  final items = await service.getInventoryItems();
  return items.where((item) => item.category == 'finished_product').toList();
}

/// Riverpod provider for recipe templates.
@riverpod
Future<List<RecipeTemplate>> recipeTemplates(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getRecipeTemplates();
}

/// Riverpod provider for customers.
@riverpod
Future<List<Customer>> customers(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getCustomers();
}

/// Riverpod provider for sales.
@riverpod
Future<List<Sale>> sales(
  Ref ref, {
  String? customerId,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 50,
}) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getSales(
    customerId: customerId,
    startDate: startDate,
    endDate: endDate,
    limit: limit,
  );
}
