// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_sesion.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Unica fuente de verdad sobre la sesion: escucha los eventos de Auth, resuelve
/// el perfil y expone el [EstadoSesion] que usa el enrutador para decidir la
/// pantalla principal segun rol (CU-01, pasos 5 y 6).

@ProviderFor(ControladorSesion)
final controladorSesionProvider = ControladorSesionProvider._();

/// Unica fuente de verdad sobre la sesion: escucha los eventos de Auth, resuelve
/// el perfil y expone el [EstadoSesion] que usa el enrutador para decidir la
/// pantalla principal segun rol (CU-01, pasos 5 y 6).
final class ControladorSesionProvider
    extends $NotifierProvider<ControladorSesion, EstadoSesion> {
  /// Unica fuente de verdad sobre la sesion: escucha los eventos de Auth, resuelve
  /// el perfil y expone el [EstadoSesion] que usa el enrutador para decidir la
  /// pantalla principal segun rol (CU-01, pasos 5 y 6).
  ControladorSesionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorSesionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorSesionHash();

  @$internal
  @override
  ControladorSesion create() => ControladorSesion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoSesion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoSesion>(value),
    );
  }
}

String _$controladorSesionHash() => r'a21c6de46a79c804a634a39d46b5e07c5f21df44';

/// Unica fuente de verdad sobre la sesion: escucha los eventos de Auth, resuelve
/// el perfil y expone el [EstadoSesion] que usa el enrutador para decidir la
/// pantalla principal segun rol (CU-01, pasos 5 y 6).

abstract class _$ControladorSesion extends $Notifier<EstadoSesion> {
  EstadoSesion build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EstadoSesion, EstadoSesion>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EstadoSesion, EstadoSesion>,
              EstadoSesion,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Rol del usuario con sesion activa, o `null` si no hay sesion resuelta.

@ProviderFor(rolActual)
final rolActualProvider = RolActualProvider._();

/// Rol del usuario con sesion activa, o `null` si no hay sesion resuelta.

final class RolActualProvider
    extends $FunctionalProvider<RolUsuario?, RolUsuario?, RolUsuario?>
    with $Provider<RolUsuario?> {
  /// Rol del usuario con sesion activa, o `null` si no hay sesion resuelta.
  RolActualProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rolActualProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rolActualHash();

  @$internal
  @override
  $ProviderElement<RolUsuario?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RolUsuario? create(Ref ref) {
    return rolActual(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RolUsuario? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RolUsuario?>(value),
    );
  }
}

String _$rolActualHash() => r'6375085d7c04657bd4e45dfce772765255d5836f';
