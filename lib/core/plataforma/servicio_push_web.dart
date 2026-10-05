import 'dart:convert';
import 'dart:js_interop';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';

ServicioPush crearServicioPush() => const ServicioPushWeb();

// Puente con el objeto `window.aimarPush` que define `web/index.html`. Se habla
// con el en texto plano y JSON en cadena a proposito: cuanto menos tipado cruce
// la frontera entre Dart y JavaScript, menos sitios donde equivocarse.
@JS('aimarPush.soportado')
external bool _soportado();

@JS('aimarPush.permiso')
external String _permiso();

@JS('aimarPush.suscribir')
external JSPromise<JSString?> _suscribir(String clavePublica);

@JS('aimarPush.suscripcionActual')
external JSPromise<JSString?> _suscripcionActual();

@JS('aimarPush.desuscribir')
external JSPromise<JSString?> _desuscribir();

/// Implementacion sobre la API de push del navegador.
class ServicioPushWeb implements ServicioPush {
  const ServicioPushWeb();

  @override
  bool get estaSoportado {
    try {
      return _soportado();
    } on Object {
      // Si el puente no esta (un index.html antiguo en cache, por ejemplo), se
      // comporta como un navegador sin push en lugar de reventar.
      return false;
    }
  }

  @override
  EstadoPermisoPush get permiso {
    try {
      return switch (_permiso()) {
        'granted' => EstadoPermisoPush.concedido,
        'denied' => EstadoPermisoPush.denegado,
        'default' => EstadoPermisoPush.sinPreguntar,
        _ => EstadoPermisoPush.noSoportado,
      };
    } on Object {
      return EstadoPermisoPush.noSoportado;
    }
  }

  @override
  Future<Result<DatosSuscripcionPush?>> suscribir(
    String clavePublicaVapid,
  ) async {
    if (clavePublicaVapid.isEmpty) {
      return const Failure(
        ErrorValidacion(
          'Esta instalacion no tiene configurada la clave de notificaciones.',
        ),
      );
    }
    return _pedirSuscripcion(
      () => _suscribir(clavePublicaVapid),
      contexto: 'la suscripcion al push',
    );
  }

  @override
  Future<Result<DatosSuscripcionPush?>> suscripcionActual() =>
      // La lambda no sobra: Dart no deja hacer un tear-off de un miembro externo
      // de JavaScript, y el build web (no `dart analyze`) es quien lo detecta.
      _pedirSuscripcion(
        () => _suscripcionActual(),
        contexto: 'la suscripcion actual',
      );

  @override
  Future<Result<String?>> desuscribir() async {
    try {
      final endpoint = (await _desuscribir().toDart)?.toDart;
      return Success(endpoint);
    } on Object catch (error, traza) {
      return Failure(
        Registro.inesperado(error, traza, contexto: 'la baja del push'),
      );
    }
  }

  Future<Result<DatosSuscripcionPush?>> _pedirSuscripcion(
    JSPromise<JSString?> Function() operacion, {
    required String contexto,
  }) async {
    try {
      final json = (await operacion().toDart)?.toDart;
      // `null` es el caso normal de "el usuario no ha dado permiso", no un fallo.
      if (json == null) return const Success(null);
      return Success(_interpretar(json));
    } on Object catch (error, traza) {
      return Failure(Registro.inesperado(error, traza, contexto: contexto));
    }
  }

  /// `PushSubscription.toJSON()` da `{endpoint, keys: {p256dh, auth}}`.
  static DatosSuscripcionPush? _interpretar(String json) {
    final mapa = jsonDecode(json) as Map<String, dynamic>;
    final claves = mapa['keys'] as Map<String, dynamic>?;
    final endpoint = mapa['endpoint'] as String?;
    final p256dh = claves?['p256dh'] as String?;
    final auth = claves?['auth'] as String?;
    if (endpoint == null || p256dh == null || auth == null) return null;

    return DatosSuscripcionPush(
      endpoint: endpoint,
      claveP256dh: p256dh,
      claveAuth: auth,
    );
  }
}
