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

String _$graphqlClientHash() => r'3bbbc687c33c602459cd430a4625f00c0dabd84c';

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

String _$graphqlServiceHash() => r'8186903b08b43726a7aa8f2cdff49036e5fc247b';

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
