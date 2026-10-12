import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudas/app_con_rutas.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

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
    int? dia,
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
        // Con ruta real: la pantalla construye las rutas de lo que abre a
        // partir de aquella por la que se ha llegado.
        child: appConRutas(
          rutaInicial:
              '${Rutas.planningDelCliente(planning.id)}'
              '${dia == null ? '' : '?${Rutas.paramDia}=$dia'}',
          rutas: [
            GoRoute(
              path: Rutas.planningCliente,
              builder: (_, _) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: Rutas.unPlanning,
                  builder: (_, estado) => PantallaPlanning(
                    planningId: estado.pathParameters['planningId']!,
                    diaInicial: int.tryParse(
                      estado.uri.queryParameters[Rutas.paramDia] ?? '',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Una semana con cuatro sesiones numeradas. Antes estaban atadas a dias del
  /// calendario; ahora son Dia 1 a Dia 4 y el cliente las hace cuando puede.
  PlanningSemanal semanaConCuatroSesiones() => planningDePrueba(
    // Sin fecha: la ayuda usa la semana en curso. Con una fija del pasado, la
    // regla "lo pasado no se toca" dejaria el planning no editable y este test
    // comprobaria lo contrario de lo que quiere.
    sesiones: [
      sesionDePrueba(id: 's-1', orden: 1, nombre: 'Empuje'),
      sesionDePrueba(id: 's-2', orden: 2, nombre: 'ggg'),
      sesionDePrueba(id: 's-3', orden: 3, nombre: 'kk'),
      sesionDePrueba(id: 's-4', orden: 4, nombre: 'jjjj'),
    ],
  );

  // Un dia a la vez, con la tira de chips para cambiar: antes se pintaba la
  // semana entera de corrido y habia que bajar buscando el dia.
  testWidgets('se ve un día a la vez, y se cambia con los chips', (
    tester,
  ) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    expect(find.text('Empuje'), findsOneWidget);
    expect(find.text('jjjj'), findsNothing);
    // Los cuatro dias estan en la tira.
    expect(find.byKey(const Key('dia_4')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dia_4')));
    await tester.pumpAndSettle();

    expect(find.text('jjjj'), findsOneWidget);
    expect(find.text('Empuje'), findsNothing);
  });

  // Es como llega el boton "Visualizar resultados de la sesion" del editor.
  testWidgets('la URL puede pedir con qué día abrir', (tester) async {
    await montar(tester, planning: semanaConCuatroSesiones(), dia: 3);

    expect(find.text('kk'), findsOneWidget);
    expect(find.text('Empuje'), findsNothing);
  });

  // Planificar es del editor. Aqui se consulta, y punto.
  testWidgets('no se ofrece tocar el contenido de la semana', (tester) async {
    await montar(tester, planning: semanaConCuatroSesiones());

    expect(find.textContaining('Añadir día'), findsNothing);
    expect(find.textContaining('Añadir bloque'), findsNothing);
    expect(find.textContaining('Añadir ejercicio'), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('una sesión hecha muestra cuándo se hizo', (tester) async {
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

  // Lo que faltaba: el entrenador no tenia donde ver lo que hizo el cliente sin
  // ponerse a planificar la semana siguiente.
  testWidgets('se ve lo planificado al lado de lo que hizo el cliente', (
    tester,
  ) async {
    await montar(
      tester,
      planning: planningDePrueba(
        sesiones: [
          sesionDePrueba(
            id: 's-1',
            orden: 1,
            nombre: 'Empuje',
            bloques: [
              bloqueDePrueba(
                ejercicios: [
                  ejercicioPlanificadoDePrueba(
                    estadoRegistro: EstadoRegistro.registrado,
                    series: [serieDePrueba(peso: 60, repeticiones: 10)],
                  ).copyWith(
                    seriesRealizadas: [
                      SerieRealizada(
                        id: 'sr-1',
                        ejercicioPlanificadoId: 'ep-1',
                        numeroSerie: 1,
                        repeticionesRealizadas: 9,
                        fechaHoraRegistro: DateTime.utc(2026, 10, 8),
                        pesoReal: 62.5,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('60 kg · 10 reps'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('serie_hecha_ep-1_1'))).data,
      '62.5 kg · 9 reps',
    );
    expect(find.text('Registrado'), findsOneWidget);
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
