import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

/// Rutas de la aplicacion, en un unico sitio para evitar cadenas repetidas.
abstract final class Rutas {
  static const String login = '/login';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String restablecerContrasena = '/restablecer-contrasena';

  /// Pantallas principales por rol (CU-01, paso 6).
  static const String inicioEntrenador = '/entrenador';
  static const String inicioCliente = '/cliente';
  static const String inicioAdministrador = '/administrador';

  /// Ruta de arranque: solo resuelve a donde ir mientras se carga la sesion.
  static const String cargando = '/';

  static String inicioSegunRol(RolUsuario rol) => switch (rol) {
    RolUsuario.entrenador => inicioEntrenador,
    RolUsuario.cliente => inicioCliente,
    RolUsuario.administrador => inicioAdministrador,
  };

  /// Rutas accesibles sin sesion.
  static const Set<String> publicas = {login, recuperarContrasena};
}
