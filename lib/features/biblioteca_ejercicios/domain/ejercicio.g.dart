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
  grupoDeclarado: const ConversorGrupoMuscular().fromJson(
    json['grupo_muscular'] as String?,
  ),
  musculoPrincipal: const ConversorMusculo().fromJson(
    json['musculo_principal'] as String?,
  ),
  musculosSecundarios: json['musculos_secundarios'] == null
      ? const <Musculo>[]
      : const ConversorMusculos().fromJson(
          json['musculos_secundarios'] as List?,
        ),
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
      'grupo_muscular': const ConversorGrupoMuscular().toJson(
        instance.grupoDeclarado,
      ),
      'musculo_principal': const ConversorMusculo().toJson(
        instance.musculoPrincipal,
      ),
      'musculos_secundarios': const ConversorMusculos().toJson(
        instance.musculosSecundarios,
      ),
      'equipamiento': instance.equipamiento,
      'video_ejemplo_url': instance.videoEjemploUrl,
      'imagen_ruta': instance.imagenRuta,
    };

const _$TipoEjercicioEnumMap = {
  TipoEjercicio.fuerza: 'fuerza',
  TipoEjercicio.cardio: 'cardio',
  TipoEjercicio.fortalecimiento: 'fortalecimiento',
};

const _$EstadoEjercicioEnumMap = {
  EstadoEjercicio.activo: 'activo',
  EstadoEjercicio.eliminado: 'eliminado',
};
