import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
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
    _suscripcion = repositorio.cambiosDeAutenticacion.listen(_alRecibirEvento);
    ref.onDispose(() {
      _suscripcion?.cancel();
      _suscripcion = null;
    });
    return const SesionDesconocida();
  }

  Future<void> _alRecibirEvento(EventoAutenticacion evento) async {
    switch (evento) {
      case EventoAutenticacion.sesionCerrada:
        state = const SesionCerrada();
      case EventoAutenticacion.recuperacionContrasena:
        state = const SesionRecuperandoContrasena();
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

  /// Vuelve a leer el perfil de la sesion actual y recalcula el estado.
  Future<void> refrescarPerfil() async {
    final repositorio = ref.read(autenticacionRepositorioProvider);
    if (repositorio.idUsuarioActual == null) {
      state = const SesionCerrada();
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

/// Rol del usuario con sesion activa, o `null` si no hay sesion resuelta.
@riverpod
RolUsuario? rolActual(Ref ref) {
  final estado = ref.watch(controladorSesionProvider);
  return estado is SesionActiva ? estado.perfil.rol : null;
}
