import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';

/// Resultado del alta de un cliente (CU-17).
///
/// La invitacion puede no haberse enviado (Resend sin configurar, o caido) sin que
/// eso invalide el alta: la ficha ya existe y la invitacion se puede reenviar. La
/// interfaz avisa de ello en lugar de dar el alta por fallida.
class ResultadoAlta {
  const ResultadoAlta({
    required this.clienteId,
    required this.invitacionEnviada,
    this.avisoInvitacion,
  });

  final String clienteId;
  final bool invitacionEnviada;
  final String? avisoInvitacion;
}

/// Puerto de dominio de la gestion de clientes (CU-17, CU-18, CU-19).
///
/// El alta y la baja NO son operaciones de tabla: pasan por Edge Functions, porque
/// crear o bloquear una cuenta de Auth exige `service_role`, que nunca puede estar
/// en el codigo Flutter. La edicion si es un `update` directo sujeto a RLS.
abstract interface class ClienteRepositorio {
  /// Fichas visibles para quien consulta. Con RLS, el entrenador ve todas y el
  /// cliente solo la suya; el administrador no ve ninguna.
  Future<Result<List<Cliente>>> listar();

  Future<Result<Cliente>> obtenerPorId(String id);

  /// CU-17: alta via Edge Function `crear-cliente`.
  ///
  /// Falla con `ErrorNombreDuplicado` si ya hay un cliente activo con ese correo.
  Future<Result<ResultadoAlta>> darDeAlta(DatosCliente datos);

  /// CU-19: edicion de la ficha. El correo no se cambia (ver `aJsonDeEdicion`).
  Future<Result<Cliente>> editar({
    required String id,
    required DatosCliente datos,
  });

  /// CU-18: baja logica via Edge Function `dar-de-baja-cliente`, que ademas
  /// bloquea el acceso en Auth.
  Future<Result<Cliente>> darDeBaja(String id);

  /// Cuantos plannings activos tiene el cliente, para el aviso de CU-18.
  ///
  /// Devuelve 0 mientras no existan las tablas de planificacion (fase 4).
  Future<Result<int>> contarPlanningsActivos(String id);
}
