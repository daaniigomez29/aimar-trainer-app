// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_login.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CU-01 Iniciar sesion: valida el formulario y delega en el repositorio.
///
/// No navega: al terminar con exito, `ControladorSesion` recibe el evento de
/// Auth y el enrutador redirige segun el rol.

@ProviderFor(ControladorLogin)
final controladorLoginProvider = ControladorLoginProvider._();

/// CU-01 Iniciar sesion: valida el formulario y delega en el repositorio.
///
/// No navega: al terminar con exito, `ControladorSesion` recibe el evento de
/// Auth y el enrutador redirige segun el rol.
final class ControladorLoginProvider
    extends $NotifierProvider<ControladorLogin, EstadoAccion> {
  /// CU-01 Iniciar sesion: valida el formulario y delega en el repositorio.
  ///
  /// No navega: al terminar con exito, `ControladorSesion` recibe el evento de
  /// Auth y el enrutador redirige segun el rol.
  ControladorLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorLoginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorLoginHash();

  @$internal
  @override
  ControladorLogin create() => ControladorLogin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorLoginHash() => r'08e791aad4811b1acde6d18648613dd8f5698164';

/// CU-01 Iniciar sesion: valida el formulario y delega en el repositorio.
///
/// No navega: al terminar con exito, `ControladorSesion` recibe el evento de
/// Auth y el enrutador redirige segun el rol.

abstract class _$ControladorLogin extends $Notifier<EstadoAccion> {
  EstadoAccion build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EstadoAccion, EstadoAccion>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EstadoAccion, EstadoAccion>,
              EstadoAccion,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
