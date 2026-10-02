// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanningSemanal _$PlanningSemanalFromJson(Map<String, dynamic> json) =>
    _PlanningSemanal(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      estado: $enumDecode(_$EstadoPlanningEnumMap, json['estado']),
      creadoEn: DateTime.parse(json['creado_en'] as String),
      nombreObjetivo: json['nombre_objetivo'] as String?,
      sesiones:
          (json['sesiones'] as List<dynamic>?)
              ?.map(
                (e) => SesionEntrenamiento.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlanningSemanalToJson(_PlanningSemanal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cliente_id': instance.clienteId,
      'fecha_inicio': instance.fechaInicio.toIso8601String(),
      'estado': _$EstadoPlanningEnumMap[instance.estado]!,
      'creado_en': instance.creadoEn.toIso8601String(),
      'nombre_objetivo': instance.nombreObjetivo,
      'sesiones': instance.sesiones.map((e) => e.toJson()).toList(),
    };

const _$EstadoPlanningEnumMap = {
  EstadoPlanning.activo: 'activo',
  EstadoPlanning.archivado: 'archivado',
};

_SesionEntrenamiento _$SesionEntrenamientoFromJson(Map<String, dynamic> json) =>
    _SesionEntrenamiento(
      id: json['id'] as String,
      planningId: json['planning_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      nombre: json['nombre'] as String,
      resultadoRegistrado: json['resultado_registrado'] as bool? ?? false,
      bloques:
          (json['bloques_ejercicio'] as List<dynamic>?)
              ?.map((e) => BloqueEjercicio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SesionEntrenamientoToJson(
  _SesionEntrenamiento instance,
) => <String, dynamic>{
  'id': instance.id,
  'planning_id': instance.planningId,
  'fecha': instance.fecha.toIso8601String(),
  'nombre': instance.nombre,
  'resultado_registrado': instance.resultadoRegistrado,
  'bloques_ejercicio': instance.bloques.map((e) => e.toJson()).toList(),
};

_BloqueEjercicio _$BloqueEjercicioFromJson(Map<String, dynamic> json) =>
    _BloqueEjercicio(
      id: json['id'] as String,
      sesionId: json['sesion_id'] as String,
      tipo: $enumDecode(_$TipoBloqueEnumMap, json['tipo']),
      orden: (json['orden'] as num).toInt(),
      notas: json['notas'] as String?,
      ejercicios:
          (json['ejercicios_planificados'] as List<dynamic>?)
              ?.map(
                (e) => EjercicioPlanificado.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BloqueEjercicioToJson(_BloqueEjercicio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sesion_id': instance.sesionId,
      'tipo': _$TipoBloqueEnumMap[instance.tipo]!,
      'orden': instance.orden,
      'notas': instance.notas,
      'ejercicios_planificados': instance.ejercicios
          .map((e) => e.toJson())
          .toList(),
    };

const _$TipoBloqueEnumMap = {
  TipoBloque.calentamiento: 'calentamiento',
  TipoBloque.fuerza: 'fuerza',
  TipoBloque.cardio: 'cardio',
  TipoBloque.movilidad: 'movilidad',
  TipoBloque.otro: 'otro',
};

_EjercicioPlanificado _$EjercicioPlanificadoFromJson(
  Map<String, dynamic> json,
) => _EjercicioPlanificado(
  id: json['id'] as String,
  bloqueId: json['bloque_id'] as String,
  ejercicioId: json['ejercicio_id'] as String,
  orden: (json['orden'] as num).toInt(),
  estadoRegistro: $enumDecode(_$EstadoRegistroEnumMap, json['estado_registro']),
  descansoPlanificadoSeg: (json['descanso_planificado_seg'] as num?)?.toInt(),
  minutosPlanificados: (json['minutos_planificados'] as num?)?.toDouble(),
  minutosRealizados: (json['minutos_realizados'] as num?)?.toDouble(),
  ejercicio: json['ejercicios'] == null
      ? null
      : Ejercicio.fromJson(json['ejercicios'] as Map<String, dynamic>),
  series:
      (json['series_planificadas'] as List<dynamic>?)
          ?.map((e) => SeriePlanificada.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$EjercicioPlanificadoToJson(
  _EjercicioPlanificado instance,
) => <String, dynamic>{
  'id': instance.id,
  'bloque_id': instance.bloqueId,
  'ejercicio_id': instance.ejercicioId,
  'orden': instance.orden,
  'estado_registro': _$EstadoRegistroEnumMap[instance.estadoRegistro]!,
  'descanso_planificado_seg': instance.descansoPlanificadoSeg,
  'minutos_planificados': instance.minutosPlanificados,
  'minutos_realizados': instance.minutosRealizados,
  'ejercicios': instance.ejercicio?.toJson(),
  'series_planificadas': instance.series.map((e) => e.toJson()).toList(),
};

const _$EstadoRegistroEnumMap = {
  EstadoRegistro.pendiente: 'pendiente',
  EstadoRegistro.registrado: 'registrado',
};

_SeriePlanificada _$SeriePlanificadaFromJson(Map<String, dynamic> json) =>
    _SeriePlanificada(
      id: json['id'] as String,
      ejercicioPlanificadoId: json['ejercicio_planificado_id'] as String,
      numeroSerie: (json['numero_serie'] as num).toInt(),
      repeticionesPlanificadas: (json['repeticiones_planificadas'] as num)
          .toInt(),
      pesoPlanificado: (json['peso_planificado'] as num?)?.toDouble(),
      rirPlanificado: (json['rir_planificado'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SeriePlanificadaToJson(_SeriePlanificada instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ejercicio_planificado_id': instance.ejercicioPlanificadoId,
      'numero_serie': instance.numeroSerie,
      'repeticiones_planificadas': instance.repeticionesPlanificadas,
      'peso_planificado': instance.pesoPlanificado,
      'rir_planificado': instance.rirPlanificado,
    };
