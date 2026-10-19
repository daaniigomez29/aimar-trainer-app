import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/application/controlador_packs.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/presentation/dialogos_pack.dart';

/// Los packs del entrenador (RF-25).
///
/// Un pack es una plantilla: un puñado de ejercicios con sus series o sus
/// minutos ya preparados, para no montar lo mismo cada semana. Solo los ve el
/// entrenador; a cualquier otro RLS le devuelve una lista vacia.
class PantallaPacks extends ConsumerWidget {
  const PantallaPacks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(listaPacksProvider);
    ref.watch(controladorPacksProvider);

    return PantallaEntrenador(
      rutaActual: Rutas.packsEntrenador,
      cuerpo: packs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Aviso(
          mensaje: mensajeDeErrorPacks(error),
          onReintentar: () => ref.invalidate(listaPacksProvider),
        ),
        data: (lista) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(listaPacksProvider),
          child: ListView(
            padding: const EdgeInsets.all(Tokens.margenPantalla),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Packs',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('boton_nuevo_pack'),
                    onPressed: () async {
                      final creado = await pedirDatosPack(
                        context: context,
                        ref: ref,
                      );
                      // Se abre el pack recien creado: se crea para meterle
                      // ejercicios, no para mirarlo en la lista.
                      if (creado != null && context.mounted) {
                        context.go(Rutas.packConcreto(creado.id));
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo pack'),
                    // El tema da a los `FilledButton` ancho minimo infinito
                    // (son los CTA de ancho completo); dentro de una `Row`, que
                    // no acota el ancho, eso revienta el layout entero.
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Plantillas de ejercicios para montar una sesión de una vez.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              if (lista.isEmpty)
                const _SinPacks()
              else
                for (final pack in lista) ...[
                  _FilaPack(pack: pack),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaPack extends StatelessWidget {
  const _FilaPack({required this.pack});

  final Pack pack;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cuantos = pack.ejercicios.length;

    return Tarjeta(
      key: Key('pack_${pack.id}'),
      onTap: () => context.go(Rutas.packConcreto(pack.id)),
      hijo: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: pack.tipo.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(pack.tipo.icono, size: 20, color: pack.tipo.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.nombre, style: textos.titleMedium),
                const SizedBox(height: 2),
                Text(
                  cuantos == 0
                      // Un pack vacio no se puede aplicar a ningun bloque, asi
                      // que mas vale decirlo aqui que al intentarlo.
                      ? 'Sin ejercicios · no se puede aplicar'
                      : '$cuantos ${cuantos == 1 ? 'ejercicio' : 'ejercicios'} '
                            '· ${pack.tipo.etiqueta}',
                  style: textos.bodySmall?.copyWith(
                    color: cuantos == 0 ? Tokens.secundario : null,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Tokens.textoTenue),
        ],
      ),
    );
  }
}

class _SinPacks extends StatelessWidget {
  const _SinPacks();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Todavía no hay packs', style: textos.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Un pack guarda un grupo de ejercicios con sus series ya puestas. '
            'Después se añade entero a un bloque, en un toque.',
            style: textos.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
