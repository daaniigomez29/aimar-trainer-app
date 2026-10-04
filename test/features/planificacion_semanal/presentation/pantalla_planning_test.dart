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

  /// Los datos reales que destaparon el fallo: semana del lunes 28/09/2026 con
  /// sesiones en cuatro de sus dias, el ultimo de ellos el domingo 04/10.
  PlanningSemanal semanaConCuatroSesiones() => planningDePrueba(
    fechaInicio: DateTime(2026, 9, 28),
    sesiones: [
      sesionDePrueba(id: 's-1', fecha: DateTime(2026, 9, 28), nombre: 'Empuje'),
      sesionDePrueba(id: 's-2', fecha: DateTime(2026, 9, 29), nombre: 'ggg'),
      sesionDePrueba(id: 's-3', fecha: DateTime(2026, 10, 2), nombre: 'kk'),
      sesionDePrueba(id: 's-4', fecha: DateTime(2026, 10, 4), nombre: 'jjjj'),
    ],
  );

  testWidgets('la semana muestra todas sus sesiones, incluida la del domingo', (
    tester,
  ) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    expect(find.text('Empuje'), findsOneWidget);
    expect(find.text('ggg'), findsOneWidget);
    expect(find.text('kk'), findsOneWidget);
    expect(find.text('jjjj'), findsOneWidget);
  });

  testWidgets('un dia con sesion no ofrece anadir otra', (tester) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    // Los dias con sesion son 28, 29 de septiembre y 2 y 4 de octubre: solo los
    // tres libres (30/09, 01/10 y 03/10) deben ofrecer el boton.
    expect(find.widgetWithText(TextButton, 'Anadir sesion'), findsNWidgets(3));
    expect(find.byKey(const Key('boton_anadir_sesion_4')), findsNothing);
    expect(find.byKey(const Key('boton_anadir_sesion_3')), findsOneWidget);
  });

  testWidgets('los dias sin sesion se marcan como descanso', (tester) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    expect(find.text('Descanso'), findsNWidgets(3));
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
    expect(find.widgetWithText(TextButton, 'Anadir sesion'), findsNothing);
    // Pero si el boton de registrar su resultado (CU-20).
    expect(find.byKey(const Key('boton_eliminar_planning')), findsNothing);
  });
}
