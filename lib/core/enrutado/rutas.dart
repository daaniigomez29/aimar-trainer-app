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

  /// Biblioteca de ejercicios (CU-02 a CU-04 para el entrenador, solo lectura
  /// para el cliente). Cada rol la ve bajo su propia seccion, para que la
  /// redireccion por rol siga funcionando.
  static const String biblioteca = 'ejercicios';
  static const String bibliotecaEntrenador = '$inicioEntrenador/$biblioteca';
  static const String bibliotecaCliente = '$inicioCliente/$biblioteca';

  /// Gestion de clientes (CU-17 a CU-19). La ven el entrenador y el
  /// administrador; el cliente no tiene esta seccion.
  static const String clientes = 'clientes';
  static const String clientesEntrenador = '$inicioEntrenador/$clientes';
  static const String clientesAdministrador = '$inicioAdministrador/$clientes';

  /// Biblioteca de quien tiene la sesion abierta.
  static String bibliotecaSegunRol(RolUsuario rol) => switch (rol) {
    RolUsuario.entrenador => bibliotecaEntrenador,
    RolUsuario.cliente => bibliotecaCliente,
    // El administrador no gestiona la biblioteca: se queda en su panel.
    RolUsuario.administrador => inicioAdministrador,
  };

  static String inicioSegunRol(RolUsuario rol) => switch (rol) {
    RolUsuario.entrenador => inicioEntrenador,
    RolUsuario.cliente => inicioCliente,
    RolUsuario.administrador => inicioAdministrador,
  };

  /// Rutas accesibles sin sesion.
  static const Set<String> publicas = {login, recuperarContrasena};
}
