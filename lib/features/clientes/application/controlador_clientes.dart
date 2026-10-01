import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';

part 'controlador_clientes.g.dart';

/// Fichas visibles para quien consulta, ordenadas por nombre.
///
/// Con RLS, el entrenador ve todas y el cliente solo la suya. El administrador no
/// ve ninguna: puede dar de alta y de baja (lo hace la Edge Function con
/// `service_role`), pero no consultar fichas.
@riverpod
Future<List<Cliente>> listaClientes(Ref ref) async {
  final resultado = await ref.watch(clienteRepositorioProvider).listar();
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Filtro del listado: texto y si se incluyen los dados de baja.
@riverpod
class FiltroClientes extends _$FiltroClientes {
  @override
  ({String texto, bool incluirBajas}) build() =>
      (texto: '', incluirBajas: false);

  void cambiarTexto(String texto) =>
      state = (texto: texto, incluirBajas: state.incluirBajas);

  void alternarBajas({required bool incluir}) =>
      state = (texto: state.texto, incluirBajas: incluir);

  void limpiar() => state = (texto: '', incluirBajas: false);
}

/// `true` si no hay ningun criterio aplicado. Fuera del Notifier porque su API
/// publica debe ser solo `state` y sus metodos (riverpod_lint:
/// avoid_public_notifier_properties).
bool filtroClientesVacio(({String texto, bool incluirBajas}) filtro) =>
    filtro.texto.trim().isEmpty && !filtro.incluirBajas;

/// Listado ya filtrado. Se filtra en memoria: con un solo entrenador, el numero
/// de clientes no justifica paginacion ni una consulta por cada tecla.
@riverpod
Future<List<Cliente>> clientesFiltrados(Ref ref) async {
  final todos = await ref.watch(listaClientesProvider.future);
  final filtro = ref.watch(filtroClientesProvider);
  final texto = filtro.texto.trim().toLowerCase();

  return todos.where((cliente) {
    if (!filtro.incluirBajas && !cliente.estado.esActivo) return false;
    if (texto.isEmpty) return true;
    return cliente.nombre.toLowerCase().contains(texto) ||
        cliente.correo.toLowerCase().contains(texto);
  }).toList();
}

/// Una ficha concreta, para el detalle. Se resuelve desde la lista ya cargada
/// cuando esta disponible, para no repetir la consulta.
@riverpod
Future<Cliente> clientePorId(Ref ref, String id) async {
  final cargados = ref.watch(listaClientesProvider);
  final enMemoria = cargados.value?.where((c) => c.id == id).firstOrNull;
  if (enMemoria != null) return enMemoria;

  final resultado = await ref
      .watch(clienteRepositorioProvider)
      .obtenerPorId(id);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Mensaje listo para mostrar a partir de lo que capture `AsyncValue`.
String mensajeDeErrorCliente(Object error) =>
    error is ErrorApp ? error.mensaje : const ErrorInesperado().mensaje;
