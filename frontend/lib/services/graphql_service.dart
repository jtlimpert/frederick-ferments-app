import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inventory_item.dart';
import '../models/production_batch.dart';
import '../models/production_reminder.dart';
import '../models/purchase.dart';
import '../models/recipe_template.dart';
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
        address
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
          reminderSchedule
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

  /// Fetches all pending reminders from the API.
  ///
  /// Throws an exception if the request fails.
  Future<List<ProductionReminder>> getPendingReminders() async {
    const query = '''
      query GetPendingReminders {
        pendingReminders {
          id
          batchId
          reminderType
          message
          dueAt
          completedAt
          snoozedUntil
          notes
          createdAt
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(document: gql(query)),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch pending reminders',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final reminders = result.data?['pendingReminders'] as List<dynamic>? ?? [];
      return reminders
          .map((reminder) => ProductionReminder.fromJson(reminder as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getPendingReminders',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Fetches reminders for a specific batch from the API.
  ///
  /// Throws an exception if the request fails.
  Future<List<ProductionReminder>> getBatchReminders(String batchId) async {
    const query = '''
      query GetBatchReminders(\$batchId: UUID!) {
        batchReminders(batchId: \$batchId) {
          id
          batchId
          reminderType
          message
          dueAt
          completedAt
          snoozedUntil
          notes
          createdAt
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'batchId': batchId},
        ),
      );

      if (result.hasException) {
        developer.log(
          'Failed to fetch batch reminders',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final reminders = result.data?['batchReminders'] as List<dynamic>? ?? [];
      return reminders
          .map((reminder) => ProductionReminder.fromJson(reminder as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'Error in getBatchReminders',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Snoozes a reminder to a later time.
  ///
  /// Throws an exception if the request fails.
  Future<ReminderResult> snoozeReminder(SnoozeReminderInput input) async {
    const mutation = '''
      mutation SnoozeReminder(\$input: SnoozeReminderInput!) {
        snoozeReminder(input: \$input) {
          success
          message
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
          'Failed to snooze reminder',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final data = result.data?['snoozeReminder'] as Map<String, dynamic>;
      return ReminderResult.fromJson(data);
    } catch (e, s) {
      developer.log(
        'Error in snoozeReminder',
        name: 'graphql_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Completes a reminder.
  ///
  /// Throws an exception if the request fails.
  Future<ReminderResult> completeReminder(CompleteReminderInput input) async {
    const mutation = '''
      mutation CompleteReminder(\$input: CompleteReminderInput!) {
        completeReminder(input: \$input) {
          success
          message
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
          'Failed to complete reminder',
          name: 'graphql_service',
          level: 1000,
          error: result.exception,
        );
        throw Exception(result.exception.toString());
      }

      final data = result.data?['completeReminder'] as Map<String, dynamic>;
      return ReminderResult.fromJson(data);
    } catch (e, s) {
      developer.log(
        'Error in completeReminder',
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

/// Riverpod provider for pending reminders.
@riverpod
Future<List<ProductionReminder>> pendingReminders(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getPendingReminders();
}
