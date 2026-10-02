import 'package:json_annotation/json_annotation.dart';

/// Estado del planning. Un planning archivado solo se consulta: no admite anadir,
/// editar ni eliminar sesiones.
@JsonEnum(fieldRename: FieldRename.snake)
enum EstadoPlanning {
  activo,
  archivado;

  bool get esActivo => this == EstadoPlanning.activo;
  bool get estaArchivado => this == EstadoPlanning.archivado;

  String get etiqueta => switch (this) {
    EstadoPlanning.activo => 'Activo',
    EstadoPlanning.archivado => 'Archivado',
  };
}

/// Tipo de bloque dentro de una sesion. Es organizativo: no condiciona si el
/// ejercicio usa series o minutos (eso lo decide `Ejercicio.tipo`).
@JsonEnum(fieldRename: FieldRename.snake)
enum TipoBloque {
  calentamiento,
  fuerza,
  cardio,
  movilidad,
  otro;

  String get etiqueta => switch (this) {
    TipoBloque.calentamiento => 'Calentamiento',
    TipoBloque.fuerza => 'Fuerza',
    TipoBloque.cardio => 'Cardio',
    TipoBloque.movilidad => 'Movilidad',
    TipoBloque.otro => 'Otro',
  };
}

/// Derivado y mantenido por trigger en la fase 5: pasa a `registrado` cuando el
/// cliente anota al menos una serie realizada (Fuerza) o sus minutos (Cardio).
@JsonEnum(fieldRename: FieldRename.snake)
enum EstadoRegistro {
  pendiente,
  registrado;

  bool get estaRegistrado => this == EstadoRegistro.registrado;
}
