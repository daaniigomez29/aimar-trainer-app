import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:go_router/go_router.dart';

import '../../../ayudas/app_con_rutas.dart';
import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: añadir una serie obligaba a abrir el formulario del
/// ejercicio, cuando el resto de la cuadrícula ya se edita en línea. Lo que se
/// comprueba aquí es que la fila nueva llega al repositorio **al guardar**, no
/// antes: la cuadrícula acumula cambios y los guarda el botón de siempre.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;
  late EjerciciosFalso ejercicios;

  final cliente = Cliente(
    id: 'c-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );

  final planning = planningDePrueba(
    sesiones: [
      sesionDePrueba(
        orden: 1,
        nombre: 'Día 1',
        bloques: [
          bloqueDePrueba(
            ejercicios: [
              ejercicioPlanificadoDePrueba(
                series: [serieDePrueba(peso: 60, repeticiones: 10, rir: 2)],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(
      const DatosEjercicioPlanificado(
        bloqueId: 'b-1',
        ejercicioId: 'ej-1',
        tipoEjercicio: TipoEjercicio.fuerza,
        orden: 1,
      ),
    );
  });

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar()).thenAnswer((_) async => const Success([]));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((_) async => Success(planning));
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          clienteRepositorioProvider.overrideWithValue(clientes),
          planningRepositorioProvider.overrideWithValue(plannings),
          ejercicioRepositorioProvider.overrideWithValue(ejercicios),
          referenciasDeSesionProvider(
            'p-1',
            1,
          ).overrideWith((ref) async => const {}),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        // Con rutas de verdad: el boton de ver resultados navega, y lo que
        // importa es **con que dia** llega alli.
        child: appConRutas(
          rutaInicial: Rutas.inicioEntrenador,
          rutas: [
            GoRoute(
              path: Rutas.inicioEntrenador,
              builder: (_, _) => const PantallaPlanificacionEntrenador(),
            ),
            GoRoute(
              path: '${Rutas.clientesEntrenador}/:idCliente/plannings/:id',
              builder: (_, estado) => Scaffold(
                body: Text(
                  'resultados de ${estado.pathParameters['idCliente']} '
                  'dia=${estado.uri.queryParameters[Rutas.paramDia]}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la serie nueva aparece heredando lo de la anterior', (
    tester,
  ) async {
    await montar(tester);
    expect(find.byKey(const Key('plan_peso_ep-1_2')), findsNothing);

    await tester.tap(find.byKey(const Key('anadir_serie_ep-1')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('plan_peso_ep-1_2')))
          .controller
          ?.text,
      '60',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('plan_reps_ep-1_2')))
          .controller
          ?.text,
      '10',
    );
    // Queda pendiente: no se ha guardado nada todavía.
    expect(find.text('Sin guardar'), findsOneWidget);
  });

  testWidgets('al guardar llegan las dos series', (tester) async {
    when(
      () => plannings.editarEjercicioPlanificado(
        id: any(named: 'id'),
        datos: any(named: 'datos'),
      ),
    ).thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));

    await montar(tester);
    await tester.tap(find.byKey(const Key('anadir_serie_ep-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_guardar_cambios')));
    await tester.pumpAndSettle();

    final datos =
        verify(
              () => plannings.editarEjercicioPlanificado(
                id: 'ep-1',
                datos: captureAny(named: 'datos'),
              ),
            ).captured.single
            as DatosEjercicioPlanificado;
    expect(datos.series, hasLength(2));
    expect(datos.series.last.numeroSerie, 2);
    expect(datos.series.last.peso, 60);
    expect(datos.series.last.repeticiones, 10);
  });

  group('quitar una serie', () {
    // Se pregunta porque el resto de la cuadricula se corrige tecleando encima
    // y quitar una fila entera no se deshace asi.
    testWidgets('pregunta antes y deja la serie si se cancela', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('anadir_serie_ep-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quitar_plan_ep-1_2')));
      await tester.pumpAndSettle();
      expect(find.text('Quitar la serie 2'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('plan_peso_ep-1_2')), findsOneWidget);
    });

    testWidgets('al confirmar desaparece de la cuadrícula', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('anadir_serie_ep-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quitar_plan_ep-1_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_confirmar_planificacion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('plan_peso_ep-1_2')), findsNothing);
    });

    // Un ejercicio que va por series necesita al menos una: lo exige
    // `DatosEjercicioPlanificado.validar`, y es mejor deshabilitar el boton que
    // dar un error al guardar.
    testWidgets('la última serie no se puede quitar', (tester) async {
      await montar(tester);

      final boton = tester.widget<IconButton>(
        find.byKey(const Key('quitar_plan_ep-1_1')),
      );
      expect(boton.onPressed, isNull);
    });
  });

  // Lo que el cliente hizo se consulta en su pantalla, a un boton de aqui.
  testWidgets('el botón de resultados abre el día que se está planificando', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('ver_resultados_s-1')));
    await tester.pumpAndSettle();

    expect(find.text('resultados de cli-1 dia=1'), findsOneWidget);
  });

  // Anadir desde el panel de la biblioteca y anadir desde el formulario de
  // CU-08 tienen que dar lo mismo: el atajo no puede salir mas caro que el
  // camino largo. Por eso se afirma con las constantes y no con un numero.
  testWidgets('desde el panel, nace con las series de partida', (tester) async {
    when(() => ejercicios.listar()).thenAnswer(
      (_) async => Success([ejercicioDePrueba(id: 'ej-2', nombre: 'Remo')]),
    );
    when(() => plannings.crearEjercicioPlanificado(any()))
        .thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));

    await montar(tester);
    await tester.tap(find.byKey(const Key('anadir_biblioteca_ej-2')));
    await tester.pumpAndSettle();

    final datos =
        verify(() => plannings.crearEjercicioPlanificado(captureAny()))
                .captured
                .single
            as DatosEjercicioPlanificado;
    expect(datos.series, hasLength(seriesPorDefecto));
    expect(
      datos.series.every((s) => s.repeticiones == repeticionesPorDefecto),
      isTrue,
    );
    expect(datos.series.map((s) => s.numeroSerie), [
      for (var i = 1; i <= seriesPorDefecto; i++) i,
    ]);
  });
}

// El caso de la semana pasada vive en `editor_semana_pasada_test.dart`, que ya
// tiene el armazon con las dos semanas montadas.
