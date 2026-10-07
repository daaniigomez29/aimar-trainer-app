import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

import 'package:aimar_trainer_app/core/plataforma/reproductor_video.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_baja_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/video_ejemplo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/dialogos_ejercicio.dart';

/// Ficha de un ejercicio. La ven los dos roles; el entrenador ademas puede
/// editar y dar de baja desde aqui.
class PantallaDetalleEjercicio extends ConsumerWidget {
  const PantallaDetalleEjercicio({required this.idEjercicio, super.key});

  final String idEjercicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esEntrenador = ref.watch(rolActualProvider)?.esEntrenador ?? false;
    final ejercicio = ref.watch(ejercicioPorIdProvider(idEjercicio));
    // Igual que en el listado: mantiene vivo el controlador durante el flujo de
    // baja, que pasa por dialogos.
    ref.watch(controladorBajaEjercicioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicio'),
        actions: [
          if (esEntrenador && ejercicio.value != null)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                ref
                    .read(controladorFormularioEjercicioProvider.notifier)
                    .reiniciar();
                context.go(Rutas.editarEjercicio(idEjercicio));
              },
            ),
        ],
      ),
      body: ejercicio.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(mensajeDeError(error), textAlign: TextAlign.center),
          ),
        ),
        data: (datos) =>
            _Contenido(ejercicio: datos, esEntrenador: esEntrenador),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.ejercicio, required this.esEntrenador});

  final Ejercicio ejercicio;
  final bool esEntrenador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (ejercicio.imagenRuta case final ruta?) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ref.read(ejercicioRepositorioProvider).urlPublicaDeImagen(ruta),
              height: 260,
              width: double.infinity,
              // `contain` y no `cover`: una ilustracion de tecnica recortada
              // puede dejar fuera justo la parte que importa.
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(ejercicio.nombre, style: textos.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              avatar: Icon(
                ejercicio.tipo.esFuerza
                    ? Icons.fitness_center
                    : Icons.directions_run,
                size: 18,
              ),
              label: Text(ejercicio.tipo.etiqueta),
            ),
            if (ejercicio.estado.estaEliminado)
              const Chip(
                avatar: Icon(Icons.block, size: 18),
                label: Text('Dado de baja'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(ejercicio.tipo.descripcionPlanificacion, style: textos.bodySmall),
        const Divider(height: 32),
        if (ejercicio.grupoMuscular case final grupo?)
          _Dato(etiqueta: 'Grupo muscular', valor: grupo),
        if (ejercicio.equipamiento case final equipo?)
          _Dato(etiqueta: 'Equipamiento', valor: equipo),
        const SizedBox(height: 8),
        Text('Cómo se ejecuta', style: textos.titleMedium),
        const SizedBox(height: 8),
        Text(ejercicio.descripcion),
        if (ejercicio.videoEjemploUrl case final url?) ...[
          const Divider(height: 32),
          Text('Vídeo de ejemplo', style: textos.titleMedium),
          const SizedBox(height: 8),
          _Video(url: url),
        ],
        if (esEntrenador) ...[
          const Divider(height: 32),
          if (ejercicio.estado.esActivo)
            OutlinedButton.icon(
              onPressed: () async {
                await confirmarBajaEjercicio(
                  context: context,
                  ref: ref,
                  ejercicio: ejercicio,
                );
                if (context.mounted) Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Dar de baja'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => reactivarEjercicio(
                context: context,
                ref: ref,
                ejercicio: ejercicio,
              ),
              icon: const Icon(Icons.restore_from_trash_outlined),
              label: const Text('Reactivar'),
            ),
        ],
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(valor)),
      ],
    ),
  );
}

/// Muestra el enlace del video y permite copiarlo.
///
/// No se abre directamente ni se incrusta un reproductor: abrir URLs externas
/// necesitaria `url_launcher`, una dependencia nueva que hay que acordar antes
/// (AGENTS.md). Copiar al portapapeles resuelve el caso sin anadirla.
/// El video de ejemplo, reproducido dentro de la app cuando se puede.
///
/// Los videos del entrenador son shorts de YouTube, que se incrustan con su
/// propio reproductor: el cliente los ve sin salir de la ficha. Si el enlace no
/// es de YouTube (o no hay navegador detras, como en los tests) se cae al enlace
/// copiable de siempre, que sigue funcionando.
class _Video extends StatelessWidget {
  const _Video({required this.url});

  final String url;

  /// Ancho maximo del reproductor. Un short es vertical: a pantalla completa en
  /// un portatil quedaria una columna de video absurdamente alta.
  static const double anchoMaximo = 250;

  @override
  Widget build(BuildContext context) {
    final incrustada = VideoEjemplo.urlIncrustada(url);
    if (incrustada == null || !ReproductorVideo.estaSoportado) {
      return _EnlaceVideo(url: url);
    }

    // Solo el reproductor: el enlace en crudo no aporta nada cuando el video se
    // ve aqui mismo, y ensuciaba la ficha. Sigue estando [_EnlaceVideo] para
    // cuando no se puede incrustar, que es el caso en que si hace falta.
    // El `Align` no es decorativo: el padre da un ancho fijo, y sin el la
    // restriccion de [anchoMaximo] no se aplicaria y el video saldria a toda la
    // pantalla.
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximo),
        child: ReproductorVideo(url: incrustada),
      ),
    );
  }
}

class _EnlaceVideo extends StatelessWidget {
  const _EnlaceVideo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SelectableText(
          url,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      IconButton(
        tooltip: 'Copiar enlace',
        icon: const Icon(Icons.copy_all_outlined),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: url));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Avisos.duracion,
              content: Text('Enlace copiado.'),
            ),
          );
        },
      ),
    ],
  );
}
