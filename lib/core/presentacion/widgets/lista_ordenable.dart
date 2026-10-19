import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Lo que recibe quien reordena: `desde` y `hasta` **ya corregidos**, como
/// posiciones finales. Es el contrato que tenia `ListaArrastrable`, asi que las
/// funciones de Postgres que renumeran del 1 al N no cambian.
typedef AlMover = void Function(int desde, int hasta);

/// Columna cuyos elementos se mueven **con flechas**, no arrastrando.
///
/// POR QUE FLECHAS (decision del 2026-10-19): arrastrar obliga a mantener
/// pulsado, apuntar y soltar en el sitio justo, y en una lista larga dentro de
/// una pagina que ya se desplaza compite con el propio scroll. Dos botones
/// dicen exactamente lo que hacen y funcionan igual con el dedo que con el
/// raton.
///
/// Pone las flechas a la izquierda de cada elemento. Cuando el elemento quiere
/// colocarlas el (en el planning van dentro de la cabecera de cada bloque y de
/// cada ejercicio, para no comerse ancho en movil), se usa [FlechasDeOrden]
/// directamente.
class ListaOrdenable extends StatelessWidget {
  const ListaOrdenable({
    required this.elementos,
    required this.onMover,
    super.key,
  });

  /// Cada elemento con su contenido. El orden de la lista es el que se ve.
  final List<Widget> elementos;

  /// `null` cuando no se puede reordenar. Con un solo elemento tampoco hay
  /// nada que mover, y las flechas salen apagadas.
  final AlMover? onMover;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (indice, elemento) in elementos.indexed)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlechasDeOrden(
              indice: indice,
              total: elementos.length,
              onMover: onMover,
            ),
            Expanded(child: elemento),
          ],
        ),
    ],
  );
}

/// Las dos flechas de un elemento. La de subir se apaga en el primero y la de
/// bajar en el ultimo: asi el hueco no baila y se ve de un vistazo donde estas.
///
/// Sin permiso para mover ([onMover] `null`) se siguen pintando, apagadas: es
/// el mismo hueco en los dos casos, para que la fila no se descoloque segun
/// quien la mire.
class FlechasDeOrden extends StatelessWidget {
  const FlechasDeOrden({
    required this.indice,
    required this.total,
    required this.onMover,
    this.clave,
    this.compactas = false,
    super.key,
  });

  final int indice;
  final int total;
  final AlMover? onMover;

  /// Lo que distingue las claves de estas flechas (`subir_<clave>`,
  /// `bajar_<clave>`). Por defecto el indice, que basta con una sola lista;
  /// con varias en la misma pantalla (los bloques y los ejercicios de cada
  /// bloque) hace falta algo unico, como el id.
  final String? clave;

  /// Mas bajas, para caber en la cabecera de una fila sin estirarla.
  final bool compactas;

  @override
  Widget build(BuildContext context) {
    final puedeSubir = onMover != null && indice > 0;
    final puedeBajar = onMover != null && indice < total - 1;
    final sufijo = clave ?? '$indice';
    final alto = compactas ? 22.0 : 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Flecha(
          clave: Key('subir_$sufijo'),
          icono: Icons.keyboard_arrow_up,
          descripcion: 'Subir',
          alto: alto,
          onPulsar: puedeSubir ? () => onMover!(indice, indice - 1) : null,
        ),
        _Flecha(
          clave: Key('bajar_$sufijo'),
          icono: Icons.keyboard_arrow_down,
          descripcion: 'Bajar',
          alto: alto,
          onPulsar: puedeBajar ? () => onMover!(indice, indice + 1) : null,
        ),
      ],
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({
    required this.clave,
    required this.icono,
    required this.descripcion,
    required this.alto,
    required this.onPulsar,
  });

  final Key clave;
  final IconData icono;
  final String descripcion;
  final double alto;
  final VoidCallback? onPulsar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    height: alto,
    child: IconButton(
      key: clave,
      tooltip: descripcion,
      icon: Icon(icono, size: 20),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: Tokens.textoSuave,
      disabledColor: Tokens.superficie3,
      onPressed: onPulsar,
    ),
  );
}
