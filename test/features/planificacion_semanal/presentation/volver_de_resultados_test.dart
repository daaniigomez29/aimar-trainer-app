import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

/// POR QUE ESTE TEST: "Visualizar resultados de la sesion" colgaba de la ficha
/// del cliente, asi que atras llevaba a la lista de semanas del cliente, por la
/// que no se habia pasado, y el editor se perdia con su dia y lo no guardado.
///
/// Va contra el **enrutador de verdad**: el fallo estaba en donde cuelga la
/// ruta, y con rutas montadas para el test no se veria.
void main() {
  testWidgets('atrás desde resultados vuelve al editor tal como estaba', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final clientes = ClientesFalso();
    final plannings = PlanningFalso();
    final ejercicios = EjerciciosFalso();
    final progreso = ProgresoFalso();

    final planning = planningDePrueba(
      sesiones: [
        sesionDePrueba(id: 's-1', orden: 1, nombre: 'Empuje'),
        sesionDePrueba(
          id: 's-2',
          orden: 2,
          nombre: 'Pierna',
          bloques: [
            bloqueDePrueba(
              id: 'b-2',
              sesionId: 's-2',
              ejercicios: [
                ejercicioPlanificadoDePrueba(
                  id: 'ep-2',
                  bloqueId: 'b-2',
                  series: [serieDePrueba(ejercicioPlanificadoId: 'ep-2')],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    when(() => clientes.listar()).thenAnswer(
      (_) async => Success([
        Cliente(
          id: 'cli-1',
          nombre: 'Cliente de prueba',
          correo: 'cliente@local.test',
          diaControlPreferido: DiaSemana.domingo,
          estado: EstadoCliente.activo,
          fechaAlta: DateTime.utc(2026),
        ),
      ]),
    );
    when(() => ejercicios.listar()).thenAnswer((_) async => const Success([]));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((_) async => Success(planning));
    when(
      () => progreso.ultimoDeCadaEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioIds: any(named: 'ejercicioIds'),
        antesDe: any(named: 'antesDe'),
      ),
    ).thenAnswer((_) async => const Success([]));
    registerFallbackValue(DateTime(2026));

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
        child: MaterialApp.router(
          theme: TemaApp.oscuro(),
          routerConfig: contenedor.read(enrutadorProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El estado que no debe perderse: el Dia 2 y un peso sin guardar.
    await tester.tap(find.text('Día 2'));
    await tester.pumpAndSettle();
    expect(find.text('Día 2 · Pierna'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('plan_peso_ep-2_1')), '77');
    await tester.pump();

    await tester.tap(find.byKey(const Key('ver_resultados_s-2')));
    await tester.pumpAndSettle();
    expect(find.text('Resultados de la semana'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Resultados de la semana'), findsNothing);
    expect(find.text('Día 2 · Pierna'), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
  });
}
