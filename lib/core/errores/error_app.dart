/// Errores de dominio de la aplicacion.
///
/// Toda excepcion de Supabase se traduce a uno de estos en la capa `data/`:
/// ninguna excepcion de la libreria debe llegar a `presentation/`.
sealed class ErrorApp {
  const ErrorApp(this.mensaje);

  /// Mensaje ya redactado para mostrar al usuario final, en espanol.
  final String mensaje;

  @override
  String toString() => '$runtimeType($mensaje)';
}

/// Credenciales incorrectas en el inicio de sesion (CU-01).
class ErrorCredencialesInvalidas extends ErrorApp {
  const ErrorCredencialesInvalidas()
    : super('Correo o contrasena incorrectos.');
}

/// Cuenta dada de baja o bloqueada en Auth (CU-01, excepcion).
class ErrorCuentaNoDisponible extends ErrorApp {
  const ErrorCuentaNoDisponible()
    : super('Esta cuenta no esta disponible. Contacta con tu entrenador.');
}

/// La invitacion por correo sigue pendiente de aceptar: el usuario existe en
/// Auth pero todavia no ha confirmado el correo ni fijado su contrasena.
class ErrorCuentaSinActivar extends ErrorApp {
  const ErrorCuentaSinActivar()
    : super(
        'Tu cuenta esta pendiente de activar. Revisa el correo de invitacion.',
      );
}

/// El usuario esta autenticado pero no tiene fila en `perfiles`, asi que no se
/// le puede asignar un rol ni una pantalla principal.
class ErrorPerfilSinRol extends ErrorApp {
  const ErrorPerfilSinRol()
    : super('Tu cuenta no tiene un rol asignado. Contacta con tu entrenador.');
}

/// RLS o la Edge Function han rechazado la operacion por rol insuficiente.
class ErrorNoAutorizado extends ErrorApp {
  const ErrorNoAutorizado()
    : super('No tienes permisos para realizar esta accion.');
}

class ErrorNoEncontrado extends ErrorApp {
  const ErrorNoEncontrado([
    super.mensaje = 'No se ha encontrado el recurso solicitado.',
  ]);
}

/// Datos que no cumplen una regla de dominio (validacion local o constraint).
class ErrorValidacion extends ErrorApp {
  const ErrorValidacion(super.mensaje, {this.campo});

  /// Campo del formulario al que atribuir el error, si aplica.
  final String? campo;
}

/// Ya existe un ejercicio activo con ese nombre (CU-02/CU-03, excepcion), o un
/// cliente activo con ese correo (CU-17). Lo garantiza un indice unico parcial.
class ErrorNombreDuplicado extends ErrorApp {
  const ErrorNombreDuplicado([
    super.mensaje = 'Ya existe un registro activo con ese nombre.',
  ]);
}

/// Una Edge Function no responde: no esta desplegada, o en local falta
/// `supabase functions serve`. Se distingue de [ErrorConexion] porque la red va
/// bien; lo que no esta es ese servicio concreto.
class ErrorServicioNoDisponible extends ErrorApp {
  const ErrorServicioNoDisponible([String? servicio])
    : super(
        servicio == null
            ? 'El servicio no esta disponible ahora mismo. Vuelve a intentarlo.'
            : 'El servicio de $servicio no esta disponible ahora mismo. '
                  'Vuelve a intentarlo.',
      );
}

/// Fallo de red o servicio no alcanzable.
class ErrorConexion extends ErrorApp {
  const ErrorConexion()
    : super('No se ha podido conectar con el servidor. Revisa tu conexion.');
}

/// Cualquier otro fallo inesperado. Conserva la causa para diagnostico, pero
/// muestra un mensaje generico.
class ErrorInesperado extends ErrorApp {
  const ErrorInesperado({this.causa, this.traza})
    : super('Ha ocurrido un error inesperado. Vuelve a intentarlo.');

  final Object? causa;
  final StackTrace? traza;

  @override
  String toString() => 'ErrorInesperado($mensaje, causa: $causa)';
}

/// El enlace de restablecimiento de contrasena ha caducado o ya se uso
/// (CU-24, excepcion).
class ErrorEnlaceCaducado extends ErrorApp {
  const ErrorEnlaceCaducado()
    : super('El enlace ha caducado o ya se ha utilizado. Solicita uno nuevo.');
}

/// Supabase ha limitado la frecuencia de peticiones (envio de correos, intentos
/// de acceso).
class ErrorDemasiadasPeticiones extends ErrorApp {
  const ErrorDemasiadasPeticiones()
    : super('Demasiados intentos. Espera unos minutos y vuelve a probar.');
}
