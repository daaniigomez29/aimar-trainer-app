import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/formularios_planificacion.dart';

import '../ayudas_planificacion.dart';

class PlanningFalso extends Mock implements PlanningRepositorio {}

void main() {
  late PlanningFalso repositorio;

  setUpAll(() {
    registerFallbackValue(
      DatosPlanning(clienteId: 'cli-1', fechaInicio: DateTime(2026)),
    );
  });

  setUp(() => repositorio = PlanningFalso());

  /// Abre el diálogo proponiendo [semana], como hace la pantalla cuando el
  /// entrenador está mirando esa semana.
  Future<void> abrir(WidgetTester tester, {Semana? semana}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [planningRepositorioProvider.overrideWithValue(repositorio)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => pedirDatosPlanning(
                  context: context,
                  ref: ref,
                  clienteId: 'cli-1',
                  semana: semana,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  // El fallo: el entrenador navegaba a una semana futura para adelantar
  // trabajo y el diálogo le proponía la semana de hoy, que no es la que quiere.
  testWidgets('propone la semana que se está viendo, no la de hoy', (
    tester,
  ) async {
    await abrir(tester, semana: Semana.de(DateTime(2026, 10, 19)));

    expect(find.text('Del 19/10 al 25/10'), findsOneWidget);
  });

  testWidgets('sin semana propuesta, la de hoy', (tester) async {
    final estaSemana = Semana.deHoy();

    await abrir(tester);

    expect(
      find.text(
        'Del ${_dosCifras(estaSemana.lunes)} al ${_dosCifras(estaSemana.domingo)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('guarda el lunes de la semana elegida', (tester) async {
    when(() => repositorio.crearPlanning(any()))
        .thenAnswer((_) async => Success(planningDePrueba()));
    await abrir(tester, semana: Semana.de(DateTime(2026, 10, 22)));

    await tester.tap(find.byKey(const Key('boton_guardar_planning')));
    await tester.pumpAndSettle();

    final datos =
        verify(() => repositorio.crearPlanning(captureAny())).captured.single
            as DatosPlanning;
    // Se eligió el jueves 22; lo que se guarda es el lunes 19.
    expect(datos.fechaInicio, DateTime(2026, 10, 19));
  });
}

String _dosCifras(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
