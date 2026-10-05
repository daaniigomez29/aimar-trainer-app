import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
// La implementacion depende de la plataforma: en web usa `dart:js_interop` para
// hablar con `PushManager`, y fuera de web no hay push que valga. El `if` del
// import es lo que evita que `dart:js_interop` entre en la compilacion de los
// tests, que corren en la VM de Dart y no en un navegador.
import 'package:aimar_trainer_app/core/plataforma/servicio_push_sin_soporte.dart'
    if (dart.library.js_interop) 'package:aimar_trainer_app/core/plataforma/servicio_push_web.dart';

part 'servicio_push.g.dart';

@Riverpod(keepAlive: true)
ServicioPush servicioPush(Ref ref) => crearServicioPush();

/// En que punto esta el permiso de notificaciones del navegador.
enum EstadoPermisoPush {
  /// El navegador no admite push (o no es un navegador).
  noSoportado,

  /// Todavia no se ha preguntado.
  sinPreguntar,

  concedido,

  /// Denegado. No se puede volver a pedir desde la app: lo tiene que cambiar el
  /// usuario en los ajustes del navegador.
  denegado;

  bool get puedeSuscribirse =>
      this == EstadoPermisoPush.sinPreguntar ||
      this == EstadoPermisoPush.concedido;
}

/// Lo que el navegador entrega al suscribirse, que es lo que hace falta para
/// cifrarle un mensaje: a donde se envia y con que claves.
class DatosSuscripcionPush {
  const DatosSuscripcionPush({
    required this.endpoint,
    required this.claveP256dh,
    required this.claveAuth,
  });

  /// La URL del servicio de push del navegador para este dispositivo. Identifica
  /// al dispositivo, no al usuario.
  final String endpoint;
  final String claveP256dh;
  final String claveAuth;
}

/// Acceso a la API de push del navegador (RNF-03: la plataforma, tras interfaz).
abstract interface class ServicioPush {
  /// `false` en un navegador sin push, o en iOS cuando la PWA no esta instalada.
  bool get estaSoportado;

  EstadoPermisoPush get permiso;

  /// Pide permiso si hace falta y suscribe este dispositivo.
  ///
  /// `null` dentro de un `Success` significa que el usuario no dio permiso, que
  /// no es un error de la app.
  Future<Result<DatosSuscripcionPush?>> suscribir(String clavePublicaVapid);

  /// La suscripcion que ya tenga este navegador, si la tiene.
  Future<Result<DatosSuscripcionPush?>> suscripcionActual();

  /// Cancela la suscripcion del navegador y devuelve el endpoint que tenia, para
  /// poder borrar tambien la fila del servidor.
  Future<Result<String?>> desuscribir();
}
