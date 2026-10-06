import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planning.dart';

import '../ayudas_planificacion.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

void main() {
  late AutenticacionFalsa autenticacion;
  late PlanningFalso repositorio;

  setUp(() {
    autenticacion = AutenticacionFalsa();
    // Una semana entera no cabe en los 600 px de alto por defecto, y un ListView
    // solo construye lo visible: sin esto, los ultimos dias "no existen" para los
    // finders y el test miente.
    repositorio = PlanningFalso();
    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn('id-usuario');
  });

  Future<void> montar(
    WidgetTester tester, {
    required PlanningSemanal planning,
    RolUsuario rol = RolUsuario.entrenador,
  }) async {
    // Una semana entera no cabe en los 600 px de alto por defecto, y un ListView
    // solo construye lo visible: sin esto los ultimos dias "no existen" para los
    // finders y el test miente diciendo que faltan sesiones.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(id: 'id-usuario', rol: rol, creadoEn: DateTime.utc(2026)),
      ),
    );
    when(() => repositorio.obtenerPlanningCompleto(planning.id))
        .thenAnswer((_) async => Success(planning));

    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        planningRepositorioProvider.overrideWithValue(repositorio),
      ],
    );
    addTearDown(contenedor.dispose);
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(home: PantallaPlanning(planningId: planning.id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Una semana con cuatro sesiones numeradas. Antes estaban atadas a dias del
  /// calendario; ahora son Dia 1 a Dia 4 y el cliente las hace cuando puede.
  PlanningSemanal semanaConCuatroSesiones() => planningDePrueba(
    fechaInicio: DateTime(2026, 9, 28),
    sesiones: [
      sesionDePrueba(id: 's-1', orden: 1, nombre: 'Empuje'),
      sesionDePrueba(id: 's-2', orden: 2, nombre: 'ggg'),
      sesionDePrueba(id: 's-3', orden: 3, nombre: 'kk'),
      sesionDePrueba(id: 's-4', orden: 4, nombre: 'jjjj'),
    ],
  );

  testWidgets('la semana muestra todas sus sesiones', (tester) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    expect(find.text('Empuje'), findsOneWidget);
    expect(find.text('ggg'), findsOneWidget);
    expect(find.text('kk'), findsOneWidget);
    expect(find.text('jjjj'), findsOneWidget);
  });

  testWidgets('las sesiones van numeradas y se puede añadir la siguiente', (
    tester,
  ) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    expect(find.text('Día 1'), findsOneWidget);
    expect(find.text('Día 4'), findsOneWidget);
    // El boton propone el numero que toca, no un dia de la semana.
    expect(find.text('Añadir día 5'), findsOneWidget);
  });

  testWidgets('una sesión hecha muestra cuando se hizo', (tester) async {
    await montar(
      tester,
      planning: planningDePrueba(
        sesiones: [
          sesionDePrueba(
            id: 's-1',
            orden: 1,
            nombre: 'Empuje',
            resultadoRegistrado: true,
            fechaRealizada: DateTime(2026, 10, 8),
          ),
        ],
      ),
    );

    expect(find.textContaining('Hecha el 08/10'), findsOneWidget);
  });

  testWidgets('el cliente ve la semana sin acciones de escritura', (
    tester,
  ) async {
    await montar(
      tester,
      planning: semanaConCuatroSesiones(),
      rol: RolUsuario.cliente,
    );

    expect(find.text('Empuje'), findsOneWidget);
    expect(find.textContaining('Añadir día'), findsNothing);
    // Pero si el boton de registrar su resultado (CU-20).
    expect(find.byKey(const Key('boton_eliminar_planning')), findsNothing);
  });
}
