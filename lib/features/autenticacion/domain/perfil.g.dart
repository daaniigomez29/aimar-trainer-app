// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Perfil _$PerfilFromJson(Map<String, dynamic> json) => _Perfil(
  id: json['id'] as String,
  rol: $enumDecode(_$RolUsuarioEnumMap, json['rol']),
  creadoEn: DateTime.parse(json['creado_en'] as String),
);

Map<String, dynamic> _$PerfilToJson(_Perfil instance) => <String, dynamic>{
  'id': instance.id,
  'rol': _$RolUsuarioEnumMap[instance.rol]!,
  'creado_en': instance.creadoEn.toIso8601String(),
};

const _$RolUsuarioEnumMap = {
  RolUsuario.administrador: 'administrador',
  RolUsuario.entrenador: 'entrenador',
  RolUsuario.cliente: 'cliente',
};
