import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/credenciales.dart';

part 'controlador_recuperacion.g.dart';

/// CU-24, primera mitad: solicitar el enlace de restablecimiento por correo.
///
/// Termina en `completada` incluso si el correo no esta registrado: el mensaje
/// que se muestra es generico para no revelar que cuentas existen.
@riverpod
class ControladorSolicitudRecuperacion
    extends _$ControladorSolicitudRecuperacion {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  Future<void> solicitarEnlace(String correo) async {
    if (state.enCurso) return;

    final errorValidacion = Credenciales.validarCorreo(correo);
    if (errorValidacion != null) {
      state = EstadoAccion.conError(errorValidacion);
      return;
    }

    state = const EstadoAccion.enCurso();
    final resultado = await ref
        .read(autenticacionRepositorioProvider)
        .enviarCorreoRecuperacion(correo.trim().toLowerCase());
    state = switch (resultado) {
      Success() => const EstadoAccion.completada(),
      Failure(:final error) => EstadoAccion.conError(error),
    };
  }

  void limpiarError() {
    if (state.error != null) {
      state = const EstadoAccion.inicial();
    }
  }
}

/// CU-24, segunda mitad: fijar la contrasena nueva sobre la sesion de
/// recuperacion que abre el enlace del correo.
@riverpod
class ControladorRestablecerContrasena
    extends _$ControladorRestablecerContrasena {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  Future<void> establecerContrasena({
    required String contrasena,
    required String repeticion,
  }) async {
    if (state.enCurso) return;

    final errorValidacion = Credenciales.validarContrasenaNueva(contrasena);
    if (errorValidacion != null) {
      state = EstadoAccion.conError(errorValidacion);
      return;
    }
    if (contrasena != repeticion) {
      state = const EstadoAccion.conError(
        ErrorValidacion('Las contraseñas no coinciden.', campo: 'repeticion'),
      );
      return;
    }

    state = const EstadoAccion.enCurso();
    final resultado = await ref
        .read(autenticacionRepositorioProvider)
        .establecerNuevaContrasena(contrasena);
    state = switch (resultado) {
      Success() => const EstadoAccion.completada(),
      Failure(:final error) => EstadoAccion.conError(error),
    };
  }

  void limpiarError() {
    if (state.error != null) {
      state = const EstadoAccion.inicial();
    }
  }
}
