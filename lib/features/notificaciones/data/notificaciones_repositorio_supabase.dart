import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/notificaciones/domain/preferencias_notificacion.dart';

part 'notificaciones_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
NotificacionesRepositorio notificacionesRepositorio(Ref ref) =>
    NotificacionesRepositorioSupabase(
      cliente: ref.watch(clienteSupabaseProvider),
    );

/// Implementacion de [NotificacionesRepositorio].
///
/// Todo pasa por RLS con el token del cliente: las dos tablas solo dejan a cada
/// uno con lo suyo. La Edge Function lee estas mismas tablas con `service_role`
/// para decidir a quien avisar.
class NotificacionesRepositorioSupabase implements NotificacionesRepositorio {
  NotificacionesRepositorioSupabase({required this.cliente});

  static const String _preferencias = 'preferencias_notificacion';
  static const String _suscripciones = 'suscripciones_push';

  final SupabaseClient cliente;

  @override
  Future<Result<PreferenciasNotificacion>> obtenerPreferencias(
    String clienteId,
  ) async {
    try {
      final fila = await cliente
          .from(_preferencias)
          .select()
          .eq('cliente_id', clienteId)
          .maybeSingle();
      // Sin fila, las preferencias por defecto: push apagado.
      return Success(
        fila == null
            ? PreferenciasNotificacion(clienteId: clienteId)
            : PreferenciasNotificacion.fromJson(fila),
      );
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<PreferenciasNotificacion>> guardarPushActivado({
    required String clienteId,
    required bool activado,
  }) async {
    try {
      final fila = await cliente
          .from(_preferencias)
          .upsert({
            'cliente_id': clienteId,
            'push_activado': activado,
            'actualizado_en': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'cliente_id')
          .select()
          .single();
      return Success(PreferenciasNotificacion.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<void>> guardarSuscripcion({
    required String clienteId,
    required DatosSuscripcionPush suscripcion,
  }) async {
    try {
      // `onConflict` sobre el endpoint: el navegador puede renovar las claves de
      // una suscripcion que ya existe, y entonces hay que actualizarla, no
      // duplicarla.
      await cliente.from(_suscripciones).upsert({
        'cliente_id': clienteId,
        'endpoint': suscripcion.endpoint,
        'clave_p256dh': suscripcion.claveP256dh,
        'clave_auth': suscripcion.claveAuth,
      }, onConflict: 'endpoint');
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<void>> eliminarSuscripcion({required String endpoint}) async {
    try {
      await cliente.from(_suscripciones).delete().eq('endpoint', endpoint);
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<int>> contarSuscripciones(String clienteId) async {
    try {
      final filas = await cliente
          .from(_suscripciones)
          .select('id')
          .eq('cliente_id', clienteId);
      return Success(filas.length);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  ErrorApp _traducir(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;
    if (error is PostgrestException) {
      return switch (error.code) {
        '42501' => const ErrorNoAutorizado(),
        '23505' => const ErrorValidacion(
          'Ese dispositivo ya estaba registrado.',
        ),
        '23503' => const ErrorValidacion('La ficha del cliente ya no existe.'),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el repositorio de notificaciones',
        ),
      };
    }
    if (error is TimeoutException) return const ErrorConexion();
    final nombre = error.runtimeType.toString();
    if (nombre == 'ClientException' || nombre == 'SocketException') {
      return const ErrorConexion();
    }
    return Registro.inesperado(
      error,
      traza,
      contexto: 'el repositorio de notificaciones',
    );
  }
}
