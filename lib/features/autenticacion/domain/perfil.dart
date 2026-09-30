import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

part 'perfil.freezed.dart';
part 'perfil.g.dart';

/// Fila de `perfiles`: enlaza la cuenta de Auth con su rol.
///
/// `id` es el mismo uuid que `auth.users.id`.
@freezed
abstract class Perfil with _$Perfil {
  const factory Perfil({
    required String id,
    required RolUsuario rol,
    required DateTime creadoEn,
  }) = _Perfil;

  factory Perfil.fromJson(Map<String, dynamic> json) => _$PerfilFromJson(json);
}
