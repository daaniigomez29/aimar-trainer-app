import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_baja_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/dialogos_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_detalle_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/tarjeta_ejercicio.dart';

/// Biblioteca de ejercicios.
///
/// Una sola pantalla para los dos roles: el entrenador ve las acciones de alta,
/// edicion y baja (CU-02 a CU-04); el cliente solo consulta (RF-04 del lado de
/// lectura). Quien manda de verdad es RLS: aunque se forzara la interfaz, el
/// `insert` de un cliente lo rechaza la politica.
class PantallaBiblioteca extends ConsumerWidget {
  const PantallaBiblioteca({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esEntrenador = ref.watch(rolActualProvider)?.esEntrenador ?? false;
    final ejercicios = ref.watch(ejerciciosFiltradosProvider);
    // Se observa, aunque no se use su valor aqui, para que el provider siga vivo
    // mientras esta pantalla lo esta: el flujo de baja de CU-04 pasa por dos
    // dialogos y, sin un oyente, Riverpod lo desecharia entre medias.
    ref.watch(controladorBajaEjercicioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de ejercicios'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(bibliotecaEjerciciosProvider),
          ),
        ],
      ),
      floatingActionButton: esEntrenador
          ? FloatingActionButton.extended(
              key: const Key('boton_nuevo_ejercicio'),
              onPressed: () => _abrirFormulario(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
      body: Column(
        children: [
          _Filtros(mostrarEliminados: esEntrenador),
          const Divider(height: 1),
          Expanded(
            child: ejercicios.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Mensaje(
                icono: Icons.error_outline,
                texto: mensajeDeError(error),
                accion: TextButton(
                  onPressed: () => ref.invalidate(bibliotecaEjerciciosProvider),
                  child: const Text('Reintentar'),
                ),
              ),
              data: (lista) => lista.isEmpty
                  ? _SinResultados(esEntrenador: esEntrenador)
                  : _Listado(ejercicios: lista, esEntrenador: esEntrenador),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _abrirFormulario(
  BuildContext context,
  WidgetRef ref, {
  Ejercicio? ejercicio,
}) async {
  // Se reinicia antes de abrir para que el formulario no arrastre el error ni el
  // "completada" de la vez anterior.
  ref.read(controladorFormularioEjercicioProvider.notifier).reiniciar();
  await Navigator.of(context).push<Ejercicio>(
    MaterialPageRoute(
      builder: (_) => PantallaFormularioEjercicio(ejercicio: ejercicio),
    ),
  );
}

class _Listado extends ConsumerWidget {
  const _Listado({required this.ejercicios, required this.esEntrenador});

  final List<Ejercicio> ejercicios;
  final bool esEntrenador;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    itemCount: ejercicios.length,
    itemBuilder: (context, indice) {
      final ejercicio = ejercicios[indice];
      return TarjetaEjercicio(
        key: Key('ejercicio_${ejercicio.id}'),
        ejercicio: ejercicio,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PantallaDetalleEjercicio(idEjercicio: ejercicio.id),
          ),
        ),
        acciones: esEntrenador
            ? [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _abrirFormulario(context, ref, ejercicio: ejercicio),
                ),
                if (ejercicio.estado.esActivo)
                  IconButton(
                    tooltip: 'Dar de baja',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => confirmarBajaEjercicio(
                      context: context,
                      ref: ref,
                      ejercicio: ejercicio,
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Reactivar',
                    icon: const Icon(Icons.restore_from_trash_outlined),
                    onPressed: () => reactivarEjercicio(
                      context: context,
                      ref: ref,
                      ejercicio: ejercicio,
                    ),
                  ),
              ]
            : const [],
      );
    },
  );
}

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.mostrarEliminados});

  final bool mostrarEliminados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroBibliotecaProvider);
    final controlador = ref.read(filtroBibliotecaProvider.notifier);
    final grupos = ref.watch(gruposMuscularesProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            key: const Key('campo_busqueda'),
            onChanged: controlador.cambiarTexto,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar',
              helperText: 'Por nombre, grupo muscular o equipamiento',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: filtro.tipo == null,
                  onSelected: (_) => controlador.cambiarTipo(null),
                ),
                for (final tipo in TipoEjercicio.values) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(tipo.etiqueta),
                    selected: filtro.tipo == tipo,
                    onSelected: (elegido) =>
                        controlador.cambiarTipo(elegido ? tipo : null),
                  ),
                ],
                if (grupos.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  DropdownButton<String?>(
                    value: filtro.grupoMuscular,
                    hint: const Text('Grupo muscular'),
                    onChanged: controlador.cambiarGrupoMuscular,
                    items: [
                      const DropdownMenuItem(child: Text('Todos')),
                      for (final grupo in grupos)
                        DropdownMenuItem(value: grupo, child: Text(grupo)),
                    ],
                  ),
                ],
                if (mostrarEliminados) ...[
                  const SizedBox(width: 16),
                  FilterChip(
                    label: const Text('Ver dados de baja'),
                    selected: filtro.incluirEliminados,
                    onSelected: (incluir) =>
                        controlador.alternarEliminados(incluir: incluir),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinResultados extends ConsumerWidget {
  const _SinResultados({required this.esEntrenador});

  final bool esEntrenador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroBibliotecaProvider);
    // Se distingue "la biblioteca esta vacia" de "el filtro no encuentra nada":
    // CU-08 preve ofrecer ir a CU-02 cuando la biblioteca esta vacia.
    if (!filtro.estaVacio) {
      return _Mensaje(
        icono: Icons.search_off,
        texto: 'Ningun ejercicio coincide con la busqueda.',
        accion: TextButton(
          onPressed: ref.read(filtroBibliotecaProvider.notifier).limpiar,
          child: const Text('Quitar filtros'),
        ),
      );
    }
    return _Mensaje(
      icono: Icons.fitness_center,
      texto: esEntrenador
          ? 'La biblioteca esta vacia. Anade el primer ejercicio.'
          : 'Tu entrenador todavia no ha anadido ejercicios.',
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto, this.accion});

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(texto, textAlign: TextAlign.center),
          if (accion != null) ...[const SizedBox(height: 8), accion!],
        ],
      ),
    ),
  );
}
