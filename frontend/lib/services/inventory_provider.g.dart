// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of inventory items from the GraphQL API.
///
/// This is an async provider that fetches inventory items and caches them.
/// Call ref.invalidate(inventoryItemsProvider) to refresh the data.

@ProviderFor(inventoryItems)
const inventoryItemsProvider = InventoryItemsProvider._();

/// Provides the list of inventory items from the GraphQL API.
///
/// This is an async provider that fetches inventory items and caches them.
/// Call ref.invalidate(inventoryItemsProvider) to refresh the data.

final class InventoryItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          FutureOr<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $FutureProvider<List<InventoryItem>> {
  /// Provides the list of inventory items from the GraphQL API.
  ///
  /// This is an async provider that fetches inventory items and caches them.
  /// Call ref.invalidate(inventoryItemsProvider) to refresh the data.
  const InventoryItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemsHash();

  @$internal
  @override
  $FutureProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryItem>> create(Ref ref) {
    return inventoryItems(ref);
  }
}

String _$inventoryItemsHash() => r'92cfa81dbd9080c80b0262ad29adda56d6874fba';
