import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: "lo pasado no se toca" se aplica deshabilitando cada
/// accion, una por una, y es facil olvidar alguna. Pasó con dos: el botón de
/// copiar lo que hizo el cliente a lo planificado, que rellenaba los campos y
/// despues no habia forma de guardar, y "Añadir ejercicio", que abria el
/// formulario de un ejercicio que la base de datos iba a rechazar.
///
/// La semana se calcula desde `Semana.deHoy()`: con una fecha fija el test
/// cambiaria de resultado segun el dia.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;
  late EjerciciosFalso ejercicios;

  final pasada = Semana.deHoy().anterior;

  final cliente = Cliente(
    id: 'c-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );

  /// Un planning de la semana pasada con un ejercicio al que mirar.
  final planning = planningDePrueba(
    id: 'p-pasada',
    fechaInicio: pasada.lunes,
    sesiones: [
      sesionDePrueba(
        orden: 1,
        nombre: 'Día 1',
        bloques: [
          bloqueDePrueba(
            ejercicios: [
              ejercicioPlanificadoDePrueba(series: [serieDePrueba(peso: 60)]),
            ],
          ),
        ],
      ),
    ],
  );

  /// Lo que el cliente hizo: sin esto no se pinta la mitad de la referencia y
  /// el boton de copiar no existe.
  final referencias = {
    'ej-1': ReferenciaAnterior(
      series: [
        SerieRealizada(
          id: 'sr-1',
          ejercicioPlanificadoId: 'ep-1',
          numeroSerie: 1,
          repeticionesRealizadas: 10,
          fechaHoraRegistro: DateTime.utc(2026, 10, 5),
          pesoReal: 62,
        ),
      ],
      fecha: DateTime.utc(2026, 10, 5),
      esSemanaAnterior: true,
    ),
  };

  /// Uno en la semana en curso, para que la pantalla **abra en el editor**.
  /// Sin el, abre con el boton de crear la semana, que con la fuente de los
  /// tests desborda a lo ancho y ensucia el test con un fallo que no es el que
  /// se mide aqui (le pasa igual a `panel_biblioteca_test`).
  final actual = planningDePrueba(
    id: 'p-actual',
    sesiones: [sesionDePrueba(id: 's-actual', orden: 1, nombre: 'Día 1')],
  );

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar()).thenAnswer((_) async => const Success([]));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([actual, planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((invocacion) async {
          final id = invocacion.positionalArguments.first as String;
          return Success(id == 'p-actual' ? actual : planning);
        });
  });

  /// Monta el editor y navega a la semana pasada, que es donde esta el planning.
  Future<void> montarEnLaSemanaPasada(WidgetTester tester) async {
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
            'p-pasada',
            1,
          ).overrideWith((ref) async => referencias),
          referenciasDeSesionProvider(
            'p-actual',
            1,
          ).overrideWith((ref) async => const {}),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaPlanificacionEntrenador()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('semana_anterior')));
    await tester.pumpAndSettle();
  }

  testWidgets('se ve lo que hizo el cliente, pero no se puede copiar', (
    tester,
  ) async {
    await montarEnLaSemanaPasada(tester);

    // La referencia sí se enseña: consultar lo de la semana pasada es el
    // motivo de abrirla.
    expect(find.textContaining('SEMANA PASADA'), findsOneWidget);

    final copiar = tester.widget<IconButton>(
      find.byKey(const Key('copiar_anterior_ep-1')),
    );
    expect(copiar.onPressed, isNull);
    expect(copiar.tooltip, 'Esta semana ya no se puede editar');
  });

  testWidgets('tampoco se ofrece añadir un ejercicio', (tester) async {
    await montarEnLaSemanaPasada(tester);

    final anadir = tester.widget<TextButton>(
      find.byKey(const Key('anadir_ejercicio_b-1')),
    );
    expect(anadir.onPressed, isNull);
  });

  testWidgets('ni añadir una serie', (tester) async {
    await montarEnLaSemanaPasada(tester);

    final anadir = tester.widget<TextButton>(
      find.byKey(const Key('anadir_serie_ep-1')),
    );
    expect(anadir.onPressed, isNull);
  });

  testWidgets('y las celdas de series siguen deshabilitadas', (tester) async {
    await montarEnLaSemanaPasada(tester);

    final celda = tester.widget<TextField>(
      find.byKey(const Key('plan_peso_ep-1_1')),
    );
    expect(celda.enabled, isFalse);
  });
}
