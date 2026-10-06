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

  /// Planning del cliente con la sesion abierta (CU-23 desde su lado). Solo
  /// lectura: planificar es del entrenador, que llega a los plannings desde la
  /// ficha del cliente, no por ruta propia.
  static const String planning = 'planning';
  static const String planningCliente = '$inicioCliente/$planning';

  /// Progreso del cliente (CU-21) y control semanal de medidas y check-in. El
  /// entrenador los consulta desde la ficha de cada cliente, no por ruta propia.
  static const String progreso = 'progreso';
  static const String progresoCliente = '$inicioCliente/$progreso';
  static const String control = 'control';
  static const String controlCliente = '$inicioCliente/$control';

  /// Preferencias de aviso del cliente (CU-22).
  static const String avisos = 'avisos';
  static const String avisosCliente = '$inicioCliente/$avisos';

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

  /// Pantallas que cuelgan de la biblioteca y de clientes.
  ///
  /// POR QUE SON RUTAS Y NO `Navigator.push`: en web, un `push` imperativo no
  /// deja rastro en el historial del navegador, así que su botón de atrás
  /// retrocedía a la última ruta visitada (la planificación o los ajustes) en
  /// vez de a la pantalla anterior. Con rutas, el atrás del navegador y el gesto
  /// atrás del móvil funcionan, y la URL dice dónde estás.
  static const String nuevo = 'nuevo';
  static const String editar = 'editar';

  /// `:idEjercicio` y `:idCliente` son los parámetros que leen las pantallas.
  static const String detalleEjercicio = ':idEjercicio';
  static const String detalleCliente = ':idCliente';

  static String ejercicioDeLaBiblioteca(RolUsuario rol, String id) =>
      '${bibliotecaSegunRol(rol)}/$id';
  static String nuevoEjercicio() => '$bibliotecaEntrenador/$nuevo';
  static String editarEjercicio(String id) =>
      '$bibliotecaEntrenador/$id/$editar';

  static String fichaDeCliente(String id) => '$clientesEntrenador/$id';
  static String nuevoCliente() => '$clientesEntrenador/$nuevo';
  static String editarCliente(String id) => '$clientesEntrenador/$id/$editar';

  /// Lo que se consulta desde la ficha de un cliente.
  static const String plannings = 'plannings';
  static const String controlDelCliente = 'control';
  static String planningsDeCliente(String id) =>
      '$clientesEntrenador/$id/$plannings';
  static String progresoDeCliente(String id) =>
      '$clientesEntrenador/$id/$progreso';
  static String controlDeCliente(String id) =>
      '$clientesEntrenador/$id/$controlDelCliente';

  /// Un planning concreto. El cliente llega desde su historico; el entrenador,
  /// desde la ficha del cliente, por eso cuelgan de sitios distintos.
  static const String unPlanning = ':planningId';
  static String planningDelCliente(String planningId) =>
      '$planningCliente/$planningId';
  static String planningDeClienteConcreto(
    String idCliente,
    String planningId,
  ) => '${planningsDeCliente(idCliente)}/$planningId';

  /// Registro del resultado de una sesión (CU-20) y de un ejercicio suelto.
  static const String sesiones = 'sesiones';
  static const String unaSesion = ':idSesion';
  static const String ejerciciosDeSesion = 'ejercicios';
  static const String unEjercicioPlanificado = ':idEjercicioPlanificado';

  static String registroDeSesion(String planningId, String idSesion) =>
      '${planningDelCliente(planningId)}/$sesiones/$idSesion';
  static String registroDeEjercicio(
    String planningId,
    String idSesion,
    String idEjercicioPlanificado,
  ) =>
      '${registroDeSesion(planningId, idSesion)}/$ejerciciosDeSesion/'
      '$idEjercicioPlanificado';

  /// Formulario de un ejercicio dentro de un bloque (CU-08 y CU-12). Cuelga del
  /// planning porque el bloque solo existe dentro de él.
  static const String bloques = 'bloques';
  static const String unBloque = ':idBloque';
  static const String ejercicioDelBloque = 'ejercicio';
  static String nuevoEjercicioEnBloque(
    String rutaDelPlanning,
    String idBloque,
  ) => '$rutaDelPlanning/$bloques/$idBloque/$ejercicioDelBloque';
  static String editarEjercicioDelBloque(
    String rutaDelPlanning,
    String idBloque,
    String idEjercicioPlanificado,
  ) =>
      '${nuevoEjercicioEnBloque(rutaDelPlanning, idBloque)}/'
      '$idEjercicioPlanificado';

  /// El planning que el entrenador edita en su pantalla de entrada: no se llega
  /// a él por una lista, pero el formulario de un ejercicio sí necesita ruta.
  static String planningEnEdicion(String planningId) =>
      '$inicioEntrenador/$plannings/$planningId';

  /// Ajustes del entrenador: cuarto destino de su navegacion.
  static const String ajustes = 'ajustes';
  static const String ajustesEntrenador = '$inicioEntrenador/$ajustes';

  /// Rutas accesibles sin sesion.
  static const Set<String> publicas = {login, recuperarContrasena};
}
