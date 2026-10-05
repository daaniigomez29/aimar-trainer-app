// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medidas.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegistroMedidas _$RegistroMedidasFromJson(Map<String, dynamic> json) =>
    _RegistroMedidas(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      pesoKg: (json['peso_kg'] as num).toDouble(),
      pechoCm: (json['pecho_cm'] as num?)?.toDouble(),
      cinturaCm: (json['cintura_cm'] as num?)?.toDouble(),
      caderaCm: (json['cadera_cm'] as num?)?.toDouble(),
      cuadricepsCm: (json['cuadriceps_cm'] as num?)?.toDouble(),
      brazosCm: (json['brazos_cm'] as num?)?.toDouble(),
      fotos:
          (json['fotos_progreso'] as List<dynamic>?)
              ?.map((e) => FotoProgreso.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RegistroMedidasToJson(_RegistroMedidas instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cliente_id': instance.clienteId,
      'fecha': instance.fecha.toIso8601String(),
      'peso_kg': instance.pesoKg,
      'pecho_cm': instance.pechoCm,
      'cintura_cm': instance.cinturaCm,
      'cadera_cm': instance.caderaCm,
      'cuadriceps_cm': instance.cuadricepsCm,
      'brazos_cm': instance.brazosCm,
      'fotos_progreso': instance.fotos.map((e) => e.toJson()).toList(),
    };

_FotoProgreso _$FotoProgresoFromJson(Map<String, dynamic> json) =>
    _FotoProgreso(
      id: json['id'] as String,
      registroMedidasId: json['registro_medidas_id'] as String,
      rutaStorage: json['ruta_storage'] as String,
      subidaEn: DateTime.parse(json['subida_en'] as String),
    );

Map<String, dynamic> _$FotoProgresoToJson(_FotoProgreso instance) =>
    <String, dynamic>{
      'id': instance.id,
      'registro_medidas_id': instance.registroMedidasId,
      'ruta_storage': instance.rutaStorage,
      'subida_en': instance.subidaEn.toIso8601String(),
    };

_CheckinRecuperacion _$CheckinRecuperacionFromJson(Map<String, dynamic> json) =>
    _CheckinRecuperacion(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      horasSueno: (json['horas_sueno'] as num).toDouble(),
      estres: (json['estres'] as num).toInt(),
      agujetas: (json['agujetas'] as num).toInt(),
      fatiga: (json['fatiga'] as num).toInt(),
      notas: json['notas'] as String?,
    );

Map<String, dynamic> _$CheckinRecuperacionToJson(
  _CheckinRecuperacion instance,
) => <String, dynamic>{
  'id': instance.id,
  'cliente_id': instance.clienteId,
  'fecha': instance.fecha.toIso8601String(),
  'horas_sueno': instance.horasSueno,
  'estres': instance.estres,
  'agujetas': instance.agujetas,
  'fatiga': instance.fatiga,
  'notas': instance.notas,
};
