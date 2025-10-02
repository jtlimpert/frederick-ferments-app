// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suppliers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of suppliers from the GraphQL API.
///
/// This is an async provider that fetches suppliers and caches them.
/// Call ref.invalidate(suppliersProvider) to refresh the data.

@ProviderFor(suppliers)
const suppliersProvider = SuppliersProvider._();

/// Provides the list of suppliers from the GraphQL API.
///
/// This is an async provider that fetches suppliers and caches them.
/// Call ref.invalidate(suppliersProvider) to refresh the data.

final class SuppliersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Supplier>>,
          List<Supplier>,
          FutureOr<List<Supplier>>
        >
    with $FutureModifier<List<Supplier>>, $FutureProvider<List<Supplier>> {
  /// Provides the list of suppliers from the GraphQL API.
  ///
  /// This is an async provider that fetches suppliers and caches them.
  /// Call ref.invalidate(suppliersProvider) to refresh the data.
  const SuppliersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suppliersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suppliersHash();

  @$internal
  @override
  $FutureProviderElement<List<Supplier>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Supplier>> create(Ref ref) {
    return suppliers(ref);
  }
}

String _$suppliersHash() => r'8c13c9997aa4315fffccc7156ac9bcfd7b0d1dc4';
