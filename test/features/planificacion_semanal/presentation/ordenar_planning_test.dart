import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: los bloques y los ejercicios se reordenan **con flechas**
/// desde el 2026-10-19 (antes, arrastrando). Hay dos listas anidadas en la misma
/// pantalla, así que lo que puede fallar en silencio es que una flecha mueva la
/// lista equivocada, o que mande una lista incompleta: las funciones de Postgres
/// renumeran del 1 al N y la rechazan. Y en una semana pasada no se debe poder
/// mover nada.
///
/// Sustituye a `arrastre_planning_test.dart`, que probaba `ListaArrastrable`
/// suelta. Este va contra la pantalla porque las flechas ya no viven en un
/// widget de lista, sino en la cabecera de cada bloque y de cada ejercicio.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;
  late EjerciciosFalso ejercicios;
  late PlanningSemanal planning;

  final cliente = Cliente(
    id: 'c-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );

  /// Dos bloques con dos ejercicios cada uno: lo justo para que las dos listas
  /// tengan algo que mover y se puedan confundir.
  PlanningSemanal dosPorDos({DateTime? fechaInicio}) => planningDePrueba(
    fechaInicio: fechaInicio,
    sesiones: [
      sesionDePrueba(
        orden: 1,
        nombre: 'Día 1',
        bloques: [
          for (final (b, eps) in const [
            ('b-1', ['ep-1', 'ep-2']),
            ('b-2', ['ep-3', 'ep-4']),
          ])
            bloqueDePrueba(
              id: b,
              orden: b == 'b-1' ? 1 : 2,
              ejercicios: [
                for (final (i, ep) in eps.indexed)
                  ejercicioPlanificadoDePrueba(
                    id: ep,
                    bloqueId: b,
                    orden: i + 1,
                    series: [
                      serieDePrueba(id: 'sp-$ep', ejercicioPlanificadoId: ep),
                    ],
                  ),
              ],
            ),
        ],
      ),
    ],
  );

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    planning = dosPorDos();
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar()).thenAnswer((_) async => const Success([]));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((_) async => Success(planning));
    when(
      () => plannings.reordenarBloques(
        sesionId: any(named: 'sesionId'),
        idsEnOrden: any(named: 'idsEnOrden'),
      ),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => plannings.reordenarEjerciciosPlanificados(
        bloqueId: any(named: 'bloqueId'),
        idsEnOrden: any(named: 'idsEnOrden'),
      ),
    ).thenAnswer((_) async => const Success(null));
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
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

  bool activa(WidgetTester tester, String clave) =>
      tester.widget<IconButton>(find.byKey(Key(clave))).onPressed != null;

  testWidgets('bajar un bloque manda los bloques enteros en su orden nuevo', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('bajar_bloque_b-1')));
    await tester.pumpAndSettle();

    verify(
      () => plannings.reordenarBloques(
        sesionId: 's-1',
        idsEnOrden: const ['b-2', 'b-1'],
      ),
    ).called(1);
    // Mover un bloque no reordena los ejercicios de dentro.
    verifyNever(
      () => plannings.reordenarEjerciciosPlanificados(
        bloqueId: any(named: 'bloqueId'),
        idsEnOrden: any(named: 'idsEnOrden'),
      ),
    );
  });

  testWidgets('subir un ejercicio solo reordena su bloque', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('subir_ejercicio_ep-4')));
    await tester.pumpAndSettle();

    verify(
      () => plannings.reordenarEjerciciosPlanificados(
        bloqueId: 'b-2',
        idsEnOrden: const ['ep-4', 'ep-3'],
      ),
    ).called(1);
    verifyNever(
      () => plannings.reordenarBloques(
        sesionId: any(named: 'sesionId'),
        idsEnOrden: any(named: 'idsEnOrden'),
      ),
    );
  });

  testWidgets('el primero no sube y el último no baja, en cada lista', (
    tester,
  ) async {
    await montar(tester);

    expect(activa(tester, 'subir_bloque_b-1'), isFalse);
    expect(activa(tester, 'bajar_bloque_b-1'), isTrue);
    expect(activa(tester, 'bajar_bloque_b-2'), isFalse);
    // Cada bloque cuenta sus ejercicios por separado: ep-3 es el primero del
    // suyo aunque sea el tercero de la sesión.
    expect(activa(tester, 'subir_ejercicio_ep-3'), isFalse);
    expect(activa(tester, 'bajar_ejercicio_ep-2'), isFalse);
    expect(activa(tester, 'bajar_ejercicio_ep-3'), isTrue);
  });

  testWidgets('en una semana pasada no se mueve nada', (tester) async {
    planning = dosPorDos(fechaInicio: Semana.deHoy().anterior.lunes);
    await montar(tester);
    // La pantalla abre en la semana en curso: hay que ir a la pasada.
    await tester.tap(find.byKey(const Key('semana_anterior')));
    await tester.pumpAndSettle();

    // Las flechas se pintan igual, para que la fila no baile, pero apagadas.
    for (final clave in const [
      'bajar_bloque_b-1',
      'subir_bloque_b-2',
      'bajar_ejercicio_ep-1',
      'subir_ejercicio_ep-4',
    ]) {
      expect(activa(tester, clave), isFalse, reason: clave);
    }
  });
}
