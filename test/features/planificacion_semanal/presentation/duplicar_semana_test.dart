import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/navegador_de_semana.dart';

/// POR QUE ESTE TEST: el navegador lo comparten el entrenador y el cliente, y
/// duplicar es solo del entrenador. Si el botón se colara en la vista del
/// cliente no daría un error: le ofrecería algo que RLS le va a negar.
void main() {
  Future<void> montar(
    WidgetTester tester, {
    VoidCallback? onDuplicar,
    String? tooltipDuplicar,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavegadorDeSemana(
            semana: Semana.de(DateTime(2026, 11, 16)),
            onCambio: (_) {},
            onDuplicar: onDuplicar,
            tooltipDuplicar: tooltipDuplicar,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin tooltip el botón no se pinta (la vista del cliente)', (
    tester,
  ) async {
    await montar(tester);

    expect(find.byKey(const Key('duplicar_semana')), findsNothing);
    expect(find.byKey(const Key('semana_anterior')), findsOneWidget);
  });

  testWidgets('en una semana vacía el botón duplica', (tester) async {
    var pulsado = 0;
    await montar(
      tester,
      tooltipDuplicar: 'Traer aquí otra semana',
      onDuplicar: () => pulsado++,
    );

    await tester.tap(find.byKey(const Key('duplicar_semana')));
    await tester.pumpAndSettle();

    expect(pulsado, 1);
  });

  // Con planning ya puesto se deshabilita en lugar de desaparecer: si no,
  // parece que la función no existe.
  testWidgets('con planning el botón sigue a la vista, deshabilitado', (
    tester,
  ) async {
    await montar(tester, tooltipDuplicar: 'Esta semana ya tiene planning');

    final boton = tester.widget<IconButton>(
      find.byKey(const Key('duplicar_semana')),
    );
    expect(boton.onPressed, isNull);
    expect(boton.tooltip, 'Esta semana ya tiene planning');
  });
}
