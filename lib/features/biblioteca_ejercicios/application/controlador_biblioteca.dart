import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/facetas_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
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

/// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
/// biblioteca y el selector de ejercicios no se pisan la busqueda.
@riverpod
class FiltroBiblioteca extends _$FiltroBiblioteca {
  @override
  FiltroEjercicios build(AmbitoDeFiltro ambito) => const FiltroEjercicios();

  void cambiarTexto(String texto) => state = state.copiarCon(texto: texto);

  /// `null` quita el filtro por tipo. Se construye el filtro entero en lugar de
  /// usar `copiarCon`, porque ahi un `null` significaria "no cambiar".
  void cambiarTipo(TipoEjercicio? tipo) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: tipo,
    grupo: state.grupo,
    musculo: state.musculo,
    soloEliminados: state.soloEliminados,
    soloSinClasificar: state.soloSinClasificar,
  );

  /// `null` quita el filtro por grupo. Al cambiar de grupo se **suelta el
  /// musculo** elegido: era del grupo anterior y dejaria la lista vacia sin que
  /// se vea por que.
  void cambiarGrupo(GrupoMuscular? grupo) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: state.tipo,
    grupo: grupo,
    musculo: grupo != null && state.musculo?.grupo == grupo
        ? state.musculo
        : null,
    soloEliminados: state.soloEliminados,
  );

  /// Ver el grupo **entero**, soltando el musculo que hubiera.
  ///
  /// No vale `cambiarGrupo`, que conserva el musculo si es de ese mismo grupo:
  /// con cuadriceps elegido, pulsar "Todo pierna" no hacia nada visible, porque
  /// el musculo seguia puesto y el chip se quedaba sin marcar.
  void verTodoElGrupo(GrupoMuscular? grupo) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: state.tipo,
    grupo: grupo,
    soloEliminados: state.soloEliminados,
  );

  /// `null` quita el filtro por musculo y deja el del grupo. Elegir un musculo
  /// fija ademas su grupo: son dos niveles de lo mismo, no dos filtros sueltos.
  void cambiarMusculo(Musculo? musculo) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: state.tipo,
    grupo: musculo?.grupo ?? state.grupo,
    musculo: musculo,
    soloEliminados: state.soloEliminados,
  );

  /// Los sin clasificar son una pestana, asi que al entrar se suelta el filtro
  /// muscular: por definicion no tienen ninguno.
  void alternarSinClasificar({required bool solo}) => state = FiltroEjercicios(
    texto: state.texto,
    tipo: state.tipo,
    soloEliminados: state.soloEliminados,
    soloSinClasificar: solo,
  );

  void alternarEliminados({required bool solo}) =>
      state = state.copiarCon(soloEliminados: solo);

  void limpiar() => state = const FiltroEjercicios();
}

/// Listado ya filtrado y ordenado que consume la pantalla.
@riverpod
Future<List<Ejercicio>> ejerciciosFiltrados(
  Ref ref,
  AmbitoDeFiltro ambito,
) async {
  final todos = await ref.watch(bibliotecaEjerciciosProvider.future);
  final filtro = ref.watch(filtroBibliotecaProvider(ambito));
  return filtro.aplicar(todos);
}

/// Opciones de filtrado con algun ejercicio detras (ver [FacetasBiblioteca]).
///
/// Se calculan sobre los ejercicios del **estado** que se esta mirando (activos
/// o dados de baja), no sobre la biblioteca entera: en la pestana de bajas los
/// chips tienen que ser los de las bajas. Lo demas del filtro no influye: los
/// chips no se recortan segun lo que el buscador tenga escrito, o irian
/// desapareciendo mientras se teclea.
@riverpod
Future<FacetasBiblioteca> facetasBiblioteca(
  Ref ref,
  AmbitoDeFiltro ambito,
) async {
  final todos = await ref.watch(bibliotecaEjerciciosProvider.future);
  final soloEliminados = ref
      .watch(filtroBibliotecaProvider(ambito))
      .soloEliminados;

  final visibles = todos.where(
    (ejercicio) => soloEliminados == !ejercicio.estado.esActivo,
  );

  final porGrupo = <GrupoMuscular, int>{};
  final musculos = <Musculo>{};
  var haySinClasificar = false;

  for (final ejercicio in visibles) {
    for (final grupo in ejercicio.grupos) {
      porGrupo[grupo] = (porGrupo[grupo] ?? 0) + 1;
    }
    musculos.addAll(ejercicio.musculos);
    haySinClasificar = haySinClasificar || !ejercicio.estaClasificado;
  }

  return FacetasBiblioteca(
    ejerciciosPorGrupo: porGrupo,
    musculosConEjercicios: musculos,
    haySinClasificar: haySinClasificar,
  );
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
