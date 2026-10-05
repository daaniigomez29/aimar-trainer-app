// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ejercicio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ejercicio _$EjercicioFromJson(Map<String, dynamic> json) => _Ejercicio(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String,
  tipo: $enumDecode(_$TipoEjercicioEnumMap, json['tipo']),
  estado: $enumDecode(_$EstadoEjercicioEnumMap, json['estado']),
  creadoEn: DateTime.parse(json['creado_en'] as String),
  grupoMuscular: json['grupo_muscular'] as String?,
  equipamiento: json['equipamiento'] as String?,
  videoEjemploUrl: json['video_ejemplo_url'] as String?,
  imagenRuta: json['imagen_ruta'] as String?,
);

Map<String, dynamic> _$EjercicioToJson(_Ejercicio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'tipo': _$TipoEjercicioEnumMap[instance.tipo]!,
      'estado': _$EstadoEjercicioEnumMap[instance.estado]!,
      'creado_en': instance.creadoEn.toIso8601String(),
      'grupo_muscular': instance.grupoMuscular,
      'equipamiento': instance.equipamiento,
      'video_ejemplo_url': instance.videoEjemploUrl,
      'imagen_ruta': instance.imagenRuta,
    };

const _$TipoEjercicioEnumMap = {
  TipoEjercicio.fuerza: 'fuerza',
  TipoEjercicio.cardio: 'cardio',
};

const _$EstadoEjercicioEnumMap = {
  EstadoEjercicio.activo: 'activo',
  EstadoEjercicio.eliminado: 'eliminado',
};
