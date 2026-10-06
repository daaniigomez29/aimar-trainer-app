import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';

part 'controlador_registro_sesion.g.dart';

/// Registro del resultado de una sesion (CU-20).
///
/// Cada metodo devuelve su `Result` ademas de dejarlo en el estado, por la leccion
/// de CU-04: con dialogos de por medio un provider autoDispose puede desecharse
/// antes de que llegue la respuesta.
///
/// Tras guardar se invalida `planningCompletoProvider`, porque los triggers habran
/// cambiado `estado_registro` del ejercicio y puede que `resultado_registrado` de
/// la sesion: lo que la pantalla tiene en memoria se queda viejo.
@riverpod
class ControladorRegistroSesion extends _$ControladorRegistroSesion {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  /// Guarda las series de un ejercicio de Fuerza.
  ///
  /// Se envia la lista completa de series confirmadas, no solo la ultima: asi la
  /// llamada es idempotente y una serie corregida se actualiza en su sitio.
  Future<Result<void>> registrarFuerza({
    required String ejercicioPlanificadoId,
    required List<DatosSerieRealizada> series,
    required String planningId,
  }) => _ejecutar(
    DatosResultadoEjercicio.fuerza(
      ejercicioPlanificadoId: ejercicioPlanificadoId,
      series: series,
    ),
    planningId,
  );

  Future<Result<void>> registrarCardio({
    required String ejercicioPlanificadoId,
    required double? minutos,
    required String planningId,
  }) {
    // El constructor de cardio no admite `null`, asi que el caso de "no has
    // puesto los minutos" se resuelve antes de construir los datos.
    final error = DatosResultadoEjercicio.validarMinutos(minutos);
    if (error != null) return _fallar(error);

    return _ejecutar(
      DatosResultadoEjercicio.cardio(
        ejercicioPlanificadoId: ejercicioPlanificadoId,
        minutos: minutos!,
      ),
      planningId,
    );
  }

  Future<Result<void>> _ejecutar(
    DatosResultadoEjercicio datos,
    String planningId,
  ) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operación en curso.'));
    }

    final invalido = datos.validar();
    if (invalido != null) return _fallar(invalido);

    state = const EstadoAccion.enCurso();
    final resultado = await ref
        .read(progresoRepositorioProvider)
        .registrarResultado(datos);

    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) {
        ref.invalidate(planningCompletoProvider(planningId));
      }
    }
    return resultado;
  }

  Future<Result<void>> _fallar(ErrorApp error) async {
    if (ref.mounted) state = EstadoAccion.conError(error);
    return Failure(error);
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }
}
