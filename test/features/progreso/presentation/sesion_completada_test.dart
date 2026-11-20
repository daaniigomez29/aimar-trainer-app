import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_sesion_completada.dart';

import '../../../ayudas/app_con_rutas.dart';
import '../../../ayudas/sesion_falsa.dart';
import '../../planificacion_semanal/ayudas_planificacion.dart';

/// POR QUE ESTE TEST: terminar un entrenamiento tiene que ser gratificante,
/// pero sin estorbar. Lo que importa: que diga lo hecho y lo mejorado, que un
/// toque salte la animacion, que respete "reducir movimiento" y que lleve de
/// vuelta al dia terminado.
void main() {
  SerieRealizada hecha(int numero, int reps, double peso) => SerieRealizada(
    id: 'r$numero',
    ejercicioPlanificadoId: 'ep-1',
    numeroSerie: numero,
    repeticionesRealizadas: reps,
    fechaHoraRegistro: DateTime(2026),
    pesoReal: peso,
  );

  final press = ejercicioPlanificadoDePrueba(
    ejercicio: ejercicioDePrueba(id: 'ej-press', nombre: 'Press banca'),
    series: [
      serieDePrueba(numeroSerie: 1, peso: 60),
      serieDePrueba(id: 'sp-2', numeroSerie: 2, peso: 60),
    ],
  ).copyWith(seriesRealizadas: [hecha(1, 10, 62.5), hecha(2, 10, 62.5)]);

  final sesion = sesionDePrueba(
    orden: 2,
    nombre: 'Empuje',
    bloques: [
      bloqueDePrueba(ejercicios: [press]),
    ],
  );

  ReferenciaAnterior antes(double peso) => ReferenciaAnterior(
    series: [hecha(1, 10, peso)],
    fecha: DateTime(2026, 10, 1),
    esSemanaAnterior: true,
  );

  Future<void> montar(
    WidgetTester tester, {
    Map<String, ReferenciaAnterior> ultimaVez = const {},
    bool sinAnimaciones = false,
    bool esperar = true,
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(rol: RolUsuario.cliente),
          ),
          referenciasDeSesionProvider(
            'p-1',
            2,
          ).overrideWith((ref) async => ultimaVez),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(900, 1600),
            disableAnimations: sinAnimaciones,
          ),
          child: appConRutas(
            rutaInicial: '/fin',
            tema: TemaApp.oscuro(),
            rutas: [
              GoRoute(
                path: Rutas.inicioCliente,
                builder: (context, state) => Text(
                  'mi planning '
                  'dia=${state.uri.queryParameters[Rutas.paramDia] ?? '-'}',
                ),
              ),
              GoRoute(
                path: '/fin',
                builder: (context, state) =>
                    PantallaSesionCompletada(planningId: 'p-1', sesion: sesion),
              ),
            ],
          ),
        ),
      ),
    );
    if (esperar) await tester.pumpAndSettle();
  }

  String cifra(WidgetTester tester, String clave) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(Key(clave)),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data)
      .join(' ');

  testWidgets('dice lo hecho, ya con sus cifras finales', (tester) async {
    await montar(tester);

    expect(find.text('¡Sesión completada!'), findsOneWidget);
    expect(find.text('Día 2 · Empuje'), findsOneWidget);
    expect(cifra(tester, 'cifra_series'), contains('2'));
    // 62,5 x 10 x 2.
    expect(cifra(tester, 'cifra_volumen'), contains('1.250 kg'));
    // Sin cardio, no hay cifra de cardio.
    expect(find.byKey(const Key('cifra_cardio')), findsNothing);
  });

  testWidgets('celebra lo que ha superado de la última vez', (tester) async {
    await montar(tester, ultimaVez: {'ej-press': antes(60)});

    expect(find.byKey(const Key('mejora_Press banca')), findsOneWidget);
    expect(find.text('+2,5 kg'), findsOneWidget);
    // Respecto a que: el cliente no tiene por que recordarlo.
    expect(
      find.text('60 → 62,5 kg · respecto a la semana pasada'),
      findsOneWidget,
    );
  });

  testWidgets('si iguala sus marcas, lo dice sin inventar mejoras', (
    tester,
  ) async {
    await montar(tester, ultimaVez: {'ej-press': antes(62.5)});

    expect(find.byKey(const Key('sin_mejoras')), findsOneWidget);
    expect(find.byKey(const Key('mejora_Press banca')), findsNothing);
  });

  testWidgets('sin una vez anterior, no habla de mejoras', (tester) async {
    await montar(tester);

    expect(find.byKey(const Key('sin_mejoras')), findsNothing);
    expect(find.text('Has superado la última vez'), findsNothing);
  });

  testWidgets('un toque salta la animación', (tester) async {
    await montar(tester, esperar: false);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('sesion_completada')));
    await tester.pump();

    expect(cifra(tester, 'cifra_volumen'), contains('1.250 kg'));
    // Los retardos de las entradas que se descartaron siguen en el reloj y
    // no piden fotogramas, asi que `pumpAndSettle` no los alcanza.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('con "reducir movimiento" sale ya quieta', (tester) async {
    await montar(tester, sinAnimaciones: true, esperar: false);
    await tester.pump();

    expect(cifra(tester, 'cifra_volumen'), contains('1.250 kg'));
    await tester.pumpAndSettle();
  });

  testWidgets('vuelve al día que acaba de terminar', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('volver_al_planning')));
    await tester.pumpAndSettle();

    expect(find.text('mi planning dia=2'), findsOneWidget);
  });
}
