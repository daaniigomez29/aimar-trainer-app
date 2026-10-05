// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferencias_notificacion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PreferenciasNotificacion _$PreferenciasNotificacionFromJson(
  Map<String, dynamic> json,
) => _PreferenciasNotificacion(
  clienteId: json['cliente_id'] as String,
  pushActivado: json['push_activado'] as bool? ?? false,
  actualizadoEn: json['actualizado_en'] == null
      ? null
      : DateTime.parse(json['actualizado_en'] as String),
);

Map<String, dynamic> _$PreferenciasNotificacionToJson(
  _PreferenciasNotificacion instance,
) => <String, dynamic>{
  'cliente_id': instance.clienteId,
  'push_activado': instance.pushActivado,
  'actualizado_en': instance.actualizadoEn?.toIso8601String(),
};
