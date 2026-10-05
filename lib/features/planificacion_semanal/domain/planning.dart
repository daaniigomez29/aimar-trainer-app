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

    /// OJO con el `JsonKey`: la consulta incrusta el recurso con el nombre de la
    /// tabla (`sesiones_entrenamiento`), no con el del campo. Sin el, la lista
    /// llegaba siempre vacia y la semana se veia entera como dias de descanso.
    @Default([])
    @JsonKey(name: 'sesiones_entrenamiento')
    List<SesionEntrenamiento> sesiones,
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

  /// Las sesiones en su orden (Dia 1, Dia 2...).
  List<SesionEntrenamiento> get sesionesOrdenadas =>
      [...sesiones]..sort((a, b) => a.orden.compareTo(b.orden));

  /// La sesion con ese numero, o `null` si no existe.
  SesionEntrenamiento? sesionNumero(int orden) =>
      sesiones.where((s) => s.orden == orden).firstOrNull;

  /// Numero que le toca a la siguiente sesion que se anada.
  int get siguienteOrden =>
      sesiones.fold<int>(
        0,
        (maximo, s) => s.orden > maximo ? s.orden : maximo,
      ) +
      1;

  /// La primera sesion que el cliente no ha terminado, que es por la que seguir.
  SesionEntrenamiento? get siguientePendiente =>
      sesionesOrdenadas.where((s) => !s.resultadoRegistrado).firstOrNull;

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

/// Sesion de entrenamiento (entidad 3).
///
/// **No tiene fecha planificada**: se numera dentro de su planning (Dia 1, Dia
/// 2...). El entrenador planifica cuantas sesiones hay, no en que dia de la
/// semana caen, para que al cliente no le penalice entrenar el jueves lo que
/// estaba previsto para el miercoles.
///
/// Lo que si se guarda es [fechaRealizada]: el dia en que el cliente la hizo.
@freezed
abstract class SesionEntrenamiento with _$SesionEntrenamiento {
  const factory SesionEntrenamiento({
    required String id,
    required String planningId,
    required int orden,
    required String nombre,

    /// Dia en que el cliente registro algo de esta sesion. `null` mientras no la
    /// haya empezado. La rellena un trigger en el primer registro; la app no la
    /// escribe nunca.
    DateTime? fechaRealizada,
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

    /// Lo que el cliente registro de verdad (CU-20). Independiente de `series`:
    /// puede tener mas, menos o ninguna.
    @Default([])
    @JsonKey(name: 'series_realizadas')
    List<SerieRealizada> seriesRealizadas,
  }) = _EjercicioPlanificado;

  factory EjercicioPlanificado.fromJson(Map<String, dynamic> json) =>
      _$EjercicioPlanificadoFromJson(json);
}

/// Serie realizada (entidad 8): lo que el cliente hizo, frente a lo que el
/// entrenador planifico.
///
/// Vive aqui, con el resto de la jerarquia del planning, aunque quien la escribe
/// sea la feature `progreso`: la consulta del planning la trae incrustada, y asi
/// la dependencia va en un solo sentido (`progreso` conoce `planificacion`, no al
/// reves).
@freezed
abstract class SerieRealizada with _$SerieRealizada {
  const factory SerieRealizada({
    required String id,
    required String ejercicioPlanificadoId,
    required int numeroSerie,
    required int repeticionesRealizadas,
    required DateTime fechaHoraRegistro,
    double? pesoReal,
    int? rirReal,
  }) = _SerieRealizada;

  factory SerieRealizada.fromJson(Map<String, dynamic> json) =>
      _$SerieRealizadaFromJson(json);
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
