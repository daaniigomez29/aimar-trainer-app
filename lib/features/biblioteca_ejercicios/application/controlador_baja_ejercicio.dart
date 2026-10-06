import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';

part 'controlador_baja_ejercicio.g.dart';

/// CU-04: baja logica de un ejercicio, con el aviso previo de si esta en uso.
///
/// Los metodos devuelven el resultado en lugar de obligar a leer `state` despues:
/// el flujo de CU-04 pasa por dos dialogos, y entre ellos este provider puede
/// desecharse (es autoDispose). Quien lo llame debe usar el valor devuelto, no el
/// estado residual.
@riverpod
class ControladorBajaEjercicio extends _$ControladorBajaEjercicio {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  /// Cuantos plannings activos usan el ejercicio, para decidir si hace falta la
  /// confirmacion adicional de CU-04.
  ///
  /// Si la consulta falla se devuelve `null`: quien llama avisa de que no se ha
  /// podido comprobar, en lugar de dar por bueno que no esta en uso.
  Future<int?> comprobarUsos(String id) async {
    final resultado = await ref
        .read(ejercicioRepositorioProvider)
        .contarUsosEnPlanningsActivos(id);
    return switch (resultado) {
      Success(:final valor) => valor,
      Failure() => null,
    };
  }

  /// Ejecuta la baja logica.
  Future<Result<Ejercicio>> darDeBaja(String id) =>
      _ejecutar((repositorio) => repositorio.darDeBaja(id));

  /// Deshace una baja. La baja logica lo permite sin perder nada.
  Future<Result<Ejercicio>> reactivar(String id) =>
      _ejecutar((repositorio) => repositorio.reactivar(id));

  Future<Result<Ejercicio>> _ejecutar(
    Future<Result<Ejercicio>> Function(EjercicioRepositorio) operacion,
  ) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operación en curso.'));
    }
    state = const EstadoAccion.enCurso();
    final resultado = await operacion(ref.read(ejercicioRepositorioProvider));

    // El provider puede haberse desechado mientras se esperaba la respuesta:
    // tocar `state` o `ref` entonces lanza UnmountedRefException.
    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) {
        ref.invalidate(bibliotecaEjerciciosProvider);
      }
    }
    return resultado;
  }

  void limpiarError() {
    if (state.error != null) {
      state = const EstadoAccion.inicial();
    }
  }
}
