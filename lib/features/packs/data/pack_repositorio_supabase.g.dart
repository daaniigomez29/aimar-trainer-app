// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(packRepositorio)
final packRepositorioProvider = PackRepositorioProvider._();

final class PackRepositorioProvider
    extends
        $FunctionalProvider<PackRepositorio, PackRepositorio, PackRepositorio>
    with $Provider<PackRepositorio> {
  PackRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packRepositorioHash();

  @$internal
  @override
  $ProviderElement<PackRepositorio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PackRepositorio create(Ref ref) {
    return packRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PackRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PackRepositorio>(value),
    );
  }
}

String _$packRepositorioHash() => r'a02326f34ffea69cd388330a171e6b07ad8a9e8d';
