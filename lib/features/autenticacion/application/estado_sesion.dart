import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';

/// Estado de sesion sobre el que decide el enrutador.
sealed class EstadoSesion {
  const EstadoSesion();
}

/// Todavia no se sabe si hay sesion: se esta resolviendo la sesion persistida.
class SesionDesconocida extends EstadoSesion {
  const SesionDesconocida();
}

/// No hay sesion y no hay nada que explicar: o nunca la hubo, o se cerro.
///
/// Cuando si hay un motivo que contar —se ha llegado por un enlace de correo
/// que ya no vale— el estado es [SesionEnlaceInvalido], que lo lleva dentro.
class SesionCerrada extends EstadoSesion {
  const SesionCerrada();
}

/// Se ha llegado por un enlace de correo de Auth que ya no sirve: gastado
/// (son de un solo uso) o caducado.
///
/// Es distinto de [SesionCerrada] por lo que hay que hacer a continuacion: aqui
/// no se manda al login —un cliente invitado no tiene contrasena que escribir
/// alli— sino a pedir otro enlace, contando [error].
class SesionEnlaceInvalido extends EstadoSesion {
  const SesionEnlaceInvalido(this.error);

  final ErrorApp error;

  @override
  bool operator ==(Object other) =>
      other is SesionEnlaceInvalido && other.error == error;

  @override
  int get hashCode => Object.hash(SesionEnlaceInvalido, error);
}

/// Sesion valida con rol conocido.
class SesionActiva extends EstadoSesion {
  const SesionActiva(this.perfil);

  final Perfil perfil;

  @override
  bool operator ==(Object other) =>
      other is SesionActiva && other.perfil == perfil;

  @override
  int get hashCode => Object.hash(SesionActiva, perfil);
}

/// El usuario entro por una invitacion (CU-17) y todavia no tiene contrasena.
///
/// Hace falta un estado propio porque GoTrue emite `signedIn` para un enlace de
/// invitacion, igual que para un login normal: sin distinguirlo, el cliente
/// entraria en la app sin contrasena y despues no podria volver a entrar.
class SesionDebeFijarContrasena extends EstadoSesion {
  const SesionDebeFijarContrasena();
}

/// El usuario ha llegado por el enlace de recuperacion (CU-24). Tiene sesion,
/// pero solo debe poder fijar una contrasena nueva.
class SesionRecuperandoContrasena extends EstadoSesion {
  const SesionRecuperandoContrasena();
}
