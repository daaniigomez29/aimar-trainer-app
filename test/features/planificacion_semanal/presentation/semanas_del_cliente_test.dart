import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mi_planning.dart';

import '../ayudas_planificacion.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class PlanningsFalso extends Mock implements PlanningRepositorio {}

class ClientesFalso extends Mock implements ClienteRepositorio {}

/// El cliente también navega por semanas, no solo el entrenador: antes solo veía
/// la de hoy y el histórico quedaba en otra pantalla.
void main() {
  late AutenticacionFalsa autenticacion;
  late PlanningsFalso plannings;
  late ClientesFalso clientes;

  final estaSemana = Semana.deHoy();

  setUp(() {
    autenticacion = AutenticacionFalsa();
    plannings = PlanningsFalso();
    clientes = ClientesFalso();

    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn('cli-1');
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(
          id: 'cli-1',
          rol: RolUsuario.cliente,
          creadoEn: DateTime.utc(2026),
        ),
      ),
    );
    when(() => clientes.obtenerPorId(any())).thenAnswer(
      (_) async => Success(
        Cliente(
          id: 'cli-1',
          nombre: 'Ana Demo',
          correo: 'ana@local.test',
          diaControlPreferido: DiaSemana.domingo,
          estado: EstadoCliente.activo,
          fechaAlta: DateTime.utc(2026),
        ),
      ),
    );
    when(() => clientes.listar()).thenAnswer((_) async => const Success([]));
    // Sin eventos de realtime: lo que se prueba aquí es la navegación.
    when(() => plannings.cambiosEnPlanningsDeCliente(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  /// Un planning con una sesión, para que la semana tenga algo que enseñar.
  PlanningSemanal deLaSemana(Semana semana, {required String id}) =>
      planningDePrueba(
        id: id,
        fechaInicio: semana.lunes,
        nombreObjetivo: 'Objetivo $id',
        // El nombre de la sesion es lo que identifica a cada planning en
        // pantalla: el objetivo no se pinta en la vista del cliente.
        sesiones: [sesionDePrueba(planningId: id, nombre: 'Sesion de $id')],
      );

  Future<void> montar(
    WidgetTester tester, {
    required List<PlanningSemanal> lista,
  }) async {
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success(lista));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((invocacion) async {
          final id = invocacion.positionalArguments.first as String;
          final encontrado = lista.where((p) => p.id == id).firstOrNull;
          return encontrado == null
              ? const Failure(ErrorNoEncontrado())
              : Success(encontrado);
        });

    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        planningRepositorioProvider.overrideWithValue(plannings),
        clienteRepositorioProvider.overrideWithValue(clientes),
      ],
    );
    addTearDown(contenedor.dispose);
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaMiPlanning()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('entra por la semana de hoy', (tester) async {
    await montar(tester, lista: [deLaSemana(estaSemana, id: 'p-hoy')]);

    expect(find.text('Semana del ${estaSemana.etiqueta}'), findsOneWidget);
  });

  testWidgets('la flecha de atrás lleva al planning de la semana anterior', (
    tester,
  ) async {
    final anterior = estaSemana.anterior;
    await montar(
      tester,
      lista: [
        deLaSemana(estaSemana, id: 'p-hoy'),
        deLaSemana(anterior, id: 'p-anterior'),
      ],
    );

    await tester.tap(find.byKey(const Key('semana_anterior')));
    await tester.pumpAndSettle();

    expect(find.text('Semana del ${anterior.etiqueta}'), findsOneWidget);
    expect(find.text('Sesion de p-anterior'), findsOneWidget);
  });

  testWidgets('una semana sin planning lo dice y deja volver', (tester) async {
    await montar(tester, lista: [deLaSemana(estaSemana, id: 'p-hoy')]);

    await tester.tap(find.byKey(const Key('semana_siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Semana sin planning'), findsOneWidget);

    // La clave: el navegador sigue ahí, así que no es un callejón sin salida.
    await tester.tap(find.byKey(const Key('semana_anterior')));
    await tester.pumpAndSettle();

    expect(find.text('Semana del ${estaSemana.etiqueta}'), findsOneWidget);
    expect(find.text('Sesion de p-hoy'), findsOneWidget);
  });

  testWidgets('sin ningún planning, no habla de una semana concreta', (
    tester,
  ) async {
    await montar(tester, lista: const []);

    expect(find.text('Todavía no tienes ninguna semana'), findsOneWidget);
  });
}
