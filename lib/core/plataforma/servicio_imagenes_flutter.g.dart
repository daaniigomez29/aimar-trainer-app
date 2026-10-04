// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servicio_imagenes_flutter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(servicioImagenes)
final servicioImagenesProvider = ServicioImagenesProvider._();

final class ServicioImagenesProvider
    extends
        $FunctionalProvider<
          ServicioImagenes,
          ServicioImagenes,
          ServicioImagenes
        >
    with $Provider<ServicioImagenes> {
  ServicioImagenesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicioImagenesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicioImagenesHash();

  @$internal
  @override
  $ProviderElement<ServicioImagenes> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServicioImagenes create(Ref ref) {
    return servicioImagenes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServicioImagenes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServicioImagenes>(value),
    );
  }
}

String _$servicioImagenesHash() => r'8fad075eba3a6db00ed83ecbf4634731a65bcab5';
