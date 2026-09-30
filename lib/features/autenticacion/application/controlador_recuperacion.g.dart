// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_recuperacion.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CU-24, primera mitad: solicitar el enlace de restablecimiento por correo.
///
/// Termina en `completada` incluso si el correo no esta registrado: el mensaje
/// que se muestra es generico para no revelar que cuentas existen.

@ProviderFor(ControladorSolicitudRecuperacion)
final controladorSolicitudRecuperacionProvider =
    ControladorSolicitudRecuperacionProvider._();

/// CU-24, primera mitad: solicitar el enlace de restablecimiento por correo.
///
/// Termina en `completada` incluso si el correo no esta registrado: el mensaje
/// que se muestra es generico para no revelar que cuentas existen.
final class ControladorSolicitudRecuperacionProvider
    extends $NotifierProvider<ControladorSolicitudRecuperacion, EstadoAccion> {
  /// CU-24, primera mitad: solicitar el enlace de restablecimiento por correo.
  ///
  /// Termina en `completada` incluso si el correo no esta registrado: el mensaje
  /// que se muestra es generico para no revelar que cuentas existen.
  ControladorSolicitudRecuperacionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorSolicitudRecuperacionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorSolicitudRecuperacionHash();

  @$internal
  @override
  ControladorSolicitudRecuperacion create() =>
      ControladorSolicitudRecuperacion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorSolicitudRecuperacionHash() =>
    r'c4dd5148073ae18411c657330769f583d94ee0de';

/// CU-24, primera mitad: solicitar el enlace de restablecimiento por correo.
///
/// Termina en `completada` incluso si el correo no esta registrado: el mensaje
/// que se muestra es generico para no revelar que cuentas existen.

abstract class _$ControladorSolicitudRecuperacion
    extends $Notifier<EstadoAccion> {
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

/// CU-24, segunda mitad: fijar la contrasena nueva sobre la sesion de
/// recuperacion que abre el enlace del correo.

@ProviderFor(ControladorRestablecerContrasena)
final controladorRestablecerContrasenaProvider =
    ControladorRestablecerContrasenaProvider._();

/// CU-24, segunda mitad: fijar la contrasena nueva sobre la sesion de
/// recuperacion que abre el enlace del correo.
final class ControladorRestablecerContrasenaProvider
    extends $NotifierProvider<ControladorRestablecerContrasena, EstadoAccion> {
  /// CU-24, segunda mitad: fijar la contrasena nueva sobre la sesion de
  /// recuperacion que abre el enlace del correo.
  ControladorRestablecerContrasenaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorRestablecerContrasenaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorRestablecerContrasenaHash();

  @$internal
  @override
  ControladorRestablecerContrasena create() =>
      ControladorRestablecerContrasena();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorRestablecerContrasenaHash() =>
    r'6deedd16c33d1133bf986e919f1d1682b053a4b2';

/// CU-24, segunda mitad: fijar la contrasena nueva sobre la sesion de
/// recuperacion que abre el enlace del correo.

abstract class _$ControladorRestablecerContrasena
    extends $Notifier<EstadoAccion> {
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
