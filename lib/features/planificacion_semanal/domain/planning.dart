import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';

part 'planning.freezed.dart';
part 'planning.g.dart';

/// Planning semanal (entidad 2 de `docs/domain-model.md`).
///
/// La semana va de `fechaInicio` a `fechaInicio + 6`, sin suponer que empiece en
/// lunes: lo decide el entrenador al crearlo.
@freezed
abstract class PlanningSemanal with _$PlanningSemanal {
  const factory PlanningSemanal({
    required String id,
    required String clienteId,
    required DateTime fechaInicio,
    required EstadoPlanning estado,
    required DateTime creadoEn,
    String? nombreObjetivo,
    @Default([]) List<SesionEntrenamiento> sesiones,
  }) = _PlanningSemanal;

  factory PlanningSemanal.fromJson(Map<String, dynamic> json) =>
      _$PlanningSemanalFromJson(json);
}

/// Dias que abarca el planning, en orden.
extension SemanaDelPlanning on PlanningSemanal {
  static const int diasPorSemana = 7;

  DateTime get fechaFin =>
      fechaInicio.add(const Duration(days: diasPorSemana - 1));

  List<DateTime> get dias => [
    for (var i = 0; i < diasPorSemana; i++)
      DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day + i),
  ];

  /// La sesion de un dia concreto, o `null` si ese dia es de descanso.
  SesionEntrenamiento? sesionDe(DateTime dia) => sesiones
      .where(
        (s) =>
            s.fecha.year == dia.year &&
            s.fecha.month == dia.month &&
            s.fecha.day == dia.day,
      )
      .firstOrNull;

  bool contiene(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final inicio = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
    );
    return !dia.isBefore(inicio) &&
        !dia.isAfter(inicio.add(const Duration(days: diasPorSemana - 1)));
  }

  /// Se puede modificar solo si esta activo (regla de dominio del planning).
  bool get esEditable => estado.esActivo;
}

/// Sesion de entrenamiento (entidad 3). Se planifica sobre una fecha real de
/// calendario, no un dia de la semana suelto.
@freezed
abstract class SesionEntrenamiento with _$SesionEntrenamiento {
  const factory SesionEntrenamiento({
    required String id,
    required String planningId,
    required DateTime fecha,
    required String nombre,
    @Default(false) bool resultadoRegistrado,
    @Default([])
    @JsonKey(name: 'bloques_ejercicio')
    List<BloqueEjercicio> bloques,
  }) = _SesionEntrenamiento;

  factory SesionEntrenamiento.fromJson(Map<String, dynamic> json) =>
      _$SesionEntrenamientoFromJson(json);
}

/// Bloque de ejercicio (entidad 4). Se ordena por `orden` dentro de su sesion.
@freezed
abstract class BloqueEjercicio with _$BloqueEjercicio {
  const factory BloqueEjercicio({
    required String id,
    required String sesionId,
    required TipoBloque tipo,
    required int orden,
    String? notas,
    @Default([])
    @JsonKey(name: 'ejercicios_planificados')
    List<EjercicioPlanificado> ejercicios,
  }) = _BloqueEjercicio;

  factory BloqueEjercicio.fromJson(Map<String, dynamic> json) =>
      _$BloqueEjercicioFromJson(json);
}

/// Ejercicio planificado (entidad 6).
///
/// Fuerza y Cardio son mutuamente excluyentes: si el ejercicio de la biblioteca es
/// de Fuerza usa `series`; si es de Cardio usa `minutosPlanificados`. Nunca ambos.
@freezed
abstract class EjercicioPlanificado with _$EjercicioPlanificado {
  const factory EjercicioPlanificado({
    required String id,
    required String bloqueId,
    required String ejercicioId,
    required int orden,
    required EstadoRegistro estadoRegistro,
    int? descansoPlanificadoSeg,
    double? minutosPlanificados,
    double? minutosRealizados,

    /// El ejercicio de la biblioteca, incrustado por la consulta. Es quien dice si
    /// esto va con series o con minutos.
    @JsonKey(name: 'ejercicios') Ejercicio? ejercicio,
    @Default([])
    @JsonKey(name: 'series_planificadas')
    List<SeriePlanificada> series,
  }) = _EjercicioPlanificado;

  factory EjercicioPlanificado.fromJson(Map<String, dynamic> json) =>
      _$EjercicioPlanificadoFromJson(json);
}

/// Serie planificada (entidad 7). Solo para ejercicios de Fuerza.
@freezed
abstract class SeriePlanificada with _$SeriePlanificada {
  const factory SeriePlanificada({
    required String id,
    required String ejercicioPlanificadoId,
    required int numeroSerie,
    required int repeticionesPlanificadas,
    double? pesoPlanificado,
    int? rirPlanificado,
  }) = _SeriePlanificada;

  factory SeriePlanificada.fromJson(Map<String, dynamic> json) =>
      _$SeriePlanificadaFromJson(json);
}
