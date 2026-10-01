import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';

/// Puerto de dominio de la biblioteca de ejercicios (CU-02, CU-03, CU-04).
///
/// No hay metodo de borrado: la baja es siempre logica, con [darDeBaja]. La tabla
/// tampoco concede el privilegio `DELETE`, asi que no existe la operacion ni por
/// debajo.
abstract interface class EjercicioRepositorio {
  /// Biblioteca completa, activos y eliminados, ordenada por nombre. El filtrado
  /// se hace en memoria (ver `FiltroEjercicios.aceptar`).
  Future<Result<List<Ejercicio>>> listar();

  Future<Result<Ejercicio>> obtenerPorId(String id);

  /// CU-02. Falla con `ErrorNombreDuplicado` si ya existe un ejercicio **activo**
  /// con ese nombre; un nombre liberado por una baja si puede reutilizarse.
  Future<Result<Ejercicio>> crear(DatosEjercicio datos);

  /// CU-03. Mismas reglas de nombre duplicado que [crear].
  Future<Result<Ejercicio>> editar({
    required String id,
    required DatosEjercicio datos,
  });

  /// CU-04: baja logica (`estado = 'eliminado'`).
  Future<Result<Ejercicio>> darDeBaja(String id);

  /// Reactiva un ejercicio dado de baja. No es un caso de uso del ERS, pero la
  /// baja logica lo hace trivial y evita que un descuido sea irreversible.
  Future<Result<Ejercicio>> reactivar(String id);

  /// Cuantos bloques de plannings **activos** referencian el ejercicio (CU-04:
  /// hay que avisar antes de darlo de baja).
  ///
  /// Devuelve 0 mientras no existan las tablas de planificacion (fase 4).
  Future<Result<int>> contarUsosEnPlanningsActivos(String id);
}
