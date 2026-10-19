import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/packs/data/pack_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';

part 'controlador_packs.g.dart';

/// Todos los packs, con sus ejercicios. Solo los ve el entrenador: a cualquier
/// otro, RLS le devuelve una lista vacia.
@riverpod
Future<List<Pack>> listaPacks(Ref ref) async {
  final resultado = await ref.watch(packRepositorioProvider).listar();
  return switch (resultado) {
    Success(:final valor) => valor,
    // `AsyncValue` ya distingue error de dato; lanzar aqui es lo que espera
    // Riverpod, y la pantalla recibe el `ErrorApp` intacto.
    Failure(:final error) => throw error,
  };
}

/// Un pack concreto, con sus ejercicios y las series de cada uno.
@riverpod
Future<Pack> packCompleto(Ref ref, String packId) async {
  final resultado = await ref.watch(packRepositorioProvider).obtener(packId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Las escrituras de los packs (CU nuevo; ver `docs/requirements.md`).
///
/// Mismo patron que `ControladorPlanificacion`: un solo [EstadoAccion] para
/// toda la pantalla, y cada operacion recarga lo que haya cambiado.
@riverpod
class ControladorPacks extends _$ControladorPacks {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  Future<Result<Pack>> crear(DatosPack datos) {
    final error = datos.validar();
    if (error != null) return _conError(error);
    return _ejecutar(
      () => ref.read(packRepositorioProvider).crear(datos),
      recargarLista: true,
    );
  }

  Future<Result<Pack>> editar({required String id, required DatosPack datos}) {
    final error = datos.validar();
    if (error != null) return _conError(error);
    return _ejecutar(
      () => ref.read(packRepositorioProvider).editar(id: id, datos: datos),
      packARecargar: id,
      recargarLista: true,
    );
  }

  Future<Result<void>> eliminar(String id) => _ejecutar(
    () => ref.read(packRepositorioProvider).eliminar(id),
    recargarLista: true,
  );

  /// Crea o edita un ejercicio del pack con sus series, de una pieza.
  Future<Result<String>> guardarEjercicio({
    required DatosPackEjercicio datos,
    String? id,
  }) => _ejecutar(
    () => ref
        .read(packRepositorioProvider)
        .guardarEjercicio(datos: datos, id: id),
    packARecargar: datos.packId,
    recargarLista: true,
  );

  Future<Result<void>> eliminarEjercicio({
    required String id,
    required String packId,
  }) => _ejecutar(
    () => ref.read(packRepositorioProvider).eliminarEjercicio(id),
    packARecargar: packId,
    recargarLista: true,
  );

  Future<Result<void>> reordenarEjercicios({
    required String packId,
    required List<String> idsEnOrden,
  }) => _ejecutar(
    () => ref
        .read(packRepositorioProvider)
        .reordenarEjercicios(packId: packId, idsEnOrden: idsEnOrden),
    packARecargar: packId,
  );

  /// Copia el pack dentro de un bloque. No recarga ningun pack: lo que cambia
  /// es el planning, y de eso se encarga quien lo llama.
  Future<Result<ResultadoAplicarPack>> aplicarABloque({
    required String packId,
    required String bloqueId,
  }) => _ejecutar(
    () => ref
        .read(packRepositorioProvider)
        .aplicarABloque(packId: packId, bloqueId: bloqueId),
  );

  /// Un error de validacion no llega a tocar el repositorio, pero si tiene que
  /// quedar en el estado para que la pantalla lo pinte.
  Future<Result<T>> _conError<T>(ErrorApp error) async {
    state = EstadoAccion.conError(error);
    return Failure(error);
  }

  Future<Result<T>> _ejecutar<T>(
    Future<Result<T>> Function() operacion, {
    String? packARecargar,
    bool recargarLista = false,
  }) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una operación en curso.'));
    }
    state = const EstadoAccion.enCurso();
    final resultado = await operacion();

    // El provider puede haberse desechado durante la espera.
    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) {
        if (packARecargar != null) {
          ref.invalidate(packCompletoProvider(packARecargar));
        }
        if (recargarLista) ref.invalidate(listaPacksProvider);
      }
    }
    return resultado;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }

  void reiniciar() => state = const EstadoAccion.inicial();
}

/// Mensaje para la interfaz a partir de lo que lance un provider de packs.
String mensajeDeErrorPacks(Object error) =>
    error is ErrorApp ? error.mensaje : 'No se han podido cargar los packs.';
