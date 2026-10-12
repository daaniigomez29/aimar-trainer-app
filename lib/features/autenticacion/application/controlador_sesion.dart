import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/url_de_arranque.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/enlace_de_correo.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

part 'controlador_sesion.g.dart';

/// Unica fuente de verdad sobre la sesion: escucha los eventos de Auth, resuelve
/// el perfil y expone el [EstadoSesion] que usa el enrutador para decidir la
/// pantalla principal segun rol (CU-01, pasos 5 y 6).
@Riverpod(keepAlive: true)
class ControladorSesion extends _$ControladorSesion {
  StreamSubscription<EventoAutenticacion>? _suscripcion;

  @override
  EstadoSesion build() {
    final repositorio = ref.watch(autenticacionRepositorioProvider);
    _suscripcion = repositorio.cambiosDeAutenticacion.listen(
      _alRecibirEvento,
      // Un enlace de correo gastado llega como **error** del stream, no como
      // evento: el SDK lo reporta con `notifyException`. Sin este `onError` el
      // fallo se quedaba sin atender, el estado no se movia de
      // `SesionDesconocida` y el enrutador aparcaba en la pantalla de carga
      // para siempre (fallo del 2026-10-12).
      onError: _alFallarAutenticacion,
    );
    ref.onDispose(() {
      _suscripcion?.cancel();
      _suscripcion = null;
    });

    // Si la URL de arranque ya trae el motivo, se sabe sin esperar a nadie.
    final errorDelEnlace = errorDeEnlaceDeCorreo(
      ref.watch(urlDeArranqueProvider),
    );
    return errorDelEnlace == null
        ? const SesionDesconocida()
        : SesionEnlaceInvalido(errorDelEnlace);
  }

  Future<void> _alRecibirEvento(EventoAutenticacion evento) async {
    switch (evento) {
      case EventoAutenticacion.sesionCerrada:
        state = const SesionCerrada();
      case EventoAutenticacion.recuperacionContrasena:
        // Un cliente invitado rescatado con un enlace de recuperacion sigue sin
        // tener contrasena, asi que **manda la invitacion** y no el tipo de
        // enlace por el que ha entrado. Si no, la pantalla le habla de
        // "contraseña nueva" y le ofrece volver al acceso, donde no tiene nada
        // que escribir.
        state = ref.read(autenticacionRepositorioProvider).debeFijarContrasena
            ? const SesionDebeFijarContrasena()
            : const SesionRecuperandoContrasena();
      case EventoAutenticacion.sesionIniciada:
      case EventoAutenticacion.usuarioActualizado:
        await refrescarPerfil();
      case EventoAutenticacion.tokenRenovado:
        // Renovar el token no cambia el rol; solo interesa si aun no se habia
        // podido resolver el perfil.
        if (state is! SesionActiva) {
          await refrescarPerfil();
        }
    }
  }

  /// Un fallo de Auth que no viene acompanado de ningun evento: el enlace del
  /// correo ya gastado, un token que no se puede renovar, la red caida al
  /// arrancar.
  void _alFallarAutenticacion(Object error, StackTrace traza) {
    Registro.fallo(error, traza, contexto: 'el flujo de autenticación');

    // Con sesion viva no se saca a nadie de donde esta: un refresco que falla
    // sin cobertura lo cuenta la pantalla que no pueda cargar, no esta.
    if (state is SesionActiva) return;
    state = SesionEnlaceInvalido(
      // El repositorio ya los traduce; el `else` es por si algun dia llega algo
      // sin traducir, para no acabar otra vez en un estado sin salida.
      error is ErrorApp ? error : const ErrorInesperado(),
    );
  }

  /// Vuelve a leer el perfil de la sesion actual y recalcula el estado.
  Future<void> refrescarPerfil() async {
    final repositorio = ref.read(autenticacionRepositorioProvider);
    if (repositorio.idUsuarioActual == null) {
      // No se pisa el motivo si ya se conoce: cuando el enlace falla, el SDK
      // emite ademas `initialSession` sin sesion, y un `SesionCerrada` encima
      // mandaria al login en lugar de a "pide otro enlace".
      if (state is! SesionEnlaceInvalido) state = const SesionCerrada();
      return;
    }
    // Antes de resolver el perfil: un cliente recien invitado no tiene contrasena,
    // y dejarle entrar le cerraria la puerta para siempre (ver CU-17).
    if (repositorio.debeFijarContrasena) {
      state = const SesionDebeFijarContrasena();
      return;
    }

    final resultado = await repositorio.perfilDeLaSesion();
    state = switch (resultado) {
      Success(:final valor) => SesionActiva(valor),
      // Sin perfil no hay rol ni pantalla a la que ir: el repositorio ya ha
      // cerrado la sesion en ese caso.
      Failure() => const SesionCerrada(),
    };
  }

  Future<void> cerrarSesion() async {
    await ref.read(autenticacionRepositorioProvider).cerrarSesion();
    state = const SesionCerrada();
  }
}

/// Id de la cuenta con sesion activa, o `null` si no hay sesion resuelta.
///
/// Es el mismo uuid que `auth.users.id` y, para un cliente, que `clientes.id`:
/// una pantalla del cliente puede usarlo para pedir lo suyo sin recibir el id
/// por parametro.
@riverpod
String? idUsuarioActual(Ref ref) {
  final estado = ref.watch(controladorSesionProvider);
  return estado is SesionActiva ? estado.perfil.id : null;
}

/// Rol del usuario con sesion activa, o `null` si no hay sesion resuelta.
@riverpod
RolUsuario? rolActual(Ref ref) {
  final estado = ref.watch(controladorSesionProvider);
  return estado is SesionActiva ? estado.perfil.rol : null;
}
