import 'package:json_annotation/json_annotation.dart';

/// Roles de la aplicacion. Se corresponde 1:1 con el enum `rol_usuario` de
/// Postgres, por lo que los nombres deben coincidir exactamente.
@JsonEnum(fieldRename: FieldRename.snake)
enum RolUsuario {
  administrador,
  entrenador,
  cliente;

  bool get esEntrenador => this == RolUsuario.entrenador;
  bool get esAdministrador => this == RolUsuario.administrador;
  bool get esCliente => this == RolUsuario.cliente;
}
