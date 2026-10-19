import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/dialogos_planificacion.dart';

import '../ayudas_planificacion.dart';

/// POR QUE ESTE TEST: desde el panel de la biblioteca, el "+" metia el
/// ejercicio **siempre en el primer bloque**. Con una sesion de calentamiento
/// mas fuerza eso nunca es lo que se quiere, y no se nota hasta que miras donde
/// ha caido.
void main() {
  final calentamiento = bloqueDePrueba(
    id: 'b-1',
    orden: 1,
    tipo: TipoBloque.calentamiento,
  );
  final fuerza = bloqueDePrueba(
    id: 'b-2',
    orden: 2,
    tipo: TipoBloque.fuerza,
    ejercicios: [ejercicioPlanificadoDePrueba(id: 'ep-1', orden: 1)],
  );
  final sesion = sesionDePrueba(bloques: [calentamiento, fuerza]);
  final ejercicio = ejercicioDePrueba(id: 'ej-1', nombre: 'Sentadilla');

  /// Monta un boton que abre el dialogo y guarda lo que devuelva.
  Future<List<BloqueEjercicio?>> montar(WidgetTester tester) async {
    final elegidos = <BloqueEjercicio?>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => elegidos.add(
                await elegirBloque(
                  context: context,
                  sesion: sesion,
                  nombre: ejercicio.nombre,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return elegidos;
  }

  testWidgets('ofrece los bloques de la sesión con lo que ya tienen', (
    tester,
  ) async {
    await montar(tester);

    expect(find.textContaining('Sentadilla'), findsOneWidget);
    expect(find.text('Bloque 1 · Calentamiento'), findsOneWidget);
    expect(find.text('Bloque 2 · Fuerza'), findsOneWidget);
    expect(find.text('Vacío'), findsOneWidget);
    expect(find.text('1 ejercicio'), findsOneWidget);
  });

  testWidgets('devuelve el bloque elegido, no el primero', (tester) async {
    final elegidos = await montar(tester);

    await tester.tap(find.byKey(const Key('elegir_bloque_b-2')));
    await tester.pumpAndSettle();

    expect(elegidos.single?.id, 'b-2');
  });

  testWidgets('cancelar no elige ninguno', (tester) async {
    final elegidos = await montar(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(elegidos.single, isNull);
  });
}
