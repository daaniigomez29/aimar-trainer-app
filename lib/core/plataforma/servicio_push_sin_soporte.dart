import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';

/// Implementacion para cuando no hay navegador detras: los tests, que corren en
/// la VM de Dart, y la futura app movil, que usara otra cosa.
///
/// No lanza ni finge: dice que no esta soportado, y la pantalla de preferencias
/// ya sabe explicar ese caso.
ServicioPush crearServicioPush() => const ServicioPushSinSoporte();

class ServicioPushSinSoporte implements ServicioPush {
  const ServicioPushSinSoporte();

  @override
  bool get estaSoportado => false;

  @override
  EstadoPermisoPush get permiso => EstadoPermisoPush.noSoportado;

  @override
  Future<Result<DatosSuscripcionPush?>> suscribir(
    String clavePublicaVapid,
  ) async => const Success(null);

  @override
  Future<Result<DatosSuscripcionPush?>> suscripcionActual() async =>
      const Success(null);

  @override
  Future<Result<String?>> desuscribir() async => const Success(null);
}
