import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';

/// Observa los providers para dejar en la consola de depuracion lo que ocurre
/// dentro de ellos.
///
/// Es el complemento necesario del `Result<T>`: un `Failure` no lanza ninguna
/// excepcion, asi que sin esto un error que la interfaz muestra como un mensaje
/// amable no deja ningun rastro en la consola.
final class ObservadorProviders extends ProviderObserver {
  const ObservadorProviders();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    Registro.fallo(
      error,
      stackTrace,
      contexto: 'el provider ${_nombre(context)}',
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    // Solo se registran los cambios que indican un problema; registrar todos los
    // estados haria la consola ilegible.
    switch (newValue) {
      case EstadoAccion(error: final error?):
        Registro.info(
          '${_nombre(context)} → error: ${error.runtimeType}: ${error.mensaje}',
        );
      case Failure(:final error):
        Registro.info(
          '${_nombre(context)} → Failure: ${error.runtimeType}: ${error.mensaje}',
        );
      case AsyncError(:final error, :final stackTrace):
        Registro.fallo(
          error,
          stackTrace,
          contexto: 'el provider ${_nombre(context)}',
        );
      default:
        break;
    }
  }

  static String _nombre(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();
}
