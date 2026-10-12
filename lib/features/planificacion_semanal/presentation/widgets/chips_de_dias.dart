import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Tira horizontal de los dias de la semana: Día 1, Día 2...
///
/// La comparten el editor del entrenador y la vista de resultados. Son la misma
/// cosa —elegir de que dia se habla— y tenerla dos veces garantizaba que una se
/// quedara atras.
///
/// No se usa en la pantalla de entrada del cliente a proposito: alli la tira
/// lleva su propio diseno, con el punto de "hecha" en cada dia.
class ChipsDeDias extends StatelessWidget {
  const ChipsDeDias({
    required this.sesiones,
    required this.elegida,
    required this.onElegir,
    this.alFinal,
    super.key,
  });

  final List<SesionEntrenamiento> sesiones;

  /// Orden del dia marcado, o `null` si no hay ninguno.
  final int? elegida;
  final ValueChanged<int> onElegir;

  /// Lo que va detras del ultimo dia, si hace falta: el editor pone ahi su
  /// boton de anadir dia.
  final Widget? alFinal;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: sesiones.length + (alFinal == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, indice) {
        if (indice == sesiones.length) return alFinal!;

        final sesion = sesiones[indice];
        return ChipFiltro(
          key: Key('dia_${sesion.orden}'),
          etiqueta: 'Día ${sesion.orden}',
          activo: sesion.orden == elegida,
          onPulsar: () => onElegir(sesion.orden),
        );
      },
    ),
  );
}
