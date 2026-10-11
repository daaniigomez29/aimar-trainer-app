import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_plannings_cliente.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

/// POR QUE ESTE TEST: "Clientes → una ficha → Plannings" se quedaba colgado, y
/// es una pantalla que no tenia ninguno. Montarla aqui reproduce el fallo sin
/// navegador.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;

  final cliente = Cliente(
    id: 'c-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
  });

  Future<void> montar(
    WidgetTester tester, {
    List<PlanningSemanal> lista = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success(lista));

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          clienteRepositorioProvider.overrideWithValue(clientes),
          planningRepositorioProvider.overrideWithValue(plannings),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(
          home: PantallaPlanningsCliente(clienteId: 'c-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin plannings lo dice, sin colgarse', (tester) async {
    await montar(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.text('Este cliente no tiene ningún planning todavía.'),
      findsOneWidget,
    );
  });

  testWidgets('lista los plannings del cliente', (tester) async {
    await montar(tester, lista: [planningDePrueba(id: 'p-1')]);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('planning_p-1')), findsOneWidget);
  });
}
