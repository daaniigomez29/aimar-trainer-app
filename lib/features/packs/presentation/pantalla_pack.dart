import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/application/controlador_packs.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/presentation/dialogos_pack.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/lista_ordenable.dart';

/// La ficha de un pack: sus ejercicios, en orden, con lo que tengan preparado.
///
/// Se monta en dos pasos, como una sesion del planning: el pack se crea vacio y
/// aqui se le van anadiendo ejercicios. Un pack sin ninguno existe, pero no se
/// puede aplicar a un bloque, y la pantalla lo dice.
class PantallaPack extends ConsumerWidget {
  const PantallaPack({required this.packId, super.key});

  final String packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = ref.watch(packCompletoProvider(packId));
    ref.watch(controladorPacksProvider);

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.packs,
      appBar: AppBar(
        title: const Text('Pack'),
        actions: [
          if (pack.value case final actual?) ...[
            IconButton(
              key: const Key('boton_editar_pack'),
              tooltip: 'Editar el nombre',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  pedirDatosPack(context: context, ref: ref, pack: actual),
            ),
            IconButton(
              key: const Key('boton_eliminar_pack'),
              tooltip: 'Eliminar el pack',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final eliminado = await confirmarEliminarPack(
                  context: context,
                  ref: ref,
                  pack: actual,
                );
                if (eliminado && context.mounted) {
                  context.go(Rutas.packsEntrenador);
                }
              },
            ),
          ],
        ],
      ),
      cuerpo: pack.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mensajeDeErrorPacks(error), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(packCompletoProvider(packId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (datos) => _Contenido(pack: datos),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.pack});

  final Pack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = pack.ejerciciosOrdenados;

    return ListView(
      padding: const EdgeInsets.all(Tokens.margenPantalla),
      children: [
        Row(
          children: [
            Icon(pack.tipo.icono, size: 22, color: pack.tipo.color),
            const SizedBox(width: 10),
            Expanded(child: Text(pack.nombre, style: textos.headlineSmall)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          ejercicios.isEmpty
              ? 'Sin ejercicios. Añade el primero para poder usarlo.'
              : '${ejercicios.length} '
                    '${ejercicios.length == 1 ? 'ejercicio' : 'ejercicios'} · '
                    '${pack.tipo.etiqueta}',
          style: textos.bodySmall?.copyWith(
            color: ejercicios.isEmpty ? Tokens.secundario : null,
          ),
        ),
        const Divider(height: 28),
        ListaOrdenable(
          // Con uno solo no hay nada que mover; las flechas salen apagadas.
          onMover: ejercicios.length > 1
              ? (desde, hasta) => _mover(
                  ref: ref,
                  ejercicios: ejercicios,
                  desde: desde,
                  hasta: hasta,
                )
              : null,
          elementos: [
            for (final ejercicio in ejercicios)
              _FilaEjercicio(ejercicio: ejercicio, pack: pack),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('boton_anadir_al_pack'),
            onPressed: () => context.go(Rutas.nuevoEjercicioDelPack(pack.id)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir ejercicio'),
          ),
        ),
      ],
    );
  }

  /// Manda la lista **entera** en su orden nuevo: la funcion de Postgres
  /// renumera del 1 al N, no mueve uno suelto.
  Future<void> _mover({
    required WidgetRef ref,
    required List<PackEjercicio> ejercicios,
    required int desde,
    required int hasta,
  }) async {
    final ids = [for (final ejercicio in ejercicios) ejercicio.id];
    final movido = ids.removeAt(desde);
    ids.insert(hasta, movido);

    await ref
        .read(controladorPacksProvider.notifier)
        .reordenarEjercicios(packId: pack.id, idsEnOrden: ids);
  }
}

class _FilaEjercicio extends ConsumerWidget {
  const _FilaEjercicio({required this.ejercicio, required this.pack});

  final PackEjercicio ejercicio;
  final Pack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final ficha = ejercicio.ejercicio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tarjeta(
        key: Key('pack_ejercicio_${ejercicio.id}'),
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MiniaturaEjercicio(ejercicio: ficha, lado: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ficha?.nombre ?? 'Ejercicio',
                        style: textos.titleSmall,
                      ),
                      Text(_resumen(ejercicio), style: textos.bodySmall),
                    ],
                  ),
                ),
                if (ejercicio.estaDeBaja) ...[
                  // Sigue en el pack, pero al aplicarlo se queda fuera: un
                  // ejercicio de baja no se anade a bloques nuevos.
                  const Pastilla(texto: 'De baja', color: Tokens.secundario),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  key: Key('editar_del_pack_${ejercicio.id}'),
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context.go(
                    Rutas.editarEjercicioDelPack(pack.id, ejercicio.id),
                  ),
                ),
                IconButton(
                  key: Key('quitar_del_pack_${ejercicio.id}'),
                  tooltip: 'Quitar del pack',
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => confirmarQuitarDelPack(
                    context: context,
                    ref: ref,
                    ejercicio: ejercicio,
                    packId: pack.id,
                  ),
                ),
              ],
            ),
            if (ejercicio.series.isNotEmpty) ...[
              const Divider(height: 18),
              for (final serie in ejercicio.seriesOrdenadas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${serie.numeroSerie}. ${_serie(serie)}',
                    style: textos.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// La linea de debajo del nombre: lo que el entrenador dejo preparado, o que
  /// no dejo nada, que tambien es valido en un pack.
  static String _resumen(PackEjercicio ejercicio) {
    if (ejercicio.minutos case final minutos?) {
      return '${_numero(minutos)} min';
    }
    if (ejercicio.series.isEmpty) {
      return 'Sin nada preparado · se rellena al planificar';
    }
    final cuantas = ejercicio.series.length;
    final descanso = ejercicio.descansoSeg;
    return [
      '$cuantas ${cuantas == 1 ? 'serie' : 'series'}',
      if (descanso != null) 'descanso ${descanso}s',
    ].join(' · ');
  }

  static String _serie(PackSerie serie) => [
    if (serie.peso case final peso?) '${_numero(peso)} kg',
    '${serie.repeticiones} reps',
    if (serie.rir case final rir?) 'RIR $rir',
  ].join(' · ');
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);
