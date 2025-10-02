import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inventory_item.dart';
import 'graphql_service.dart';

part 'inventory_provider.g.dart';

/// Provides the list of inventory items from the GraphQL API.
///
/// This is an async provider that fetches inventory items and caches them.
/// Call ref.invalidate(inventoryItemsProvider) to refresh the data.
@riverpod
Future<List<InventoryItem>> inventoryItems(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getInventoryItems();
}
