import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';

/// Estado de sesion sobre el que decide el enrutador.
sealed class EstadoSesion {
  const EstadoSesion();
}

/// Todavia no se sabe si hay sesion: se esta resolviendo la sesion persistida.
class SesionDesconocida extends EstadoSesion {
  const SesionDesconocida();
}

/// No hay sesion. `error` acompana el motivo cuando el cierre no fue voluntario
/// (por ejemplo, cuenta sin perfil o dada de baja).
class SesionCerrada extends EstadoSesion {
  const SesionCerrada();
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

/// El usuario ha llegado por el enlace de recuperacion (CU-24). Tiene sesion,
/// pero solo debe poder fijar una contrasena nueva.
class SesionRecuperandoContrasena extends EstadoSesion {
  const SesionRecuperandoContrasena();
}
