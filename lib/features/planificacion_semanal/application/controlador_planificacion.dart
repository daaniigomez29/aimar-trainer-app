import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

part 'controlador_planificacion.g.dart';

/// Plannings de un cliente, para su historico (CU-23).
@riverpod
Future<List<PlanningSemanal>> planningsDeCliente(
  Ref ref,
  String clienteId,
) async {
  final resultado = await ref
      .watch(planningRepositorioProvider)
      .listarDeCliente(clienteId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Plannings del cliente que tiene la sesion abierta, para consultar los suyos.
///
/// No recibe el id por parametro a proposito: lo toma de la sesion, asi que la
/// pantalla del cliente no puede pedir el historico de otro ni por error. RLS ya
/// lo impide en el servidor; esto evita siquiera intentarlo.
@riverpod
Future<List<PlanningSemanal>> misPlannings(Ref ref) async {
  final idCliente = ref.watch(idUsuarioActualProvider);
  // Sin sesion resuelta no hay a quien preguntar. El enrutador no deja llegar
  // aqui sin ella, pero el provider no depende de eso.
  if (idCliente == null) return const [];

  final resultado = await ref
      .watch(planningRepositorioProvider)
      .listarDeCliente(idCliente);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Un planning con toda su jerarquia. Es la fuente de la pantalla de edicion.
@riverpod
Future<PlanningSemanal> planningCompleto(Ref ref, String planningId) async {
  final resultado = await ref
      .watch(planningRepositorioProvider)
      .obtenerPlanningCompleto(planningId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Orquesta todas las operaciones de escritura de la planificacion (CU-05 a
/// CU-16).
///
/// Un solo controlador para los cuatro niveles porque comparten el mismo patron:
/// validar en dominio, escribir, recargar el planning. Cada metodo devuelve su
/// `Result` en lugar de dejarlo solo en el estado, por la leccion del fallo de
/// CU-04: con dialogos de por medio, un provider autoDispose puede desecharse.
@riverpod
class ControladorPlanificacion extends _$ControladorPlanificacion {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  // --- Planning (CU-05, CU-09, CU-13) ---

  Future<Result<PlanningSemanal>> crearPlanning(DatosPlanning datos) =>
      _ejecutar(() async {
        final error = datos.validar();
        if (error != null) return Failure(error);
        return ref.read(planningRepositorioProvider).crearPlanning(datos);
      });

  Future<Result<PlanningSemanal>> editarPlanning({
    required String id,
    required DatosPlanning datos,
  }) => _ejecutar(() async {
    final error = datos.validar();
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .editarPlanning(id: id, datos: datos);
  }, planningARecargar: id);

  Future<Result<PlanningSemanal>> archivarPlanning(String id) => _ejecutar(
    () => ref.read(planningRepositorioProvider).archivarPlanning(id),
    planningARecargar: id,
  );

  Future<Result<PlanningSemanal>> reactivarPlanning(String id) => _ejecutar(
    () => ref.read(planningRepositorioProvider).reactivarPlanning(id),
    planningARecargar: id,
  );

  Future<Result<void>> eliminarPlanning(String id) => _ejecutar(
    () => ref.read(planningRepositorioProvider).eliminarPlanning(id),
  );

  // --- Sesion (CU-06, CU-10, CU-14) ---

  Future<Result<SesionEntrenamiento>> crearSesion({
    required DatosSesion datos,
    required PlanningSemanal planning,
  }) => _ejecutar(() async {
    final error = datos.validar(planning: planning);
    if (error != null) return Failure(error);
    return ref.read(planningRepositorioProvider).crearSesion(datos);
  }, planningARecargar: datos.planningId);

  Future<Result<SesionEntrenamiento>> editarSesion({
    required String id,
    required DatosSesion datos,
    required PlanningSemanal planning,
  }) => _ejecutar(() async {
    final error = datos.validar(planning: planning, idSesionQueSeEdita: id);
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .editarSesion(id: id, datos: datos);
  }, planningARecargar: datos.planningId);

  Future<Result<void>> eliminarSesion({
    required String id,
    required String planningId,
  }) => _ejecutar(
    () => ref.read(planningRepositorioProvider).eliminarSesion(id),
    planningARecargar: planningId,
  );

  // --- Bloque (CU-07, CU-11, CU-15) ---

  Future<Result<BloqueEjercicio>> crearBloque({
    required DatosBloque datos,
    required SesionEntrenamiento sesion,
    required String planningId,
  }) => _ejecutar(() async {
    final error = datos.validar(sesion: sesion);
    if (error != null) return Failure(error);
    return ref.read(planningRepositorioProvider).crearBloque(datos);
  }, planningARecargar: planningId);

  Future<Result<BloqueEjercicio>> editarBloque({
    required String id,
    required DatosBloque datos,
    required SesionEntrenamiento sesion,
    required String planningId,
  }) => _ejecutar(() async {
    final error = datos.validar(sesion: sesion, idBloqueQueSeEdita: id);
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .editarBloque(id: id, datos: datos);
  }, planningARecargar: planningId);

  Future<Result<void>> eliminarBloque({
    required String id,
    required String planningId,
  }) => _ejecutar(
    () => ref.read(planningRepositorioProvider).eliminarBloque(id),
    planningARecargar: planningId,
  );

  /// Reordena los bloques de la sesion (CU-11), arrastrandolos.
  ///
  /// Recibe los bloques ya en el orden que deben quedar: la pantalla mueve la
  /// tarjeta en su lista y manda el resultado, que es como se arrastra.
  Future<Result<void>> reordenarBloques({
    required SesionEntrenamiento sesion,
    required List<String> idsEnOrden,
    required String planningId,
  }) => _ejecutar(() async {
    final error = validarReordenacion(
      idsEnOrden: idsEnOrden,
      idsActuales: [for (final bloque in sesion.bloques) bloque.id],
    );
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .reordenarBloques(sesionId: sesion.id, idsEnOrden: idsEnOrden);
  }, planningARecargar: planningId);

  // --- Ejercicio planificado (CU-08, CU-12, CU-16) ---

  Future<Result<EjercicioPlanificado>> crearEjercicio({
    required DatosEjercicioPlanificado datos,
    required BloqueEjercicio bloque,
    required String planningId,
  }) => _ejecutar(() async {
    final error = datos.validar(bloque: bloque);
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .crearEjercicioPlanificado(datos);
  }, planningARecargar: planningId);

  Future<Result<EjercicioPlanificado>> editarEjercicio({
    required String id,
    required DatosEjercicioPlanificado datos,
    required BloqueEjercicio bloque,
    required String planningId,
  }) => _ejecutar(() async {
    final error = datos.validar(bloque: bloque, idQueSeEdita: id);
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .editarEjercicioPlanificado(id: id, datos: datos);
  }, planningARecargar: planningId);

  Future<Result<void>> eliminarEjercicio({
    required String id,
    required String planningId,
  }) => _ejecutar(
    () =>
        ref.read(planningRepositorioProvider).eliminarEjercicioPlanificado(id),
    planningARecargar: planningId,
  );

  /// Reordena los ejercicios dentro de un bloque (CU-12), arrastrandolos.
  Future<Result<void>> reordenarEjercicios({
    required BloqueEjercicio bloque,
    required List<String> idsEnOrden,
    required String planningId,
  }) => _ejecutar(() async {
    final error = validarReordenacion(
      idsEnOrden: idsEnOrden,
      idsActuales: [for (final ejercicio in bloque.ejercicios) ejercicio.id],
    );
    if (error != null) return Failure(error);
    return ref
        .read(planningRepositorioProvider)
        .reordenarEjerciciosPlanificados(
          bloqueId: bloque.id,
          idsEnOrden: idsEnOrden,
        );
  }, planningARecargar: planningId);

  /// Envoltorio comun: marca el estado, ejecuta, recarga el planning si procede y
  /// devuelve el resultado.
  Future<Result<T>> _ejecutar<T>(
    Future<Result<T>> Function() operacion, {
    String? planningARecargar,
  }) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operacion en curso.'));
    }
    state = const EstadoAccion.enCurso();
    final resultado = await operacion();

    // El provider puede haberse desechado durante la espera.
    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito && planningARecargar != null) {
        ref.invalidate(planningCompletoProvider(planningARecargar));
      }
    }
    return resultado;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }

  void reiniciar() => state = const EstadoAccion.inicial();
}

/// Mensaje listo para mostrar a partir de lo que capture `AsyncValue`.
String mensajeDeErrorPlanificacion(Object error) =>
    error is ErrorApp ? error.mensaje : const ErrorInesperado().mensaje;
