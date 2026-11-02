import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

/// Fotos de un registro de medidas (entidad 9).
///
/// Cuelgan de un registro ya guardado (`fotos_progreso.registro_medidas_id`),
/// asi que mientras no haya medidas de ese dia no hay donde ponerlas.
class FotosProgreso extends ConsumerWidget {
  const FotosProgreso({
    required this.clienteId,
    required this.registro,
    required this.soloLectura,
    super.key,
  });

  final String clienteId;
  final RegistroMedidas? registro;
  final bool soloLectura;

  static const double lado = 110;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final actual = registro;
    final estado = ref.watch(controladorControlSemanalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos de progreso', style: textos.titleSmall),
        const SizedBox(height: 6),
        if (actual == null)
          Text(
            'Guarda las medidas de este día para poder añadirle fotos.',
            style: textos.bodySmall,
          )
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final foto in actual.fotos)
                _Miniatura(
                  foto: foto,
                  onEliminar: soloLectura
                      ? null
                      : () => ref
                            .read(controladorControlSemanalProvider.notifier)
                            .eliminarFoto(
                              clienteId: clienteId,
                              registro: actual,
                              foto: foto,
                            ),
                ),
              if (!soloLectura)
                SizedBox(
                  width: lado,
                  height: lado,
                  child: OutlinedButton(
                    key: const Key('boton_anadir_foto'),
                    onPressed: estado.enCurso
                        ? null
                        : () async {
                            final resultado = await ref
                                .read(
                                  controladorControlSemanalProvider.notifier,
                                )
                                .anadirFoto(
                                  clienteId: clienteId,
                                  registro: actual,
                                );
                            if (!context.mounted) return;
                            if (resultado.errorONulo case final error?) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: Avisos.duracion,
                                  content: Text(error.mensaje),
                                ),
                              );
                            }
                          },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined),
                        SizedBox(height: 6),
                        Text('Añadir foto', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Se guardan en privado: solo las veis tu y tu entrenador.',
            style: textos.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// La foto se pide con una URL firmada que caduca: el bucket es privado y no hay
/// enlace permanente que poner en un `Image.network`.
class _Miniatura extends ConsumerWidget {
  const _Miniatura({required this.foto, required this.onEliminar});

  final FotoProgreso foto;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(urlDeFotoProvider(foto));

    return SizedBox(
      width: FotosProgreso.lado,
      height: FotosProgreso.lado,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radioBoton),
            child: ColoredBox(
              color: Tokens.superficie3,
              child: url.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const Center(child: Icon(Icons.broken_image)),
                // Recortada al cuadrado para que la cuadricula quede pareja: en
                // una foto vertical se pierde casi todo, asi que se abre entera
                // al tocarla.
                data: (uri) => Semantics(
                  button: true,
                  label: 'Ver la foto a tamaño completo',
                  child: GestureDetector(
                    key: Key('ver_foto_${foto.id}'),
                    onTap: () => _abrirFoto(context, uri),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.zoomIn,
                      child: Image.network(
                        uri.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onEliminar != null)
            Align(
              alignment: Alignment.topRight,
              child: IconButton.filledTonal(
                key: Key('eliminar_foto_${foto.id}'),
                tooltip: 'Quitar foto',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16),
                onPressed: onEliminar,
              ),
            ),
        ],
      ),
    );
  }
}

/// La foto entera, sobre fondo negro y a pantalla completa. Se puede acercar:
/// pellizcando en el movil y con la rueda en el ordenador.
Future<void> _abrirFoto(BuildContext context, Uri uri) => showDialog<void>(
  context: context,
  builder: (contexto) => Dialog.fullscreen(
    backgroundColor: Colors.black,
    child: Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            uri.toString(),
            key: const Key('foto_completa'),
            fit: BoxFit.contain,
            loadingBuilder: (_, imagen, progreso) => progreso == null
                ? imagen
                : const Center(child: CircularProgressIndicator()),
            // El enlace firmado caduca: si lleva mucho rato abierta la pantalla,
            // volver a entrar pide uno nuevo.
            errorBuilder: (_, _, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No se ha podido cargar la foto. Sal de esta pantalla y '
                  'vuelve a entrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                key: const Key('cerrar_foto'),
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(contexto).pop(),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
