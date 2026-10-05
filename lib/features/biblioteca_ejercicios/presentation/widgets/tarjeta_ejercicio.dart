import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';

/// Fila del listado de la biblioteca (`docs/ui-design.md`, 6.4).
///
/// Miniatura, nombre, grupo muscular y tipo, mas el indicador de video. El
/// entrenador recibe ademas el lapiz de editar; al cliente le llega `null` y no
/// se pinta.
class TarjetaEjercicio extends ConsumerWidget {
  const TarjetaEjercicio({
    required this.ejercicio,
    this.onTap,
    this.onEditar,
    this.onDarDeBaja,
    this.onReactivar,
    super.key,
  });

  final Ejercicio ejercicio;
  final VoidCallback? onTap;

  /// Solo el entrenador los recibe; al cliente le llegan `null` y no se pintan.
  final VoidCallback? onEditar;
  final VoidCallback? onDarDeBaja;
  final VoidCallback? onReactivar;

  static const double ladoMiniatura = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final eliminado = ejercicio.estado.estaEliminado;

    return Tarjeta(
      key: Key('ejercicio_${ejercicio.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      hijo: Row(
        children: [
          MiniaturaEjercicio(
            ejercicio: ejercicio,
            lado: TarjetaEjercicio.ladoMiniatura,
            radio: Tokens.radioBoton,
            iconoDeVideo: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ejercicio.nombre,
                  style: textos.titleMedium?.copyWith(
                    decoration: eliminado ? TextDecoration.lineThrough : null,
                    color: eliminado ? Tokens.textoTenue : Tokens.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    ?ejercicio.grupoMuscular,
                    ejercicio.tipo.etiqueta,
                    if (eliminado) 'Dado de baja',
                  ].join(' • '),
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          if (onEditar != null && !eliminado)
            IconButton(
              key: Key('editar_${ejercicio.id}'),
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEditar,
            ),
          // CU-04 sigue arrancando aqui: el prototipo no lo muestra porque es la
          // biblioteca del cliente, que solo consulta.
          if (onDarDeBaja != null && !eliminado)
            IconButton(
              key: Key('eliminar_${ejercicio.id}'),
              tooltip: 'Dar de baja',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDarDeBaja,
            ),
          if (onReactivar != null && eliminado)
            IconButton(
              key: Key('reactivar_${ejercicio.id}'),
              tooltip: 'Reactivar',
              icon: const Icon(Icons.restore_from_trash_outlined, size: 18),
              onPressed: onReactivar,
            ),
          const Icon(Icons.chevron_right, size: 18, color: Tokens.textoTenue),
        ],
      ),
    );
  }
}

/// Se mantiene la etiqueta del tipo como pastilla para quien la necesite fuera
/// del listado (detalle, panel del entrenador).
class PastillaTipo extends StatelessWidget {
  const PastillaTipo({required this.ejercicio, super.key});

  final Ejercicio ejercicio;

  @override
  Widget build(BuildContext context) => Pastilla(
    texto: ejercicio.tipo.etiqueta,
    color: ejercicio.tipo.esFuerza ? Tokens.acento : Tokens.secundario,
  );
}
