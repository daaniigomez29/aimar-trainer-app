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
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mis_plannings.dart';

import '../ayudas_planificacion.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class PlanningsFalso extends Mock implements PlanningRepositorio {}

void main() {
  late AutenticacionFalsa autenticacion;
  late PlanningsFalso plannings;

  /// Hoy a medianoche: las semanas de prueba se colocan alrededor de esta fecha
  /// para que el test no dependa del dia en que se ejecute.
  final hoy = DateTime.now();
  final diaDeHoy = DateTime(hoy.year, hoy.month, hoy.day);

  setUp(() {
    autenticacion = AutenticacionFalsa();
    plannings = PlanningsFalso();
    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn('id-usuario');
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(
          id: 'id-usuario',
          rol: RolUsuario.cliente,
          creadoEn: DateTime.utc(2026),
        ),
      ),
    );
  });

  Future<void> montar(
    WidgetTester tester, {
    required List<PlanningSemanal> lista,
    PlanningSemanal? completo,
  }) async {
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success(lista));
    when(() => plannings.obtenerPlanningCompleto(any())).thenAnswer(
      (_) async => completo == null
          ? const Failure(ErrorNoEncontrado())
          : Success(completo),
    );

    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        planningRepositorioProvider.overrideWithValue(plannings),
      ],
    );
    addTearDown(contenedor.dispose);
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaMisPlannings()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pide los plannings de la cuenta con la sesion abierta', (
    tester,
  ) async {
    await montar(tester, lista: const []);

    verify(() => plannings.listarDeCliente('id-usuario')).called(1);
  });

  testWidgets('sin plannings, lo dice en lugar de dejar la pantalla vacia', (
    tester,
  ) async {
    await montar(tester, lista: const []);

    expect(find.textContaining('todavia no te ha preparado'), findsOneWidget);
  });

  testWidgets('la semana en curso muestra la sesion de hoy', (tester) async {
    final semana = planningDePrueba(
      clienteId: 'id-usuario',
      fechaInicio: diaDeHoy.subtract(const Duration(days: 1)),
      nombreObjetivo: 'Fuerza general',
    );
    await montar(
      tester,
      lista: [semana],
      completo: semana.copyWith(
        sesiones: [
          sesionDePrueba(
            orden: 1,
            nombre: 'Empuje',
            bloques: [
              bloqueDePrueba(ejercicios: [ejercicioPlanificadoDePrueba()]),
            ],
          ),
        ],
      ),
    );

    expect(find.textContaining('Te toca el dia 1: Empuje'), findsOneWidget);
    expect(find.text('Fuerza general'), findsOneWidget);
  });

  testWidgets('una semana sin sesiones lo dice', (tester) async {
    final semana = planningDePrueba(
      clienteId: 'id-usuario',
      fechaInicio: diaDeHoy,
    );
    await montar(tester, lista: [semana], completo: semana);

    expect(find.textContaining('aun no tiene sesiones'), findsOneWidget);
  });

  testWidgets('las semanas archivadas van aparte, en el historico', (
    tester,
  ) async {
    await montar(
      tester,
      lista: [
        planningDePrueba(
          id: 'p-vieja',
          clienteId: 'id-usuario',
          fechaInicio: diaDeHoy.subtract(const Duration(days: 30)),
          estado: EstadoPlanning.archivado,
        ),
      ],
    );

    expect(find.text('Semanas anteriores'), findsOneWidget);
    expect(find.byKey(const Key('planning_p-vieja')), findsOneWidget);
    // No hay ninguna activa: se dice, en vez de dejar solo el historico.
    expect(find.textContaining('ninguna semana activa'), findsOneWidget);
  });

  testWidgets('el cliente no recibe ninguna accion de escritura', (
    tester,
  ) async {
    final semana = planningDePrueba(
      clienteId: 'id-usuario',
      fechaInicio: diaDeHoy,
    );
    await montar(tester, lista: [semana], completo: semana);

    // El equivalente del entrenador (PantallaPlanningsCliente) si tiene boton de
    // nuevo planning: aqui no debe existir ninguno.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('boton_nuevo_planning')), findsNothing);
  });
}
