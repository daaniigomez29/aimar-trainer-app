import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/credenciales.dart';

part 'controlador_login.g.dart';

/// CU-01 Iniciar sesion: valida el formulario y delega en el repositorio.
///
/// No navega: al terminar con exito, `ControladorSesion` recibe el evento de
/// Auth y el enrutador redirige segun el rol.
@riverpod
class ControladorLogin extends _$ControladorLogin {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    if (state.enCurso) return;

    final credenciales = Credenciales(correo: correo, contrasena: contrasena);
    final errorValidacion = credenciales.validar();
    if (errorValidacion != null) {
      state = EstadoAccion.conError(errorValidacion);
      return;
    }

    state = const EstadoAccion.enCurso();
    final resultado = await ref
        .read(autenticacionRepositorioProvider)
        .iniciarSesion(
          correo: credenciales.correoNormalizado,
          contrasena: contrasena,
        );
    state = switch (resultado) {
      Success() => const EstadoAccion.completada(),
      Failure(:final error) => EstadoAccion.conError(error),
    };
  }

  /// Limpia el error para que no quede colgado al editar el formulario.
  void limpiarError() {
    if (state.error != null) {
      state = const EstadoAccion.inicial();
    }
  }
}
