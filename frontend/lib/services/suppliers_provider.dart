import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/supplier.dart';
import 'graphql_service.dart';

part 'suppliers_provider.g.dart';

/// Provides the list of suppliers from the GraphQL API.
///
/// This is an async provider that fetches suppliers and caches them.
/// Call ref.invalidate(suppliersProvider) to refresh the data.
@riverpod
Future<List<Supplier>> suppliers(Ref ref) async {
  final service = ref.watch(graphqlServiceProvider.notifier);
  return service.getSuppliers();
}
