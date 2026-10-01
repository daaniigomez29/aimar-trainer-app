// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ejercicio_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ejercicioRepositorio)
final ejercicioRepositorioProvider = EjercicioRepositorioProvider._();

final class EjercicioRepositorioProvider
    extends
        $FunctionalProvider<
          EjercicioRepositorio,
          EjercicioRepositorio,
          EjercicioRepositorio
        >
    with $Provider<EjercicioRepositorio> {
  EjercicioRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ejercicioRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ejercicioRepositorioHash();

  @$internal
  @override
  $ProviderElement<EjercicioRepositorio> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EjercicioRepositorio create(Ref ref) {
    return ejercicioRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EjercicioRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EjercicioRepositorio>(value),
    );
  }
}

String _$ejercicioRepositorioHash() =>
    r'dc9c532e3672d04d5499a26492f1f2859547b285';
