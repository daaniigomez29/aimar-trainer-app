import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/notificaciones/data/notificaciones_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/notificaciones/domain/preferencias_notificacion.dart';

part 'controlador_notificaciones.g.dart';

/// Preferencias del cliente, con las de por defecto si todavia no tiene fila.
@riverpod
Future<PreferenciasNotificacion> preferenciasDeCliente(
  Ref ref,
  String clienteId,
) async {
  final resultado = await ref
      .watch(notificacionesRepositorioProvider)
      .obtenerPreferencias(clienteId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Dispositivos suscritos del cliente. Sirve para avisar de que el push esta
/// activado pero este navegador concreto no esta suscrito.
@riverpod
Future<int> dispositivosSuscritos(Ref ref, String clienteId) async {
  final resultado = await ref
      .watch(notificacionesRepositorioProvider)
      .contarSuscripciones(clienteId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Estado del permiso de notificaciones en este navegador.
///
/// Va en su propio provider y no en el controlador porque `riverpod_lint`
/// prohibe las propiedades publicas en un notifier: todo lo que expone debe
/// pasar por `state`, y esto no es estado de la operacion, es del navegador.
@riverpod
EstadoPermisoPush permisoPush(Ref ref) =>
    ref.watch(servicioPushProvider).permiso;

@riverpod
bool pushSoportado(Ref ref) => ref.watch(servicioPushProvider).estaSoportado;

/// Activar y desactivar el push del cliente (CU-22).
///
/// Activar son tres pasos que tienen que ir juntos: pedir permiso al navegador,
/// guardar la suscripcion y marcar la preferencia. Si el usuario no da permiso,
/// no se marca nada: quedaria el push "activado" sin dispositivo al que enviar, y
/// la Edge Function lo anotaria como fallido todos los dias.
@riverpod
class ControladorNotificaciones extends _$ControladorNotificaciones {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  Future<Result<bool>> activar(String clienteId) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operación en curso.'));
    }

    final servicio = ref.read(servicioPushProvider);
    if (!servicio.estaSoportado) {
      return _fallar(
        const ErrorValidacion(
          'Este navegador no admite notificaciones. En iPhone hay que instalar '
          'la app en la pantalla de inicio primero.',
        ),
      );
    }
    if (servicio.permiso == EstadoPermisoPush.denegado) {
      return _fallar(
        const ErrorValidacion(
          'Has bloqueado las notificaciones en el navegador. Tienes que '
          'permitirlas en sus ajustes para este sitio.',
        ),
      );
    }

    final clave = ref.read(configuracionAppProvider).clavePublicaVapid;
    state = const EstadoAccion.enCurso();

    final suscripcion = await servicio.suscribir(clave);
    switch (suscripcion) {
      case Failure(:final error):
        return _fallar(error);
      case Success(:final valor):
        // Sin permiso no hay suscripcion, y sin suscripcion no se activa nada.
        if (valor == null) {
          return _fallar(
            const ErrorValidacion(
              'No se han activado: el navegador no ha dado permiso.',
            ),
          );
        }

        final repositorio = ref.read(notificacionesRepositorioProvider);
        final guardada = await repositorio.guardarSuscripcion(
          clienteId: clienteId,
          suscripcion: valor,
        );
        if (guardada case Failure(:final error)) return _fallar(error);

        final preferencia = await repositorio.guardarPushActivado(
          clienteId: clienteId,
          activado: true,
        );
        return _terminar(preferencia.map((_) => true), clienteId);
    }
  }

  Future<Result<bool>> desactivar(String clienteId) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operación en curso.'));
    }
    state = const EstadoAccion.enCurso();

    final repositorio = ref.read(notificacionesRepositorioProvider);

    // Primero la preferencia: es lo que mira la Edge Function. Si la baja del
    // navegador fallara despues, el cliente ya no recibiria avisos igualmente.
    final preferencia = await repositorio.guardarPushActivado(
      clienteId: clienteId,
      activado: false,
    );
    if (preferencia case Failure(:final error)) return _fallar(error);

    final endpoint = await ref.read(servicioPushProvider).desuscribir();
    if (endpoint case Success(:final valor?)) {
      await repositorio.eliminarSuscripcion(endpoint: valor);
    }

    return _terminar(const Success(false), clienteId);
  }

  Future<Result<bool>> _terminar(
    Result<bool> resultado,
    String clienteId,
  ) async {
    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) {
        ref
          ..invalidate(preferenciasDeClienteProvider(clienteId))
          ..invalidate(dispositivosSuscritosProvider(clienteId));
      }
    }
    return resultado;
  }

  Future<Result<bool>> _fallar(ErrorApp error) async {
    if (ref.mounted) state = EstadoAccion.conError(error);
    return Failure(error);
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }
}
