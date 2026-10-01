import 'package:json_annotation/json_annotation.dart';

/// Alta y baja logica del cliente. Nunca hay borrado fisico: una baja conserva
/// el historico completo y solo bloquea el acceso.
@JsonEnum(fieldRename: FieldRename.snake)
enum EstadoCliente {
  activo,
  baja;

  bool get esActivo => this == EstadoCliente.activo;
  bool get estaDeBaja => this == EstadoCliente.baja;

  String get etiqueta => switch (this) {
    EstadoCliente.activo => 'Activo',
    EstadoCliente.baja => 'De baja',
  };
}
