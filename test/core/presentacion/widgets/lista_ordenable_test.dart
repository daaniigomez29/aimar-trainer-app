import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/lista_ordenable.dart';

/// POR QUE ESTE TEST: los índices que salen de aquí van a una función de
/// Postgres que renumera del 1 al N, así que un desde/hasta mal calculado deja
/// el elemento en el sitio equivocado **y se guarda**. Es el mismo contrato que
/// tenía `ListaArrastrable`, que ya tenía su test por el mismo motivo.
void main() {
  Future<List<(int, int)>> montar(
    WidgetTester tester, {
    required bool sePuedeMover,
    int cuantos = 3,
  }) async {
    final movimientos = <(int, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaOrdenable(
            onMover: !sePuedeMover
                ? null
                : (desde, hasta) => movimientos.add((desde, hasta)),
            elementos: [for (var i = 0; i < cuantos; i++) Text('Fila $i')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return movimientos;
  }

  bool activa(WidgetTester tester, String clave) =>
      tester.widget<IconButton>(find.byKey(Key(clave))).onPressed != null;

  testWidgets('el primero no sube y el último no baja', (tester) async {
    await montar(tester, sePuedeMover: true);

    expect(activa(tester, 'subir_0'), isFalse);
    expect(activa(tester, 'bajar_0'), isTrue);
    expect(activa(tester, 'subir_2'), isTrue);
    expect(activa(tester, 'bajar_2'), isFalse);
  });

  testWidgets('sin permiso para mover, todas apagadas', (tester) async {
    await montar(tester, sePuedeMover: false);

    // Las flechas se siguen pintando para que la fila no baile según quién
    // mire, pero no hacen nada.
    expect(activa(tester, 'bajar_0'), isFalse);
    expect(activa(tester, 'subir_1'), isFalse);
  });

  testWidgets('con un solo elemento no hay nada que mover', (tester) async {
    await montar(tester, sePuedeMover: true, cuantos: 1);

    expect(activa(tester, 'subir_0'), isFalse);
    expect(activa(tester, 'bajar_0'), isFalse);
  });

  testWidgets('bajar el primero manda (0, 1)', (tester) async {
    final movimientos = await montar(tester, sePuedeMover: true);

    await tester.tap(find.byKey(const Key('bajar_0')));
    await tester.pumpAndSettle();

    expect(movimientos, [(0, 1)]);
  });

  testWidgets('subir el último manda (2, 1)', (tester) async {
    final movimientos = await montar(tester, sePuedeMover: true);

    await tester.tap(find.byKey(const Key('subir_2')));
    await tester.pumpAndSettle();

    expect(movimientos, [(2, 1)]);
  });
}
