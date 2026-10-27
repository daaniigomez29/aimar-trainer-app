import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/data/pack_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack_repositorio.dart';
import 'package:aimar_trainer_app/features/packs/presentation/pantalla_pack.dart';
import 'package:aimar_trainer_app/features/packs/presentation/pantalla_packs.dart';

import '../../../ayudas/app_con_rutas.dart';
import '../../../ayudas/sesion_falsa.dart';

class PackFalso extends Mock implements PackRepositorio {}

/// POR QUE ESTE TEST: la lista tiene que avisar de los packs **vacíos**, porque
/// un pack sin ejercicios no se puede aplicar a ningún bloque y eso solo se
/// descubriría al intentarlo. Y la ficha tiene que mandar la lista **entera** al
/// reordenar: la función de Postgres renumera del 1 al N y rechaza una lista
/// incompleta.
void main() {
  late PackFalso repositorio;

  Ejercicio ejercicio(String id, String nombre, {bool activo = true}) =>
      Ejercicio(
        id: id,
        nombre: nombre,
        descripcion: 'Descripción.',
        tipo: TipoEjercicio.fuerza,
        estado: activo ? EstadoEjercicio.activo : EstadoEjercicio.eliminado,
        creadoEn: DateTime.utc(2026),
      );

  PackEjercicio delPack(String id, int orden, Ejercicio ficha) => PackEjercicio(
    id: id,
    packId: 'p-1',
    ejercicioId: ficha.id,
    orden: orden,
    ejercicio: ficha,
  );

  Pack pack({
    List<PackEjercicio> ejercicios = const [],
    List<TipoEjercicio> tipos = const [TipoEjercicio.fuerza],
  }) => Pack(
    id: 'p-1',
    nombre: 'Torso A',
    tipos: tipos,
    creadoEn: DateTime.utc(2026, 10, 19),
    ejercicios: ejercicios,
  );

  setUpAll(() {
    registerFallbackValue(
      const DatosPack(nombre: 'x', tipos: {TipoEjercicio.fuerza}),
    );
  });

  setUp(() {
    repositorio = PackFalso();
  });

  Future<void> montar(
    WidgetTester tester, {
    required List<Pack> lista,
    String rutaInicial = Rutas.packsEntrenador,
  }) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => repositorio.listar()).thenAnswer((_) async => Success(lista));
    when(() => repositorio.obtener(any())).thenAnswer((invocacion) async {
      final id = invocacion.positionalArguments.first as String;
      final encontrado = lista.where((p) => p.id == id).firstOrNull;
      return encontrado == null
          ? const Failure(ErrorNoEncontrado('Ese pack ya no existe.'))
          : Success(encontrado);
    });

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          packRepositorioProvider.overrideWithValue(repositorio),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: appConRutas(
          rutaInicial: rutaInicial,
          // Con el tema de verdad: el suyo da a los `FilledButton` ancho minimo
          // infinito, y sin el el boton de "Nuevo pack" dentro de una `Row`
          // pasaba aqui y reventaba en la app.
          tema: TemaApp.oscuro(),
          rutas: [
            GoRoute(
              path: Rutas.packsEntrenador,
              builder: (_, _) => const PantallaPacks(),
              routes: [
                GoRoute(
                  path: Rutas.unPack,
                  builder: (_, estado) =>
                      PantallaPack(packId: estado.pathParameters['packId']!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin packs, explica para qué sirven', (tester) async {
    await montar(tester, lista: const []);

    expect(find.text('Todavía no hay packs'), findsOneWidget);
    expect(find.byKey(const Key('boton_nuevo_pack')), findsOneWidget);
  });

  testWidgets('un pack vacío avisa de que no se puede aplicar', (tester) async {
    await montar(tester, lista: [pack()]);

    expect(find.text('Sin ejercicios · no se puede aplicar'), findsOneWidget);
  });

  testWidgets('con ejercicios, dice cuántos y de qué tipo', (tester) async {
    await montar(
      tester,
      lista: [
        pack(
          ejercicios: [
            delPack('pe-1', 1, ejercicio('ej-1', 'Press banca')),
            delPack('pe-2', 2, ejercicio('ej-2', 'Dominadas')),
          ],
        ),
      ],
    );

    expect(find.text('2 ejercicios · Fuerza'), findsOneWidget);
  });

  testWidgets('se entra al pack desde la lista', (tester) async {
    await montar(
      tester,
      lista: [
        pack(
          ejercicios: [delPack('pe-1', 1, ejercicio('ej-1', 'Press banca'))],
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('pack_p-1')));
    await tester.pumpAndSettle();

    expect(find.text('Press banca'), findsOneWidget);
    expect(find.byKey(const Key('boton_anadir_al_pack')), findsOneWidget);
  });

  group('la ficha del pack', () {
    final conDos = pack(
      ejercicios: [
        delPack('pe-1', 1, ejercicio('ej-1', 'Press banca')),
        delPack('pe-2', 2, ejercicio('ej-2', 'Dominadas')),
      ],
    );

    testWidgets('reordenar manda la lista entera en su orden nuevo', (
      tester,
    ) async {
      when(
        () => repositorio.reordenarEjercicios(
          packId: any(named: 'packId'),
          idsEnOrden: any(named: 'idsEnOrden'),
        ),
      ).thenAnswer((_) async => const Success(null));

      await montar(
        tester,
        lista: [conDos],
        rutaInicial: Rutas.packConcreto('p-1'),
      );

      await tester.tap(find.byKey(const Key('bajar_0')));
      await tester.pumpAndSettle();

      verify(
        () => repositorio.reordenarEjercicios(
          packId: 'p-1',
          idsEnOrden: const ['pe-2', 'pe-1'],
        ),
      ).called(1);
    });

    testWidgets('un ejercicio sin nada preparado lo dice', (tester) async {
      await montar(
        tester,
        lista: [conDos],
        rutaInicial: Rutas.packConcreto('p-1'),
      );

      expect(
        find.text('Sin nada preparado · se rellena al planificar'),
        findsNWidgets(2),
      );
    });

    testWidgets('un ejercicio dado de baja se marca', (tester) async {
      await montar(
        tester,
        lista: [
          pack(
            ejercicios: [
              delPack(
                'pe-1',
                1,
                ejercicio('ej-1', 'Press banca', activo: false),
              ),
            ],
          ),
        ],
        rutaInicial: Rutas.packConcreto('p-1'),
      );

      expect(find.text('DE BAJA'), findsOneWidget);
    });
  });

  // Desde el 2026-10-27 un pack puede llevar varias etiquetas de tipo.
  group('etiquetas de tipo', () {
    testWidgets('un pack mixto se lee con sus dos tipos', (tester) async {
      await montar(
        tester,
        lista: [
          pack(
            tipos: const [TipoEjercicio.fuerza, TipoEjercicio.cardio],
            ejercicios: [
              delPack('pe-1', 1, ejercicio('ej-1', 'Press banca')),
              delPack('pe-2', 2, ejercicio('ej-2', 'Dominadas')),
            ],
          ),
        ],
      );

      expect(find.text('2 ejercicios · Fuerza + Cardio'), findsOneWidget);
    });

    testWidgets('al crear se pueden elegir varios tipos', (tester) async {
      when(() => repositorio.crear(any())).thenAnswer(
        (_) async => Success(pack(tipos: const [TipoEjercicio.fuerza])),
      );
      await montar(tester, lista: const []);

      await tester.tap(find.byKey(const Key('boton_nuevo_pack')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_nombre_pack')),
        'Mixto',
      );
      // Fuerza viene marcado; se anade Cardio.
      await tester.tap(find.byKey(const Key('tipo_pack_cardio')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('boton_guardar_pack')));
      await tester.pumpAndSettle();

      final datos =
          verify(() => repositorio.crear(captureAny())).captured.single
              as DatosPack;
      expect(datos.tipos, {TipoEjercicio.fuerza, TipoEjercicio.cardio});
    });

    testWidgets('sin ningún tipo no se guarda y lo dice', (tester) async {
      await montar(tester, lista: const []);

      await tester.tap(find.byKey(const Key('boton_nuevo_pack')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_nombre_pack')),
        'Sin tipo',
      );
      await tester.tap(find.byKey(const Key('tipo_pack_fuerza')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('boton_guardar_pack')));
      await tester.pumpAndSettle();

      expect(find.text('Elige al menos un tipo para el pack.'), findsOneWidget);
      verifyNever(() => repositorio.crear(any()));
    });
  });
}
