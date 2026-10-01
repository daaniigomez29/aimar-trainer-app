import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';

part 'controlador_formulario_ejercicio.g.dart';

/// CU-02 (anadir) y CU-03 (editar) ejercicio.
///
/// Un solo controlador para los dos casos porque el formulario y las
/// validaciones son identicos; lo unico que cambia es si hay `id` previo.
@riverpod
class ControladorFormularioEjercicio extends _$ControladorFormularioEjercicio {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  /// Guarda el ejercicio. Con `id` a `null` crea (CU-02); con `id` edita (CU-03).
  ///
  /// Devuelve el ejercicio guardado, o `null` si hubo error (el motivo queda en
  /// `state.error`), para que la pantalla sepa si puede cerrarse.
  Future<Ejercicio?> guardar({
    required DatosEjercicio datos,
    String? id,
  }) async {
    if (state.enCurso) return null;

    // Validacion de dominio antes de salir a la red: el nombre duplicado no se
    // puede saber aqui, pero el resto si (CU-02, excepcion "datos incompletos").
    final errorValidacion = datos.validar();
    if (errorValidacion != null) {
      state = EstadoAccion.conError(errorValidacion);
      return null;
    }

    state = const EstadoAccion.enCurso();
    final repositorio = ref.read(ejercicioRepositorioProvider);
    final resultado = id == null
        ? await repositorio.crear(datos)
        : await repositorio.editar(id: id, datos: datos);

    switch (resultado) {
      case Success(:final valor):
        state = const EstadoAccion.completada();
        // El listado se recarga para que el nuevo ejercicio aparezca sin que la
        // pantalla tenga que enterarse.
        ref.invalidate(bibliotecaEjerciciosProvider);
        return valor;
      case Failure(:final error):
        state = EstadoAccion.conError(error);
        return null;
    }
  }

  void limpiarError() {
    if (state.error != null) {
      state = const EstadoAccion.inicial();
    }
  }

  /// Vuelve al estado inicial al abrir el formulario de nuevo.
  void reiniciar() => state = const EstadoAccion.inicial();
}
