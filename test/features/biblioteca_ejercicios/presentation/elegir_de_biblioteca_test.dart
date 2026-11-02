import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/elegir_de_biblioteca.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../../planificacion_semanal/ayudas_planificacion.dart';

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: Aimar se quejaba de tres clics para filtrar por un musculo
/// y de tener que bajar mucho despues hasta los ejercicios. Lo que importa es
/// eso: musculos a un clic, y la lista arriba sin que el filtro la empuje.
void main() {
  late EjerciciosFalso biblioteca;

  Ejercicio de(String id, Musculo musculo) => ejercicioDePrueba(
    id: id,
    nombre: 'Ejercicio $id',
  ).copyWith(musculoPrincipal: musculo);

  final ejercicios = [
    for (var i = 0; i < 40; i++) de('c$i', Musculo.cuadriceps),
    de('glu', Musculo.gluteo),
  ];

  setUp(() {
    biblioteca = EjerciciosFalso();
    when(() => biblioteca.listar())
        .thenAnswer((_) async => Success(ejercicios));
  });

  Future<void> montar(
    WidgetTester tester, {
    double anchoPanel = 1000,
    Ejercicio? elegido,
  }) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          ejercicioRepositorioProvider.overrideWithValue(biblioteca),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: anchoPanel,
                child: ElegirDeBiblioteca(
                  ambito: AmbitoDeFiltro.formularioBloque,
                  prefijoClave: 'elegir',
                  habilitado: true,
                  enPanel: true,
                  elegido: elegido,
                  onElegir: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fila(String id) => find.byKey(Key('elegir_$id'));

  group('con sitio, en columnas', () {
    testWidgets('un solo clic en el músculo filtra la lista', (tester) async {
      await montar(tester);

      // Sin abrir nada: ni desplegable del filtro ni del grupo.
      expect(find.byKey(const Key('filtro_muscular')), findsNothing);

      await tester.tap(find.byKey(const Key('musculo_gluteo')));
      await tester.pumpAndSettle();

      expect(fila('glu'), findsOneWidget);
      expect(fila('c0'), findsNothing);
    });

    testWidgets('el nombre del grupo filtra por el grupo entero', (
      tester,
    ) async {
      await montar(tester);

      await tester.tap(find.byKey(const Key('musculo_gluteo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('todo_pierna')));
      await tester.pumpAndSettle();

      expect(fila('c0'), findsOneWidget);
    });

    testWidgets('bajar por la lista no se lleva los filtros', (tester) async {
      await montar(tester);
      final antes = tester.getTopLeft(
        find.byKey(const Key('musculo_cuadriceps')),
      );

      await tester.drag(fila('c4'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(fila('c0'), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('musculo_cuadriceps'))),
        antes,
      );
    });

    testWidgets('al filtrar, la lista vuelve a empezar arriba', (tester) async {
      await montar(tester);

      await tester.drag(fila('c4'), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(fila('c0'), findsNothing);

      // Filtra y deja tantos como para seguir desplazandose: el grupo entero.
      await tester.tap(find.byKey(const Key('todo_pierna')));
      await tester.pumpAndSettle();

      expect(fila('c0'), findsOneWidget);
    });

    testWidgets('con mucho ancho, los ejercicios van en varias columnas', (
      tester,
    ) async {
      await montar(tester, anchoPanel: 1500);

      expect(
        tester.getTopLeft(fila('c1')).dy,
        tester.getTopLeft(fila('c0')).dy,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('la lista de una columna no desborda en el ancho mínimo', (
      tester,
    ) async {
      await montar(tester, anchoPanel: 640);

      expect(find.byKey(const Key('columna_filtros')), findsOneWidget);
      expect(
        tester.getTopLeft(fila('c1')).dy,
        greaterThan(tester.getTopLeft(fila('c0')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('en un panel estrecho sigue el filtro plegable', (tester) async {
    await montar(tester, anchoPanel: 420);

    expect(find.byKey(const Key('columna_filtros')), findsNothing);
    expect(find.byKey(const Key('filtro_muscular')), findsOneWidget);
  });

  group('el cursor en el buscador', () {
    bool conFoco(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(const Key('busqueda_ejercicio')))
        .autofocus;

    testWidgets('al añadir, sí', (tester) async {
      await montar(tester);

      expect(conFoco(tester), isTrue);
    });

    testWidgets('al editar, no', (tester) async {
      await montar(tester, elegido: ejercicios.first);

      expect(conFoco(tester), isFalse);
    });
  });
}
