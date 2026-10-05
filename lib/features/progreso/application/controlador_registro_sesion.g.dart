// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_registro_sesion.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Registro del resultado de una sesion (CU-20).
///
/// Cada metodo devuelve su `Result` ademas de dejarlo en el estado, por la leccion
/// de CU-04: con dialogos de por medio un provider autoDispose puede desecharse
/// antes de que llegue la respuesta.
///
/// Tras guardar se invalida `planningCompletoProvider`, porque los triggers habran
/// cambiado `estado_registro` del ejercicio y puede que `resultado_registrado` de
/// la sesion: lo que la pantalla tiene en memoria se queda viejo.

@ProviderFor(ControladorRegistroSesion)
final controladorRegistroSesionProvider = ControladorRegistroSesionProvider._();

/// Registro del resultado de una sesion (CU-20).
///
/// Cada metodo devuelve su `Result` ademas de dejarlo en el estado, por la leccion
/// de CU-04: con dialogos de por medio un provider autoDispose puede desecharse
/// antes de que llegue la respuesta.
///
/// Tras guardar se invalida `planningCompletoProvider`, porque los triggers habran
/// cambiado `estado_registro` del ejercicio y puede que `resultado_registrado` de
/// la sesion: lo que la pantalla tiene en memoria se queda viejo.
final class ControladorRegistroSesionProvider
    extends $NotifierProvider<ControladorRegistroSesion, EstadoAccion> {
  /// Registro del resultado de una sesion (CU-20).
  ///
  /// Cada metodo devuelve su `Result` ademas de dejarlo en el estado, por la leccion
  /// de CU-04: con dialogos de por medio un provider autoDispose puede desecharse
  /// antes de que llegue la respuesta.
  ///
  /// Tras guardar se invalida `planningCompletoProvider`, porque los triggers habran
  /// cambiado `estado_registro` del ejercicio y puede que `resultado_registrado` de
  /// la sesion: lo que la pantalla tiene en memoria se queda viejo.
  ControladorRegistroSesionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorRegistroSesionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorRegistroSesionHash();

  @$internal
  @override
  ControladorRegistroSesion create() => ControladorRegistroSesion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorRegistroSesionHash() =>
    r'a3bc5e7b186e969c9e84ba7b8702bdefe1184a05';

/// Registro del resultado de una sesion (CU-20).
///
/// Cada metodo devuelve su `Result` ademas de dejarlo en el estado, por la leccion
/// de CU-04: con dialogos de por medio un provider autoDispose puede desecharse
/// antes de que llegue la respuesta.
///
/// Tras guardar se invalida `planningCompletoProvider`, porque los triggers habran
/// cambiado `estado_registro` del ejercicio y puede que `resultado_registrado` de
/// la sesion: lo que la pantalla tiene en memoria se queda viejo.

abstract class _$ControladorRegistroSesion extends $Notifier<EstadoAccion> {
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
