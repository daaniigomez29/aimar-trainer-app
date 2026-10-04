import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_ejercicio.dart';

import '../../planificacion_semanal/ayudas_planificacion.dart';

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

class _DatosFalsos extends Fake implements DatosResultadoEjercicio {}

void main() {
  late ProgresoFalso repositorio;

  setUpAll(() {
    registerFallbackValue(_DatosFalsos());
    // `any(named: 'rango')` necesita un valor de respaldo registrado para su
    // tipo; sin el, mocktail falla al preparar el doble.
    registerFallbackValue(
      RangoFechas(desde: DateTime(2026), hasta: DateTime(2026)),
    );
  });

  setUp(() {
    repositorio = ProgresoFalso();
    when(() => repositorio.registrarResultado(any()))
        .thenAnswer((_) async => const Success(null));
    when(
      () => repositorio.progresoDeEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioId: any(named: 'ejercicioId'),
        rango: any(named: 'rango'),
      ),
    ).thenAnswer((_) async => const Success(<RegistroProgreso>[]));
  });

  Future<void> montar(
    WidgetTester tester,
    EjercicioPlanificado ejercicio,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progresoRepositorioProvider.overrideWithValue(repositorio)],
        child: MaterialApp(
          home: PantallaRegistroEjercicio(
            ejercicio: ejercicio,
            planningId: 'p-1',
            clienteId: 'cli-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  EjercicioPlanificado deFuerza({List<SerieRealizada> realizadas = const []}) =>
      ejercicioPlanificadoDePrueba(
        ejercicio: ejercicioDePrueba(),
        series: [
          serieDePrueba(numeroSerie: 1, repeticiones: 10, peso: 60),
          serieDePrueba(id: 'sp-2', numeroSerie: 2, repeticiones: 8, peso: 65),
        ],
      ).copyWith(seriesRealizadas: realizadas);

  DatosResultadoEjercicio ultimoEnviado() =>
      verify(() => repositorio.registrarResultado(captureAny())).captured.last
          as DatosResultadoEjercicio;

  testWidgets('arranca en la primera serie con los valores planificados', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    expect(find.text('Confirmar serie 1'), findsOneWidget);
    expect(find.widgetWithText(TextField, '60'), findsOneWidget);
    expect(find.widgetWithText(TextField, '10'), findsOneWidget);
  });

  testWidgets('confirmar una serie la registra y pasa a la siguiente', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_confirmar_serie')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.series.length, 1);
    expect(enviado.series.single.numeroSerie, 1);
    expect(enviado.series.single.repeticiones, 10);
    expect(enviado.minutos, isNull);
    // Y la pantalla ya esta en la segunda serie.
    expect(find.text('Confirmar serie 2'), findsOneWidget);
  });

  testWidgets('la segunda confirmacion reenvia tambien la primera serie', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_confirmar_serie')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_serie')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.series.map((s) => s.numeroSerie).toList(), [1, 2]);
  });

  testWidgets('se puede registrar una serie de mas de las planificadas', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('boton_confirmar_serie')));
      await tester.pumpAndSettle();
    }

    expect(ultimoEnviado().series.length, 3);
  });

  testWidgets('lo ya registrado se carga para poder corregirlo', (
    tester,
  ) async {
    await montar(
      tester,
      deFuerza(
        realizadas: [
          SerieRealizada(
            id: 'sr-1',
            ejercicioPlanificadoId: 'ep-1',
            numeroSerie: 1,
            repeticionesRealizadas: 7,
            pesoReal: 55,
            fechaHoraRegistro: DateTime(2026, 10, 3),
          ),
        ],
      ),
    );

    // Arranca en la serie 2, la primera sin registrar.
    expect(find.text('Confirmar serie 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton_confirmar_serie')));
    await tester.pumpAndSettle();

    // Y al guardar, la serie 1 viaja con lo que ya tenia, no se pierde.
    final enviado = ultimoEnviado();
    expect(enviado.series.first.numeroSerie, 1);
    expect(enviado.series.first.repeticiones, 7);
    expect(enviado.series.first.peso, 55);
  });

  testWidgets('un Cardio registra minutos y ninguna serie', (tester) async {
    final cardio = ejercicioPlanificadoDePrueba(
      ejercicio: ejercicioDePrueba(
        id: 'ej-cardio',
        nombre: 'Cinta',
        tipo: TipoEjercicio.cardio,
      ),
      minutosPlanificados: 30,
    );
    await montar(tester, cardio);

    expect(find.byKey(const Key('boton_confirmar_serie')), findsNothing);
    await tester.tap(find.byKey(const Key('boton_guardar_cardio')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.esCardio, isTrue);
    expect(enviado.minutos, 30);
    expect(enviado.series, isEmpty);
  });
}
