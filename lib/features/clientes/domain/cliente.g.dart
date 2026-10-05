// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cliente _$ClienteFromJson(Map<String, dynamic> json) => _Cliente(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  correo: json['correo'] as String,
  diaControlPreferido: $enumDecode(
    _$DiaSemanaEnumMap,
    json['dia_control_preferido'],
  ),
  estado: $enumDecode(_$EstadoClienteEnumMap, json['estado']),
  fechaAlta: DateTime.parse(json['fecha_alta'] as String),
  fechaNacimiento: json['fecha_nacimiento'] == null
      ? null
      : DateTime.parse(json['fecha_nacimiento'] as String),
  alturaCm: (json['altura_cm'] as num?)?.toDouble(),
  pesoInicialKg: (json['peso_inicial_kg'] as num?)?.toDouble(),
  objetivos: json['objetivos'] as String?,
  fechaBaja: json['fecha_baja'] == null
      ? null
      : DateTime.parse(json['fecha_baja'] as String),
);

Map<String, dynamic> _$ClienteToJson(_Cliente instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'correo': instance.correo,
  'dia_control_preferido': _$DiaSemanaEnumMap[instance.diaControlPreferido]!,
  'estado': _$EstadoClienteEnumMap[instance.estado]!,
  'fecha_alta': instance.fechaAlta.toIso8601String(),
  'fecha_nacimiento': instance.fechaNacimiento?.toIso8601String(),
  'altura_cm': instance.alturaCm,
  'peso_inicial_kg': instance.pesoInicialKg,
  'objetivos': instance.objetivos,
  'fecha_baja': instance.fechaBaja?.toIso8601String(),
};

const _$DiaSemanaEnumMap = {
  DiaSemana.lunes: 'lunes',
  DiaSemana.martes: 'martes',
  DiaSemana.miercoles: 'miercoles',
  DiaSemana.jueves: 'jueves',
  DiaSemana.viernes: 'viernes',
  DiaSemana.sabado: 'sabado',
  DiaSemana.domingo: 'domingo',
};

const _$EstadoClienteEnumMap = {
  EstadoCliente.activo: 'activo',
  EstadoCliente.baja: 'baja',
};
