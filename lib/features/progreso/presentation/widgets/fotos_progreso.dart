import 'package:flutter/material.dart';
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
            'Guarda las medidas de este dia para poder anadirle fotos.',
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
                                SnackBar(content: Text(error.mensaje)),
                              );
                            }
                          },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined),
                        SizedBox(height: 6),
                        Text('Anadir foto', textAlign: TextAlign.center),
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
                data: (uri) => Image.network(uri.toString(), fit: BoxFit.cover),
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
