import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

part 'controlador_biblioteca.g.dart';

/// Biblioteca completa (activos y eliminados), ordenada por nombre.
///
/// Es la unica consulta al servidor del listado: el filtrado se aplica encima en
/// memoria. La lectura la permite RLS a cualquier usuario autenticado, asi que
/// este provider sirve igual al entrenador y al cliente.
@riverpod
Future<List<Ejercicio>> bibliotecaEjercicios(Ref ref) async {
  final resultado = await ref.watch(ejercicioRepositorioProvider).listar();
  return switch (resultado) {
    Success(:final valor) => valor,
    // `AsyncValue` ya distingue error de dato; lanzar aqui es lo que espera
    // Riverpod, y la pantalla recibe el ErrorApp intacto.
    Failure(:final error) => throw error,
  };
}

/// Filtro activo del listado (CU-21 usa el mismo patron para su rango de fechas).
@riverpod
class FiltroBiblioteca extends _$FiltroBiblioteca {
  @override
  FiltroEjercicios build() => const FiltroEjercicios();

  void cambiarTexto(String texto) => state = state.copiarCon(texto: texto);

  /// `null` quita el filtro por tipo. Se construye el filtro entero en lugar de
  /// usar `copiarCon`, porque ahi un `null` significaria "no cambiar".
  void cambiarTipo(TipoEjercicio? tipo) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: tipo,
    grupoMuscular: state.grupoMuscular,
    soloEliminados: state.soloEliminados,
  );

  /// `null` quita el filtro por grupo muscular.
  void cambiarGrupoMuscular(String? grupo) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: state.tipo,
    grupoMuscular: grupo,
    soloEliminados: state.soloEliminados,
  );

  void alternarEliminados({required bool solo}) =>
      state = state.copiarCon(soloEliminados: solo);

  void limpiar() => state = const FiltroEjercicios();
}

/// Listado ya filtrado que consume la pantalla.
@riverpod
Future<List<Ejercicio>> ejerciciosFiltrados(Ref ref) async {
  final todos = await ref.watch(bibliotecaEjerciciosProvider.future);
  final filtro = ref.watch(filtroBibliotecaProvider);
  return todos.where(filtro.aceptar).toList();
}

/// Grupos musculares presentes en la biblioteca, para ofrecerlos como filtro sin
/// mantener una lista fija en el codigo.
@riverpod
Future<List<String>> gruposMusculares(Ref ref) async {
  final todos = await ref.watch(bibliotecaEjerciciosProvider.future);
  final grupos = todos
      .where((e) => e.estado.esActivo)
      .map((e) => e.grupoMuscular)
      .whereType<String>()
      .where((g) => g.trim().isNotEmpty)
      .toSet()
      .toList();
  grupos.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return grupos;
}

/// Un ejercicio concreto, para la pantalla de detalle.
@riverpod
Future<Ejercicio> ejercicioPorId(Ref ref, String id) async {
  // Se resuelve desde la lista ya cargada cuando esta disponible, para no repetir
  // la consulta al abrir el detalle desde el listado.
  final cargados = ref.watch(bibliotecaEjerciciosProvider);
  final enMemoria = cargados.value?.where((e) => e.id == id).firstOrNull;
  if (enMemoria != null) return enMemoria;

  final resultado = await ref
      .watch(ejercicioRepositorioProvider)
      .obtenerPorId(id);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Mensaje de error listo para mostrar, a partir de lo que capture `AsyncValue`.
String mensajeDeError(Object error) =>
    error is ErrorApp ? error.mensaje : const ErrorInesperado().mensaje;
