// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autenticacion_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(autenticacionRepositorio)
final autenticacionRepositorioProvider = AutenticacionRepositorioProvider._();

final class AutenticacionRepositorioProvider
    extends
        $FunctionalProvider<
          AutenticacionRepositorio,
          AutenticacionRepositorio,
          AutenticacionRepositorio
        >
    with $Provider<AutenticacionRepositorio> {
  AutenticacionRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autenticacionRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autenticacionRepositorioHash();

  @$internal
  @override
  $ProviderElement<AutenticacionRepositorio> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AutenticacionRepositorio create(Ref ref) {
    return autenticacionRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutenticacionRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutenticacionRepositorio>(value),
    );
  }
}

String _$autenticacionRepositorioHash() =>
    r'171b198b50fe780b05dded46c8172e9571bdbe3f';
