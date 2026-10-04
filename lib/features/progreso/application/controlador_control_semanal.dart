import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes_flutter.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

part 'controlador_control_semanal.g.dart';

/// Medidas de un dia concreto, o `null` si ese dia no tiene registro.
@riverpod
Future<RegistroMedidas?> medidasDelDia(
  Ref ref,
  String clienteId,
  DateTime fecha,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .medidasDelDia(clienteId: clienteId, fecha: fecha);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Check-in de un dia concreto, o `null`.
@riverpod
Future<CheckinRecuperacion?> checkinDelDia(
  Ref ref,
  String clienteId,
  DateTime fecha,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .checkinDelDia(clienteId: clienteId, fecha: fecha);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Historico de medidas, de lo mas reciente a lo mas antiguo.
@riverpod
Future<List<RegistroMedidas>> historialMedidas(
  Ref ref,
  String clienteId,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .listarMedidas(clienteId: clienteId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Historico de check-in.
@riverpod
Future<List<CheckinRecuperacion>> historialCheckins(
  Ref ref,
  String clienteId,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .listarCheckins(clienteId: clienteId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// URL firmada para mostrar una foto. Caduca, asi que el provider se vuelve a
/// pedir cada vez que la pantalla se reconstruye de cero.
@riverpod
Future<Uri> urlDeFoto(Ref ref, FotoProgreso foto) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .urlFirmadaDe(foto);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Escrituras del control semanal: medidas, check-in y fotos.
///
/// Medidas y check-in son **dos operaciones independientes**, sin transaccion que
/// las una: se muestran juntas porque se rellenan el mismo dia, pero si el cliente
/// solo completa una, esa se guarda. Es la decision del modelo de dominio
/// (entidad 10), no una limitacion.
@riverpod
class ControladorControlSemanal extends _$ControladorControlSemanal {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  Future<Result<RegistroMedidas>> guardarMedidas(DatosRegistroMedidas datos) =>
      _ejecutar(
        () async {
          final error = datos.validar();
          if (error != null) return Failure(error);
          return ref.read(progresoRepositorioProvider).guardarMedidas(datos);
        },
        clienteId: datos.clienteId,
        fecha: datos.fecha,
      );

  Future<Result<CheckinRecuperacion>> guardarCheckin(DatosCheckin datos) =>
      _ejecutar(
        () async {
          final error = datos.validar();
          if (error != null) return Failure(error);
          return ref.read(progresoRepositorioProvider).guardarCheckin(datos);
        },
        clienteId: datos.clienteId,
        fecha: datos.fecha,
      );

  /// Abre el selector, convierte la imagen y la sube.
  ///
  /// Devuelve `null` dentro de un `Success` si el usuario cerro el selector sin
  /// elegir nada.
  Future<Result<FotoProgreso?>> anadirFoto({
    required String clienteId,
    required RegistroMedidas registro,
  }) => _ejecutar(
    () async {
      final elegida = await ref.read(servicioImagenesProvider).elegirFoto();
      switch (elegida) {
        case Failure(:final error):
          return Failure<FotoProgreso?>(error);
        case Success(:final valor):
          // Cancelar el selector no es un error: no hay nada que subir.
          if (valor == null) return const Success<FotoProgreso?>(null);
          final subida = await ref
              .read(progresoRepositorioProvider)
              .subirFoto(
                clienteId: clienteId,
                registroMedidasId: registro.id,
                imagen: valor,
              );
          return subida.map<FotoProgreso?>((foto) => foto);
      }
    },
    clienteId: clienteId,
    fecha: registro.fecha,
  );

  Future<Result<void>> eliminarFoto({
    required String clienteId,
    required RegistroMedidas registro,
    required FotoProgreso foto,
  }) => _ejecutar(
    () => ref.read(progresoRepositorioProvider).eliminarFoto(foto),
    clienteId: clienteId,
    fecha: registro.fecha,
  );

  Future<Result<T>> _ejecutar<T>(
    Future<Result<T>> Function() operacion, {
    required String clienteId,
    required DateTime fecha,
  }) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operacion en curso.'));
    }
    state = const EstadoAccion.enCurso();
    final resultado = await operacion();

    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) {
        ref
          ..invalidate(medidasDelDiaProvider(clienteId, fecha))
          ..invalidate(checkinDelDiaProvider(clienteId, fecha))
          ..invalidate(historialMedidasProvider(clienteId))
          ..invalidate(historialCheckinsProvider(clienteId));
      }
    }
    return resultado;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }
}
