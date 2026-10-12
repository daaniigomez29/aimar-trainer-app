import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/lista_arrastrable.dart';

/// POR QUE ESTE TEST: el arrastre tiene dos formas de fallar en silencio. Una,
/// que el asa aparezca donde no debe o quede viva cuando no hay nada que mover.
/// Otra, que al soltar lleguen indices que dejan el elemento en el sitio
/// equivocado, que es justo lo que no se ve mirando la pantalla quieta.
///
/// Se prueba sobre [ListaArrastrable] y no a traves de una pantalla: es el
/// widget que presta el arrastre a los bloques y a los ejercicios (CU-11,
/// CU-12), y asi el test no se cae cada vez que cambia la pantalla que lo usa.
/// Antes colgaba de `TarjetaSesion`, que desaparecio al separar la vista de
/// resultados de la de planificacion.
void main() {
  Future<List<(int, int)>> montar(
    WidgetTester tester, {
    required bool sePuedeMover,
    int cuantos = 3,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final movimientos = <(int, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListaArrastrable(
              onMover: !sePuedeMover
                  ? null
                  : (desde, hasta) => movimientos.add((desde, hasta)),
              hijos: [
                for (var i = 0; i < cuantos; i++)
                  SizedBox(
                    key: Key('fila_$i'),
                    height: 80,
                    child: Row(
                      children: [
                        AsaDeArrastre(indice: i, activa: sePuedeMover),
                        Text('Fila $i'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return movimientos;
  }

  testWidgets('con varios elementos hay un asa por fila', (tester) async {
    await montar(tester, sePuedeMover: true);

    expect(find.byType(AsaDeArrastre), findsNWidgets(3));
    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  testWidgets('sin permiso para mover no se ofrece reordenar', (tester) async {
    await montar(tester, sePuedeMover: false);

    // El asa sigue pintandose, para que la fila no baile segun quien la mire,
    // pero inerte y sin lista reordenable debajo.
    expect(find.byType(ReorderableListView), findsNothing);
    expect(
      tester
          .widgetList<AsaDeArrastre>(find.byType(AsaDeArrastre))
          .every((asa) => !asa.activa),
      isTrue,
    );
  });

  testWidgets('con un solo elemento tampoco: no hay nada que mover', (
    tester,
  ) async {
    await montar(tester, sePuedeMover: true, cuantos: 1);

    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('arrastrar el primero hacia abajo lo manda al segundo', (
    tester,
  ) async {
    final movimientos = await montar(tester, sePuedeMover: true);

    final alto = tester.getSize(find.byKey(const Key('fila_0'))).height;
    await tester.timedDrag(
      find.byType(AsaDeArrastre).first,
      Offset(0, alto),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    // Con `onReorderItem`, el destino ya viene corregido: el elemento 0 pasa a
    // ocupar la posicion 1, no la 2.
    expect(movimientos, [(0, 1)]);
  });
}
