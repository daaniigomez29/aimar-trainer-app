import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/lista_arrastrable.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/tarjeta_sesion.dart';

import '../ayudas_planificacion.dart';

/// POR QUE ESTE TEST: el arrastre tiene dos formas de fallar en silencio. Una,
/// que el asa aparezca donde no debe (el cliente no reordena el trabajo que le
/// han puesto). Otra, que al soltar lleguen indices que dejan el elemento en el
/// sitio equivocado, que es justo lo que no se ve mirando la pantalla quieta.
void main() {
  final bloque1 = bloqueDePrueba(
    id: 'b-1',
    orden: 1,
    tipo: TipoBloque.calentamiento,
    ejercicios: [
      ejercicioPlanificadoDePrueba(id: 'ep-1', orden: 1),
      ejercicioPlanificadoDePrueba(id: 'ep-2', orden: 2),
    ],
  );
  final bloque2 = bloqueDePrueba(id: 'b-2', orden: 2, tipo: TipoBloque.fuerza);
  final sesion = sesionDePrueba(bloques: [bloque1, bloque2]);
  final planning = planningDePrueba(sesiones: [sesion]);

  Future<List<(int, int)>> montar(
    WidgetTester tester, {
    required bool puedeEditar,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final movimientos = <(int, int)>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TarjetaSesion(
                sesion: sesion,
                planning: planning,
                puedeEditar: puedeEditar,
                onAnadirBloque: () {},
                onEditarSesion: () {},
                onEliminarSesion: () {},
                onEditarBloque: (_) {},
                onEliminarBloque: (_) {},
                onAnadirEjercicio: (_) {},
                onEditarEjercicio: (_, _) {},
                onEliminarEjercicio: (_) {},
                onMoverBloque: !puedeEditar
                    ? null
                    : (desde, hasta) => movimientos.add((desde, hasta)),
                onMoverEjercicio: !puedeEditar
                    ? null
                    : (_, desde, hasta) => movimientos.add((desde, hasta)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return movimientos;
  }

  testWidgets('el entrenador ve un asa por bloque y por ejercicio', (
    tester,
  ) async {
    await montar(tester, puedeEditar: true);

    // Dos bloques y dos ejercicios dentro del primero.
    expect(find.byType(AsaDeArrastre), findsNWidgets(4));
    expect(find.byType(ReorderableListView), findsNWidgets(2));
  });

  testWidgets('al cliente no se le ofrece reordenar', (tester) async {
    await montar(tester, puedeEditar: false);

    expect(find.byType(AsaDeArrastre), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('arrastrar el primer bloque hacia abajo lo manda al segundo', (
    tester,
  ) async {
    final movimientos = await montar(tester, puedeEditar: true);

    final asa = find.byType(AsaDeArrastre).first;
    final alto = tester.getSize(find.byKey(const Key('bloque_b-1'))).height;
    await tester.timedDrag(
      asa,
      Offset(0, alto),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    // Con `onReorderItem`, el destino ya viene corregido: el bloque 0 pasa a
    // ocupar la posicion 1, no la 2.
    expect(movimientos, [(0, 1)]);
  });

  testWidgets('un bloque con un solo ejercicio no ofrece arrastrarlo', (
    tester,
  ) async {
    final soloUno = sesionDePrueba(
      bloques: [
        bloqueDePrueba(
          ejercicios: [ejercicioPlanificadoDePrueba(id: 'ep-1', orden: 1)],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TarjetaSesion(
              sesion: soloUno,
              planning: planningDePrueba(sesiones: [soloUno]),
              puedeEditar: true,
              onAnadirBloque: () {},
              onEditarSesion: () {},
              onEliminarSesion: () {},
              onEditarBloque: (_) {},
              onEliminarBloque: (_) {},
              onAnadirEjercicio: (_) {},
              onEditarEjercicio: (_, _) {},
              onEliminarEjercicio: (_) {},
              onMoverBloque: (_, _) {},
              onMoverEjercicio: (_, _, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El asa sigue pintandose, para que la fila no baile, pero inerte.
    expect(find.byType(ReorderableListView), findsNothing);
    expect(
      tester
          .widgetList<AsaDeArrastre>(find.byType(AsaDeArrastre))
          .every((asa) => !asa.activa),
      isTrue,
    );
  });
}
