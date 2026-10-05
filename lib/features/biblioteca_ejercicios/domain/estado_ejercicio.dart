import 'package:json_annotation/json_annotation.dart';

/// Baja logica del ejercicio. Nunca se hace `DELETE` fisico: un ejercicio
/// `eliminado` no puede anadirse a nuevos bloques, pero sigue visible en los
/// que ya lo usaban.
@JsonEnum(fieldRename: FieldRename.snake)
enum EstadoEjercicio {
  activo,
  eliminado;

  bool get esActivo => this == EstadoEjercicio.activo;
  bool get estaEliminado => this == EstadoEjercicio.eliminado;
}
