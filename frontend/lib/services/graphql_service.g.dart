// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graphql_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a configured GraphQL client instance.

@ProviderFor(graphqlClient)
const graphqlClientProvider = GraphqlClientProvider._();

/// Provides a configured GraphQL client instance.

final class GraphqlClientProvider
    extends $FunctionalProvider<GraphQLClient, GraphQLClient, GraphQLClient>
    with $Provider<GraphQLClient> {
  /// Provides a configured GraphQL client instance.
  const GraphqlClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'graphqlClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$graphqlClientHash();

  @$internal
  @override
  $ProviderElement<GraphQLClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GraphQLClient create(Ref ref) {
    return graphqlClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GraphQLClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GraphQLClient>(value),
    );
  }
}

String _$graphqlClientHash() => r'eb0e9d29fcf92c64e5e8f98e219cff63eef7f19c';

/// Service for interacting with the Frederick Ferments GraphQL API.
///
/// Provides methods for querying inventory, suppliers,
/// and executing mutations.

@ProviderFor(GraphqlService)
const graphqlServiceProvider = GraphqlServiceProvider._();

/// Service for interacting with the Frederick Ferments GraphQL API.
///
/// Provides methods for querying inventory, suppliers,
/// and executing mutations.
final class GraphqlServiceProvider
    extends $NotifierProvider<GraphqlService, void> {
  /// Service for interacting with the Frederick Ferments GraphQL API.
  ///
  /// Provides methods for querying inventory, suppliers,
  /// and executing mutations.
  const GraphqlServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'graphqlServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$graphqlServiceHash();

  @$internal
  @override
  GraphqlService create() => GraphqlService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$graphqlServiceHash() => r'37c829a2bec0c52a5dd30806074d0822cad3bf54';

/// Service for interacting with the Frederick Ferments GraphQL API.
///
/// Provides methods for querying inventory, suppliers,
/// and executing mutations.

abstract class _$GraphqlService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

/// Riverpod provider for active production batches.

@ProviderFor(activeBatches)
const activeBatchesProvider = ActiveBatchesProvider._();

/// Riverpod provider for active production batches.

final class ActiveBatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductionBatch>>,
          List<ProductionBatch>,
          FutureOr<List<ProductionBatch>>
        >
    with
        $FutureModifier<List<ProductionBatch>>,
        $FutureProvider<List<ProductionBatch>> {
  /// Riverpod provider for active production batches.
  const ActiveBatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBatchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBatchesHash();

  @$internal
  @override
  $FutureProviderElement<List<ProductionBatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductionBatch>> create(Ref ref) {
    return activeBatches(ref);
  }
}

String _$activeBatchesHash() => r'f785aa45dd4aac259acdf451fa4229f52216a1fa';

/// Riverpod provider for production history.

@ProviderFor(productionHistory)
const productionHistoryProvider = ProductionHistoryFamily._();

/// Riverpod provider for production history.

final class ProductionHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductionBatch>>,
          List<ProductionBatch>,
          FutureOr<List<ProductionBatch>>
        >
    with
        $FutureModifier<List<ProductionBatch>>,
        $FutureProvider<List<ProductionBatch>> {
  /// Riverpod provider for production history.
  const ProductionHistoryProvider._({
    required ProductionHistoryFamily super.from,
    required ({String? productInventoryId, int limit}) super.argument,
  }) : super(
         retry: null,
         name: r'productionHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productionHistoryHash();

  @override
  String toString() {
    return r'productionHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductionBatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductionBatch>> create(Ref ref) {
    final argument = this.argument as ({String? productInventoryId, int limit});
    return productionHistory(
      ref,
      productInventoryId: argument.productInventoryId,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductionHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productionHistoryHash() => r'142c842509920db420d98e51180bbea813d077f3';

/// Riverpod provider for production history.

final class ProductionHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProductionBatch>>,
          ({String? productInventoryId, int limit})
        > {
  const ProductionHistoryFamily._()
    : super(
        retry: null,
        name: r'productionHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Riverpod provider for production history.

  ProductionHistoryProvider call({
    String? productInventoryId,
    int limit = 50,
  }) => ProductionHistoryProvider._(
    argument: (productInventoryId: productInventoryId, limit: limit),
    from: this,
  );

  @override
  String toString() => r'productionHistoryProvider';
}

/// Riverpod provider for finished products (filtered inventory items).

@ProviderFor(finishedProducts)
const finishedProductsProvider = FinishedProductsProvider._();

/// Riverpod provider for finished products (filtered inventory items).

final class FinishedProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          FutureOr<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $FutureProvider<List<InventoryItem>> {
  /// Riverpod provider for finished products (filtered inventory items).
  const FinishedProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'finishedProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$finishedProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryItem>> create(Ref ref) {
    return finishedProducts(ref);
  }
}

String _$finishedProductsHash() => r'0379022a45f5a56f2e86e5b78c2edc6fdf0e3e62';

/// Riverpod provider for recipe templates.

@ProviderFor(recipeTemplates)
const recipeTemplatesProvider = RecipeTemplatesProvider._();

/// Riverpod provider for recipe templates.

final class RecipeTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecipeTemplate>>,
          List<RecipeTemplate>,
          FutureOr<List<RecipeTemplate>>
        >
    with
        $FutureModifier<List<RecipeTemplate>>,
        $FutureProvider<List<RecipeTemplate>> {
  /// Riverpod provider for recipe templates.
  const RecipeTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeTemplatesHash();

  @$internal
  @override
  $FutureProviderElement<List<RecipeTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecipeTemplate>> create(Ref ref) {
    return recipeTemplates(ref);
  }
}

String _$recipeTemplatesHash() => r'0e50e49c4655944f9562b77cead69bc655af83e7';

/// Riverpod provider for customers.

@ProviderFor(customers)
const customersProvider = CustomersProvider._();

/// Riverpod provider for customers.

final class CustomersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Customer>>,
          List<Customer>,
          FutureOr<List<Customer>>
        >
    with $FutureModifier<List<Customer>>, $FutureProvider<List<Customer>> {
  /// Riverpod provider for customers.
  const CustomersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customersHash();

  @$internal
  @override
  $FutureProviderElement<List<Customer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Customer>> create(Ref ref) {
    return customers(ref);
  }
}

String _$customersHash() => r'4a19ca41e9e6489ed209b7e195efbf1998961b20';

/// Riverpod provider for sales.

@ProviderFor(sales)
const salesProvider = SalesFamily._();

/// Riverpod provider for sales.

final class SalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sale>>,
          List<Sale>,
          FutureOr<List<Sale>>
        >
    with $FutureModifier<List<Sale>>, $FutureProvider<List<Sale>> {
  /// Riverpod provider for sales.
  const SalesProvider._({
    required SalesFamily super.from,
    required ({
      String? customerId,
      DateTime? startDate,
      DateTime? endDate,
      int limit,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'salesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$salesHash();

  @override
  String toString() {
    return r'salesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Sale>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sale>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String? customerId,
              DateTime? startDate,
              DateTime? endDate,
              int limit,
            });
    return sales(
      ref,
      customerId: argument.customerId,
      startDate: argument.startDate,
      endDate: argument.endDate,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SalesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$salesHash() => r'e587b9f1f56c1aad3460c7667f07535ba00816d0';

/// Riverpod provider for sales.

final class SalesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Sale>>,
          ({
            String? customerId,
            DateTime? startDate,
            DateTime? endDate,
            int limit,
          })
        > {
  const SalesFamily._()
    : super(
        retry: null,
        name: r'salesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Riverpod provider for sales.

  SalesProvider call({
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) => SalesProvider._(
    argument: (
      customerId: customerId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    ),
    from: this,
  );

  @override
  String toString() => r'salesProvider';
}
