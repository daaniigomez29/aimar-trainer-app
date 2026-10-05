// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metricas_progreso.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegistroProgreso _$RegistroProgresoFromJson(
  Map<String, dynamic> json,
) => _RegistroProgreso(
  clienteId: json['cliente_id'] as String,
  ejercicioId: json['ejercicio_id'] as String,
  ejercicioNombre: json['ejercicio_nombre'] as String,
  ejercicioTipo: $enumDecode(_$TipoEjercicioEnumMap, json['ejercicio_tipo']),
  sesionId: json['sesion_id'] as String,
  fecha: DateTime.parse(json['fecha'] as String),
  numeroSerie: (json['numero_serie'] as num?)?.toInt(),
  repeticionesRealizadas: (json['repeticiones_realizadas'] as num?)?.toInt(),
  pesoReal: (json['peso_real'] as num?)?.toDouble(),
  rirReal: (json['rir_real'] as num?)?.toInt(),
  minutosRealizados: (json['minutos_realizados'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RegistroProgresoToJson(_RegistroProgreso instance) =>
    <String, dynamic>{
      'cliente_id': instance.clienteId,
      'ejercicio_id': instance.ejercicioId,
      'ejercicio_nombre': instance.ejercicioNombre,
      'ejercicio_tipo': _$TipoEjercicioEnumMap[instance.ejercicioTipo]!,
      'sesion_id': instance.sesionId,
      'fecha': instance.fecha.toIso8601String(),
      'numero_serie': instance.numeroSerie,
      'repeticiones_realizadas': instance.repeticionesRealizadas,
      'peso_real': instance.pesoReal,
      'rir_real': instance.rirReal,
      'minutos_realizados': instance.minutosRealizados,
    };

const _$TipoEjercicioEnumMap = {
  TipoEjercicio.fuerza: 'fuerza',
  TipoEjercicio.cardio: 'cardio',
};

_EjercicioConRegistro _$EjercicioConRegistroFromJson(
  Map<String, dynamic> json,
) => _EjercicioConRegistro(
  ejercicioId: json['ejercicio_id'] as String,
  ejercicioNombre: json['ejercicio_nombre'] as String,
  ejercicioTipo: $enumDecode(_$TipoEjercicioEnumMap, json['ejercicio_tipo']),
);

Map<String, dynamic> _$EjercicioConRegistroToJson(
  _EjercicioConRegistro instance,
) => <String, dynamic>{
  'ejercicio_id': instance.ejercicioId,
  'ejercicio_nombre': instance.ejercicioNombre,
  'ejercicio_tipo': _$TipoEjercicioEnumMap[instance.ejercicioTipo]!,
};
