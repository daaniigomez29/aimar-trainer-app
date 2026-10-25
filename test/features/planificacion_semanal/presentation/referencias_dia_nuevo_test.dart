import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

/// POR QUE ESTE TEST: el caso de Aimar (2026-10-25). La semana anterior tenia 3
/// dias y la nueva 4, y en el Dia 4 no salia "la ultima vez" de ningun
/// ejercicio, aunque el historico (102 filas en produccion) si lo tenia.
///
/// Causa: sin Dia 4 en la semana anterior, `referenciasDelDia` devolvia un
/// `const {}` y `referenciasDeSesion` le hacia `removeWhere`, que lanza sobre un
/// mapa constante. El calculo moria antes del historico y la pantalla, que trata
/// el error como "no hay nada", dejaba el dia en blanco. Los dos tests fallaban
/// antes del arreglo.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;
  late EjerciciosFalso ejercicios;
  late ProgresoFalso progreso;
  late PlanningSemanal nuevo;

  final cliente = Cliente(
    id: 'cli-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );
  final ejercicioX = ejercicioDePrueba(id: 'ej-x', nombre: 'Sentadilla');

  // La semana anterior: 3 dias, sin Dia 4.
  final anterior = planningDePrueba(
    id: 'p-anterior',
    fechaInicio: Semana.deHoy().anterior.lunes,
    sesiones: [
      for (var i = 1; i <= 3; i++)
        sesionDePrueba(id: 's-ant-$i', planningId: 'p-anterior', orden: i),
    ],
  );

  PlanningSemanal semanaNueva({required bool conEjercicio}) => planningDePrueba(
    sesiones: [
      for (var i = 1; i <= 3; i++) sesionDePrueba(id: 's-$i', orden: i),
      sesionDePrueba(
        id: 's-4',
        orden: 4,
        nombre: 'Full',
        bloques: [
          bloqueDePrueba(
            id: 'b-4',
            sesionId: 's-4',
            ejercicios: [
              if (conEjercicio)
                ejercicioPlanificadoDePrueba(
                  id: 'ep-x',
                  bloqueId: 'b-4',
                  ejercicio: ejercicioX,
                  series: [serieDePrueba(ejercicioPlanificadoId: 'ep-x')],
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
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    progreso = ProgresoFalso();
    nuevo = semanaNueva(conEjercicio: false);

    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar())
        .thenAnswer((_) async => Success([ejercicioX]));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([nuevo, anterior]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((invocacion) async {
          final id = invocacion.positionalArguments.first as String;
          return Success(id == anterior.id ? anterior : nuevo);
        });
    // Lo que hay en el historico: la sentadilla, hecha hace unos dias.
    when(
      () => progreso.ultimoDeCadaEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioIds: any(named: 'ejercicioIds'),
        antesDe: any(named: 'antesDe'),
      ),
    ).thenAnswer(
      (_) async => Success([
        RegistroProgreso(
          clienteId: 'cli-1',
          ejercicioId: 'ej-x',
          ejercicioNombre: 'Sentadilla',
          ejercicioTipo: TipoEjercicio.fuerza,
          sesionId: 's-ant-3',
          fecha: Semana.deHoy().anterior.lunes.add(const Duration(days: 4)),
          numeroSerie: 1,
          repeticionesRealizadas: 8,
          pesoReal: 100,
          rirReal: 2,
        ),
      ]),
    );
    when(() => plannings.crearEjercicioPlanificado(any()))
        .thenAnswer((_) async {
          // La base ya lo tiene: la siguiente lectura del planning lo trae.
          nuevo = semanaNueva(conEjercicio: true);
          return Success(nuevo.sesiones.last.bloques.single.ejercicios.single);
        });
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
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
          progresoRepositorioProvider.overrideWithValue(progreso),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: const PantallaPlanificacionEntrenador(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el Día 4 abierto vacío enseña la última vez al añadirle un '
      'ejercicio', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Día 4'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ÚLTIMA VEZ'), findsNothing);

    await tester.tap(find.byKey(const Key('anadir_biblioteca_ej-x')));
    await tester.pumpAndSettle();

    expect(find.text('Sentadilla'), findsWidgets);
    expect(find.textContaining('ÚLTIMA VEZ'), findsOneWidget);
  });

  // Control: el mismo Dia 4 abierto ya con el ejercicio dentro, que es como lo
  // vio Daniel en local al entrar de cero. Si este pasa y el de arriba no, la
  // diferencia es el recorrido, no los datos.
  testWidgets('el Día 4 abierto ya con el ejercicio enseña la última vez', (
    tester,
  ) async {
    nuevo = semanaNueva(conEjercicio: true);
    await montar(tester);

    await tester.tap(find.text('Día 4'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ÚLTIMA VEZ'), findsOneWidget);
  });
}
