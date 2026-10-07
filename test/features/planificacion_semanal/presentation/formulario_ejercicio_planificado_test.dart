import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_formulario_ejercicio_planificado.dart';

import '../ayudas_planificacion.dart';

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

void main() {
  late EjerciciosFalso biblioteca;
  late PlanningFalso planning;

  final fuerza = ejercicioDePrueba(
    id: 'ej-f',
    nombre: 'Press banca',
    tipo: TipoEjercicio.fuerza,
  );
  final cardio = ejercicioDePrueba(
    id: 'ej-c',
    nombre: 'Cinta',
    tipo: TipoEjercicio.cardio,
  );

  setUpAll(() {
    registerFallbackValue(datosEjercicio(tipo: TipoEjercicio.fuerza));
  });

  setUp(() {
    biblioteca = EjerciciosFalso();
    planning = PlanningFalso();
    when(() => biblioteca.listar())
        .thenAnswer((_) async => Success([fuerza, cardio]));
  });

  /// Con `previo` el formulario es el de editar (CU-12); sin el, el de anadir.
  Future<void> montar(
    WidgetTester tester, {
    EjercicioPlanificado? previo,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ejercicioRepositorioProvider.overrideWithValue(biblioteca),
          planningRepositorioProvider.overrideWithValue(planning),
        ],
        child: MaterialApp(
          home: PantallaFormularioEjercicioPlanificado(
            bloque: bloqueDePrueba(ejercicios: [?previo]),
            planningId: 'p-1',
            ejercicioPlanificado: previo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Un ejercicio ya anadido al bloque, con tres series.
  EjercicioPlanificado conTresSeries() => ejercicioPlanificadoDePrueba(
    ejercicio: fuerza,
    descansoSeg: 90,
    series: [
      for (var i = 1; i <= 3; i++)
        serieDePrueba(
          id: 'sp-$i',
          numeroSerie: i,
          repeticiones: 8 + i,
          peso: 60,
        ),
    ],
  );

  /// Elige un ejercicio del desplegable por su nombre.
  Future<void> elegir(WidgetTester tester, String nombre) async {
    await tester.tap(find.byKey(const Key('selector_ejercicio')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(nombre).last);
    await tester.pumpAndSettle();
  }

  testWidgets('sin ejercicio elegido no se puede guardar', (tester) async {
    await montar(tester);

    final boton = tester.widget<FilledButton>(
      find.byKey(const Key('boton_guardar_ejercicio_planificado')),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('al elegir Fuerza aparecen las series, no los minutos', (
    tester,
  ) async {
    await montar(tester);
    await elegir(tester, 'Press banca');

    expect(find.byKey(const Key('campo_reps_0')), findsOneWidget);
    expect(find.byKey(const Key('campo_peso_0')), findsOneWidget);
    expect(find.byKey(const Key('campo_rir_0')), findsOneWidget);
    expect(find.byKey(const Key('campo_descanso')), findsOneWidget);
    // La clave del punto 6: el campo de minutos no existe para Fuerza, asi que no
    // hay forma de pedir una combinacion imposible.
    expect(find.byKey(const Key('campo_minutos')), findsNothing);
  });

  testWidgets('al elegir Cardio aparecen los minutos, no las series', (
    tester,
  ) async {
    await montar(tester);
    await elegir(tester, 'Cinta');

    expect(find.byKey(const Key('campo_minutos')), findsOneWidget);
    expect(find.byKey(const Key('campo_reps_0')), findsNothing);
    expect(find.byKey(const Key('campo_descanso')), findsNothing);
    expect(find.byKey(const Key('boton_anadir_serie')), findsNothing);
  });

  testWidgets('cambiar de Fuerza a Cardio retira las series de la vista', (
    tester,
  ) async {
    await montar(tester);
    await elegir(tester, 'Press banca');
    expect(find.byKey(const Key('campo_reps_0')), findsOneWidget);

    await elegir(tester, 'Cinta');

    expect(find.byKey(const Key('campo_reps_0')), findsNothing);
    expect(find.byKey(const Key('campo_minutos')), findsOneWidget);
  });

  testWidgets('se pueden añadir y quitar series', (tester) async {
    await montar(tester);
    await elegir(tester, 'Press banca');
    expect(find.byKey(const Key('campo_reps_1')), findsNothing);

    await tester.tap(find.byKey(const Key('boton_anadir_serie')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo_reps_1')), findsOneWidget);
  });

  testWidgets('un Cardio guarda minutos y ninguna serie', (tester) async {
    when(() => planning.crearEjercicioPlanificado(any()))
        .thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));
    await montar(tester);
    await elegir(tester, 'Cinta');

    await tester.enterText(find.byKey(const Key('campo_minutos')), '30');
    await tester.ensureVisible(
      find.byKey(const Key('boton_guardar_ejercicio_planificado')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('boton_guardar_ejercicio_planificado')),
    );
    await tester.pumpAndSettle();

    final capturado =
        verify(() => planning.crearEjercicioPlanificado(captureAny()))
                .captured
                .single
            as DatosEjercicioPlanificado;
    expect(capturado.minutos, 30);
    expect(capturado.series, isEmpty);
    expect(capturado.descansoSeg, isNull);
  });

  testWidgets('una Fuerza guarda sus series y ningún minuto', (tester) async {
    when(() => planning.crearEjercicioPlanificado(any()))
        .thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));
    await montar(tester);
    await elegir(tester, 'Press banca');

    await tester.enterText(find.byKey(const Key('campo_reps_0')), '10');
    await tester.enterText(find.byKey(const Key('campo_peso_0')), '60');
    await tester.enterText(find.byKey(const Key('campo_rir_0')), '2');
    await tester.enterText(find.byKey(const Key('campo_descanso')), '90');
    await tester.ensureVisible(
      find.byKey(const Key('boton_guardar_ejercicio_planificado')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('boton_guardar_ejercicio_planificado')),
    );
    await tester.pumpAndSettle();

    final capturado =
        verify(() => planning.crearEjercicioPlanificado(captureAny()))
                .captured
                .single
            as DatosEjercicioPlanificado;
    expect(capturado.minutos, isNull);
    expect(capturado.descansoSeg, 90);
    expect(capturado.series, hasLength(1));
    expect(capturado.series.first.repeticiones, 10);
    expect(capturado.series.first.peso, 60);
    expect(capturado.series.first.rir, 2);
  });

  testWidgets('al editar llegan las series que ya tenía', (tester) async {
    await montar(tester, previo: conTresSeries());

    expect(find.text('Editar ejercicio'), findsOneWidget);
    expect(find.byKey(const Key('campo_reps_2')), findsOneWidget);
    expect(find.byKey(const Key('campo_reps_3')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('campo_reps_0')))
          .controller
          ?.text,
      '9',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('campo_descanso')))
          .controller
          ?.text,
      '90',
    );
  });

  // El agujero que esto cubre: una vez anadido el ejercicio no habia forma de
  // quitarle una serie, porque a este formulario no se llegaba.
  testWidgets(
    'quitar una serie de un ejercicio ya añadido lo guarda con una menos',
    (tester) async {
      when(
        () => planning.editarEjercicioPlanificado(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      ).thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));
      await montar(tester, previo: conTresSeries());

      await tester.ensureVisible(find.byKey(const Key('quitar_serie_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quitar_serie_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campo_reps_2')), findsNothing);
      await tester.ensureVisible(
        find.byKey(const Key('boton_guardar_ejercicio_planificado')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('boton_guardar_ejercicio_planificado')),
      );
      await tester.pumpAndSettle();

      final capturado =
          verify(
                () => planning.editarEjercicioPlanificado(
                  id: 'ep-1',
                  datos: captureAny(named: 'datos'),
                ),
              ).captured.single
              as DatosEjercicioPlanificado;
      // Quedan las series 1 y 3, renumeradas como 1 y 2: el numero de serie es la
      // posicion en el ejercicio, no un identificador.
      expect(capturado.series, hasLength(2));
      expect(capturado.series.map((s) => s.numeroSerie), [1, 2]);
      expect(capturado.series.map((s) => s.repeticiones), [9, 11]);
    },
  );

  testWidgets('al editar también se puede añadir una serie', (tester) async {
    await montar(tester, previo: conTresSeries());

    await tester.tap(find.byKey(const Key('boton_anadir_serie')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo_reps_3')), findsOneWidget);
  });

  // El mismo orden que la cuadricula de la planificacion y que el registro del
  // cliente: primero el peso, luego las repeticiones.
  testWidgets('el peso va antes que las repeticiones', (tester) async {
    await montar(tester, previo: conTresSeries());

    expect(
      tester.getTopLeft(find.byKey(const Key('campo_peso_0'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const Key('campo_reps_0'))).dx),
    );
  });

  testWidgets('la biblioteca vacía lo explica y ofrece añadir antes', (
    tester,
  ) async {
    when(() => biblioteca.listar())
        .thenAnswer((_) async => const Success(<Ejercicio>[]));
    await montar(tester);

    expect(find.textContaining('La biblioteca está vacía'), findsOneWidget);
  });
}
