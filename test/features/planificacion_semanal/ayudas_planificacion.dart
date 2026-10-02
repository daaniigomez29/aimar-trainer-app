import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Constructores de entidades de planificacion para los tests, con valores por
/// defecto razonables para no repetirlos en cada caso.

PlanningSemanal planningDePrueba({
  String id = 'p-1',
  String clienteId = 'cli-1',
  DateTime? fechaInicio,
  EstadoPlanning estado = EstadoPlanning.activo,
  String? nombreObjetivo,
  List<SesionEntrenamiento> sesiones = const [],
}) => PlanningSemanal(
  id: id,
  clienteId: clienteId,
  fechaInicio: fechaInicio ?? DateTime(2026, 10, 5),
  estado: estado,
  creadoEn: DateTime.utc(2026, 10),
  nombreObjetivo: nombreObjetivo,
  sesiones: sesiones,
);

SesionEntrenamiento sesionDePrueba({
  String id = 's-1',
  String planningId = 'p-1',
  DateTime? fecha,
  String nombre = 'Empuje',
  bool resultadoRegistrado = false,
  List<BloqueEjercicio> bloques = const [],
}) => SesionEntrenamiento(
  id: id,
  planningId: planningId,
  fecha: fecha ?? DateTime(2026, 10, 5),
  nombre: nombre,
  resultadoRegistrado: resultadoRegistrado,
  bloques: bloques,
);

BloqueEjercicio bloqueDePrueba({
  String id = 'b-1',
  String sesionId = 's-1',
  TipoBloque tipo = TipoBloque.fuerza,
  int orden = 1,
  String? notas,
  List<EjercicioPlanificado> ejercicios = const [],
}) => BloqueEjercicio(
  id: id,
  sesionId: sesionId,
  tipo: tipo,
  orden: orden,
  notas: notas,
  ejercicios: ejercicios,
);

Ejercicio ejercicioDePrueba({
  String id = 'ej-1',
  String nombre = 'Press banca',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
}) => Ejercicio(
  id: id,
  nombre: nombre,
  descripcion: 'Descripcion.',
  tipo: tipo,
  estado: EstadoEjercicio.activo,
  creadoEn: DateTime.utc(2026),
);

EjercicioPlanificado ejercicioPlanificadoDePrueba({
  String id = 'ep-1',
  String bloqueId = 'b-1',
  int orden = 1,
  Ejercicio? ejercicio,
  double? minutosPlanificados,
  int? descansoSeg,
  List<SeriePlanificada> series = const [],
  EstadoRegistro estadoRegistro = EstadoRegistro.pendiente,
}) => EjercicioPlanificado(
  id: id,
  bloqueId: bloqueId,
  ejercicioId: (ejercicio ?? ejercicioDePrueba()).id,
  orden: orden,
  estadoRegistro: estadoRegistro,
  descansoPlanificadoSeg: descansoSeg,
  minutosPlanificados: minutosPlanificados,
  ejercicio: ejercicio ?? ejercicioDePrueba(),
  series: series,
);

SeriePlanificada serieDePrueba({
  String id = 'sp-1',
  String ejercicioPlanificadoId = 'ep-1',
  int numeroSerie = 1,
  int repeticiones = 10,
  double? peso,
  int? rir,
}) => SeriePlanificada(
  id: id,
  ejercicioPlanificadoId: ejercicioPlanificadoId,
  numeroSerie: numeroSerie,
  repeticionesPlanificadas: repeticiones,
  pesoPlanificado: peso,
  rirPlanificado: rir,
);

DatosEjercicioPlanificado datosEjercicio({
  required TipoEjercicio tipo,
  String bloqueId = 'b-1',
  String ejercicioId = 'ej-1',
  int orden = 1,
  int? descansoSeg,
  double? minutos,
  List<DatosSerie> series = const [],
}) => DatosEjercicioPlanificado(
  bloqueId: bloqueId,
  ejercicioId: ejercicioId,
  tipoEjercicio: tipo,
  orden: orden,
  descansoSeg: descansoSeg,
  minutos: minutos,
  series: series,
);
