import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inventory_item.dart';
import '../models/purchase.dart';
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
}
