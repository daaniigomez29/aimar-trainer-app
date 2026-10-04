import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Columna cuyos elementos se pueden reordenar arrastrandolos (CU-11, CU-12).
///
/// Se usa dentro de otras columnas que ya scrollean, de ahi `shrinkWrap` y
/// `NeverScrollableScrollPhysics`: la lista no scrollea por su cuenta, solo
/// presta el arrastre.
///
/// `buildDefaultDragHandles: false` a proposito: con el asa automatica, toda la
/// fila arrastra y los botones de editar y eliminar dejan de responder bien en
/// tactil. El asa es [AsaDeArrastre], que cada elemento coloca donde le encaja.
class ListaArrastrable extends StatelessWidget {
  const ListaArrastrable({required this.hijos, this.onMover, super.key});

  /// Cada hijo necesita su propia `Key`, como pide `ReorderableListView`.
  final List<Widget> hijos;

  /// `null` cuando no se puede reordenar (el cliente, o un planning
  /// archivado). Con un solo elemento tampoco hay nada que mover.
  ///
  /// Recibe los indices de `onReorderItem`, que ya vienen corregidos: `hasta`
  /// es la posicion final, no la de antes de sacar el elemento.
  final void Function(int desde, int hasta)? onMover;

  @override
  Widget build(BuildContext context) {
    if (onMover == null || hijos.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hijos,
      );
    }

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      onReorderItem: onMover!,
      children: hijos,
    );
  }
}

/// El asa que inicia el arrastre. Fuera de una [ListaArrastrable] activa, se
/// pinta igual pero no hace nada: es el mismo hueco en los dos casos, para que
/// la fila no se descoloque segun quien la mire.
class AsaDeArrastre extends StatelessWidget {
  const AsaDeArrastre({
    required this.indice,
    this.activa = true,
    this.tamano = 16,
    super.key,
  });

  final int indice;
  final bool activa;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final icono = Icon(
      Icons.drag_indicator,
      size: tamano,
      color: activa ? Tokens.textoSuave : Tokens.textoTenue,
    );
    if (!activa) return icono;

    return ReorderableDragStartListener(
      index: indice,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Tooltip(message: 'Arrastra para mover', child: icono),
      ),
    );
  }
}
