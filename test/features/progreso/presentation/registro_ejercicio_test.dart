import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_ejercicio.dart';

import '../../../ayudas/app_con_rutas.dart';
import '../../planificacion_semanal/ayudas_planificacion.dart';

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

class _DatosFalsos extends Fake implements DatosResultadoEjercicio {}

void main() {
  late ProgresoFalso repositorio;

  setUpAll(() {
    registerFallbackValue(_DatosFalsos());
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
    // La pantalla muestra todas las series a la vez: con los 600 px por defecto
    // no caben y los finders no las encontrarian.
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [progresoRepositorioProvider.overrideWithValue(repositorio)],
        // Con rutas de verdad: al terminar el ultimo ejercicio la pantalla
        // navega al planning del cliente, y eso necesita un GoRouter.
        child: appConRutas(
          rutaInicial: '/registro',
          tema: TemaApp.oscuro(),
          rutas: [
            GoRoute(
              path: Rutas.inicioCliente,
              builder: (context, state) =>
                  const Scaffold(body: Text('mi planning')),
            ),
            GoRoute(
              path: '/registro',
              builder: (context, state) => PantallaRegistroEjercicio(
                ejercicio: ejercicio,
                planningId: 'p-1',
                clienteId: 'cli-1',
              ),
            ),
          ],
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

  testWidgets('cada serie llega con lo planificado puesto', (tester) async {
    await montar(tester, deFuerza());

    // Serie 1: 60 kg x 10. Serie 2: 65 kg x 8.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('peso_serie_1')))
          .controller
          ?.text,
      '60',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('reps_serie_2')))
          .controller
          ?.text,
      '8',
    );
  });

  testWidgets('confirmar una serie la registra', (tester) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('confirmar_serie_1')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.series.length, 1);
    expect(enviado.series.single.numeroSerie, 1);
    expect(enviado.series.single.repeticiones, 10);
    expect(enviado.minutos, isNull);
  });

  testWidgets('la segunda confirmación reenvia también la primera serie', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('confirmar_serie_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar_serie_2')));
    await tester.pumpAndSettle();

    expect(ultimoEnviado().series.map((s) => s.numeroSerie).toList(), [1, 2]);
  });

  testWidgets('se puede añadir y registrar una serie de mas', (tester) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_serie_extra')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirmar_serie_3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmar_serie_3')));
    await tester.pumpAndSettle();

    expect(ultimoEnviado().series.single.numeroSerie, 3);
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

    // La serie 1 llega con lo registrado, no con lo planificado.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('reps_serie_1')))
          .controller
          ?.text,
      '7',
    );

    await tester.tap(find.byKey(const Key('confirmar_serie_2')));
    await tester.pumpAndSettle();

    // Y al guardar, la serie 1 viaja con lo que ya tenia: no se pierde.
    final enviado = ultimoEnviado();
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

    expect(find.byKey(const Key('confirmar_serie_1')), findsNothing);
    await tester.tap(find.byKey(const Key('boton_guardar_cardio')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.esCardio, isTrue);
    expect(enviado.minutos, 30);
    expect(enviado.series, isEmpty);
  });

  // Al acabar el ultimo ejercicio el cliente quiere ver como queda su semana,
  // no volver a la lista de lo que acaba de terminar.
  testWidgets('terminar el último ejercicio devuelve al planning', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_siguiente_ejercicio')));
    await tester.pumpAndSettle();

    expect(find.text('mi planning'), findsOneWidget);
  });
}
