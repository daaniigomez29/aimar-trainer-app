import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';

part 'preferencias_notificacion.freezed.dart';
part 'preferencias_notificacion.g.dart';

/// Lo que el cliente decide sobre sus avisos (CU-22).
///
/// Solo el push es opcional. El correo no aparece aqui porque **no se puede
/// desactivar**: es el canal de respaldo universal (architecture.md), el unico
/// que llega siempre, tambien en un iPhone sin la PWA instalada.
@freezed
abstract class PreferenciasNotificacion with _$PreferenciasNotificacion {
  const factory PreferenciasNotificacion({
    required String clienteId,
    @Default(false) bool pushActivado,
    DateTime? actualizadoEn,
  }) = _PreferenciasNotificacion;

  factory PreferenciasNotificacion.fromJson(Map<String, dynamic> json) =>
      _$PreferenciasNotificacionFromJson(json);
}

/// Puerto de dominio de las notificaciones.
///
/// Guarda lo que el navegador entrega al suscribirse; enviarlas es cosa de la
/// Edge Function, no de la app.
abstract interface class NotificacionesRepositorio {
  /// Preferencias del cliente. Si no tiene fila todavia, devuelve las de por
  /// defecto (push desactivado) en lugar de `null`: no tener fila y tener el
  /// push apagado son lo mismo.
  Future<Result<PreferenciasNotificacion>> obtenerPreferencias(
    String clienteId,
  );

  Future<Result<PreferenciasNotificacion>> guardarPushActivado({
    required String clienteId,
    required bool activado,
  });

  /// Registra el dispositivo. Si ese endpoint ya existia, actualiza sus claves.
  Future<Result<void>> guardarSuscripcion({
    required String clienteId,
    required DatosSuscripcionPush suscripcion,
  });

  /// Olvida un dispositivo concreto.
  Future<Result<void>> eliminarSuscripcion({required String endpoint});

  /// Cuantos dispositivos tiene suscritos el cliente.
  Future<Result<int>> contarSuscripciones(String clienteId);
}
