import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Puerto de dominio de la planificacion semanal (CU-05 a CU-16, y CU-23).
///
/// A diferencia de clientes y ejercicios, aqui el borrado SI es fisico: eliminar
/// un planning, una sesion, un bloque o un ejercicio planificado es un caso de uso
/// real, y la cascada de las FK se encarga de los hijos. La baja logica se reserva
/// a lo que tiene historico que conservar (clientes y biblioteca).
abstract interface class PlanningRepositorio {
  /// Plannings de un cliente, activos y archivados, mas recientes primero
  /// (CU-23). Sin sus hijos: para eso esta [obtenerPlanningCompleto].
  Future<Result<List<PlanningSemanal>>> listarDeCliente(String clienteId);

  /// El planning con toda su jerarquia: sesiones, bloques, ejercicios
  /// planificados (con su ejercicio de la biblioteca) y series planificadas.
  ///
  /// Se trae de una sola consulta: una semana cabe de sobra en memoria y asi la
  /// pantalla puede validar ordenes y fechas duplicadas sin ir al servidor.
  Future<Result<PlanningSemanal>> obtenerPlanningCompleto(String planningId);

  // --- Planning (CU-05, CU-09, CU-13) ---

  Future<Result<PlanningSemanal>> crearPlanning(DatosPlanning datos);

  Future<Result<PlanningSemanal>> editarPlanning({
    required String id,
    required DatosPlanning datos,
  });

  /// Archiva el planning. Deja de admitir cambios pero se conserva para consulta.
  Future<Result<PlanningSemanal>> archivarPlanning(String id);

  Future<Result<PlanningSemanal>> reactivarPlanning(String id);

  /// Borrado fisico. Arrastra sesiones, bloques, ejercicios planificados y series.
  Future<Result<void>> eliminarPlanning(String id);

  // --- Sesion (CU-06, CU-10, CU-14) ---

  Future<Result<SesionEntrenamiento>> crearSesion(DatosSesion datos);

  Future<Result<SesionEntrenamiento>> editarSesion({
    required String id,
    required DatosSesion datos,
  });

  Future<Result<void>> eliminarSesion(String id);

  // --- Bloque (CU-07, CU-11, CU-15) ---

  Future<Result<BloqueEjercicio>> crearBloque(DatosBloque datos);

  Future<Result<BloqueEjercicio>> editarBloque({
    required String id,
    required DatosBloque datos,
  });

  Future<Result<void>> eliminarBloque(String id);

  /// Renumera los bloques de la sesion en el orden recibido (CU-11).
  ///
  /// La lista tiene que traer **todos** los bloques de la sesion y cada uno una
  /// sola vez: la operacion renumera del 1 al N, no mueve uno suelto. Va en una
  /// sola transaccion porque el indice unico de `(sesion_id, orden)` no admite
  /// estados intermedios con dos bloques en la misma posicion.
  Future<Result<void>> reordenarBloques({
    required String sesionId,
    required List<String> idsEnOrden,
  });

  // --- Ejercicio planificado y sus series (CU-08, CU-12, CU-16) ---

  /// Crea el ejercicio planificado y, si es de Fuerza, sus series en el mismo
  /// flujo. Si la insercion de las series falla, el ejercicio se borra: no debe
  /// quedar un ejercicio de Fuerza sin ninguna serie.
  Future<Result<EjercicioPlanificado>> crearEjercicioPlanificado(
    DatosEjercicioPlanificado datos,
  );

  /// Edita el ejercicio y reemplaza sus series por las indicadas.
  Future<Result<EjercicioPlanificado>> editarEjercicioPlanificado({
    required String id,
    required DatosEjercicioPlanificado datos,
  });

  /// Quita el ejercicio del bloque. No toca la biblioteca (CU-16).
  Future<Result<void>> eliminarEjercicioPlanificado(String id);

  /// Renumera los ejercicios del bloque en el orden recibido (CU-12). Mismas
  /// condiciones que [reordenarBloques].
  Future<Result<void>> reordenarEjerciciosPlanificados({
    required String bloqueId,
    required List<String> idsEnOrden,
  });
}
