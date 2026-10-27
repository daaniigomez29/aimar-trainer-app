// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Pack _$PackFromJson(Map<String, dynamic> json) => _Pack(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  tipos: (json['tipos'] as List<dynamic>)
      .map((e) => $enumDecode(_$TipoEjercicioEnumMap, e))
      .toList(),
  creadoEn: DateTime.parse(json['creado_en'] as String),
  ejercicios:
      (json['pack_ejercicios'] as List<dynamic>?)
          ?.map((e) => PackEjercicio.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PackToJson(_Pack instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'tipos': instance.tipos.map((e) => _$TipoEjercicioEnumMap[e]!).toList(),
  'creado_en': instance.creadoEn.toIso8601String(),
  'pack_ejercicios': instance.ejercicios.map((e) => e.toJson()).toList(),
};

const _$TipoEjercicioEnumMap = {
  TipoEjercicio.fuerza: 'fuerza',
  TipoEjercicio.cardio: 'cardio',
  TipoEjercicio.fortalecimiento: 'fortalecimiento',
};

_PackEjercicio _$PackEjercicioFromJson(Map<String, dynamic> json) =>
    _PackEjercicio(
      id: json['id'] as String,
      packId: json['pack_id'] as String,
      ejercicioId: json['ejercicio_id'] as String,
      orden: (json['orden'] as num).toInt(),
      descansoSeg: (json['descanso_seg'] as num?)?.toInt(),
      minutos: (json['minutos'] as num?)?.toDouble(),
      ejercicio: json['ejercicios'] == null
          ? null
          : Ejercicio.fromJson(json['ejercicios'] as Map<String, dynamic>),
      series:
          (json['pack_series'] as List<dynamic>?)
              ?.map((e) => PackSerie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PackEjercicioToJson(_PackEjercicio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pack_id': instance.packId,
      'ejercicio_id': instance.ejercicioId,
      'orden': instance.orden,
      'descanso_seg': instance.descansoSeg,
      'minutos': instance.minutos,
      'ejercicios': instance.ejercicio?.toJson(),
      'pack_series': instance.series.map((e) => e.toJson()).toList(),
    };

_PackSerie _$PackSerieFromJson(Map<String, dynamic> json) => _PackSerie(
  id: json['id'] as String,
  packEjercicioId: json['pack_ejercicio_id'] as String,
  numeroSerie: (json['numero_serie'] as num).toInt(),
  repeticiones: (json['repeticiones'] as num).toInt(),
  peso: (json['peso'] as num?)?.toDouble(),
  rir: (json['rir'] as num?)?.toInt(),
);

Map<String, dynamic> _$PackSerieToJson(_PackSerie instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pack_ejercicio_id': instance.packEjercicioId,
      'numero_serie': instance.numeroSerie,
      'repeticiones': instance.repeticiones,
      'peso': instance.peso,
      'rir': instance.rir,
    };
