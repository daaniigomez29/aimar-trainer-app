// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progreso_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(progresoRepositorio)
final progresoRepositorioProvider = ProgresoRepositorioProvider._();

final class ProgresoRepositorioProvider
    extends
        $FunctionalProvider<
          ProgresoRepositorio,
          ProgresoRepositorio,
          ProgresoRepositorio
        >
    with $Provider<ProgresoRepositorio> {
  ProgresoRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progresoRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progresoRepositorioHash();

  @$internal
  @override
  $ProviderElement<ProgresoRepositorio> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgresoRepositorio create(Ref ref) {
    return progresoRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgresoRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgresoRepositorio>(value),
    );
  }
}

String _$progresoRepositorioHash() =>
    r'927eaf8b5f67745e3181a5257982c56b0ae5f21d';
