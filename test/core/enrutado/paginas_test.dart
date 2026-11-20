import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/enrutado/paginas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';

import '../../ayudas/sesion_falsa.dart';

/// POR QUE ESTE TEST: las secciones principales cuelgan de la ruta de inicio,
/// y la cabecera ponia sola una flecha de atras en todas menos en Biblioteca.
/// Peticion de Daniel (2026-11-20): sin flecha en las secciones, con flecha
/// y deslizando solo en lo que se abre dentro de una seccion.
void main() {
  Widget pantalla(String titulo, {VoidCallback? alPulsar}) => Scaffold(
    appBar: AppBar(title: Text(titulo)),
    body: TextButton(onPressed: alPulsar, child: const Text('entrar')),
    // Como la barra de la app: va dentro de cada pantalla.
    bottomNavigationBar: FijoEnLaTransicion(
      child: SizedBox(key: Key('barra_$titulo'), height: 56),
    ),
  );

  /// `/inicio` > `seccion` (de la barra) > `vista` (dentro de la seccion).
  Future<GoRouter> montar(
    WidgetTester tester, {
    bool sinAnimaciones = false,
  }) async {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/inicio/seccion',
      routes: [
        GoRoute(
          path: '/inicio',
          builder: (context, state) => pantalla('Inicio'),
          routes: [
            GoRoute(
              path: 'seccion',
              pageBuilder: (context, state) => PaginaDeSeccion(
                key: state.pageKey,
                child: pantalla(
                  'Seccion',
                  alPulsar: () => router.go('/inicio/seccion/vista'),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'vista',
                  // Como en la app: con `builder`, go_router monta la pagina
                  // sin transicion (ver `paginaDeVista`).
                  pageBuilder: (context, state) =>
                      paginaDeVista(state, pantalla('Vista')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MediaQuery(
        // Con el tamano de la pantalla: sin el, la app lee un ancho de 0.
        data: MediaQueryData.fromView(tester.view)
            .copyWith(disableAnimations: sinAnimaciones),
        child: MaterialApp.router(
          theme: TemaApp.oscuro(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// La pantalla de la vista: el `Scaffold` que contiene su titulo.
  Finder vista() =>
      find.ancestor(of: find.text('Vista'), matching: find.byType(Scaffold));

  Finder barraDeLaVista() => find.byKey(const Key('barra_Vista'));

  double ancho(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  testWidgets('una sección no tiene flecha aunque cuelgue de otra ruta', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Seccion'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('lo que se abre dentro de una sección sí la tiene', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.text('entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Vista'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('la vista entra deslizándose desde la derecha', (tester) async {
    await montar(tester);

    await tester.tap(find.text('entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // A medio camino: ni fuera ni en su sitio. Se mide la pantalla entera,
    // no el titulo, que nunca esta en x = 0.
    final x = tester.getTopLeft(vista()).dx;
    expect(x, greaterThan(0));
    expect(x, lessThan(ancho(tester)));
    // La barra no viaja con la pantalla: sigue en su sitio.
    expect(tester.getTopLeft(barraDeLaVista()).dx, closeTo(0, 0.01));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(vista()).dx, 0);
  });

  testWidgets('al volver, sale por la derecha', (tester) async {
    await montar(tester);
    await tester.tap(find.text('entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final x = tester.getTopLeft(vista()).dx;
    expect(x, greaterThan(0));
    expect(x, lessThan(ancho(tester)));
    expect(tester.getTopLeft(barraDeLaVista()).dx, closeTo(0, 0.01));

    await tester.pumpAndSettle();
    expect(find.text('Vista'), findsNothing);
  });

  testWidgets('con "reducir movimiento" entra sin deslizar', (tester) async {
    await montar(tester, sinAnimaciones: true);

    await tester.tap(find.text('entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getTopLeft(vista()).dx, 0);
    await tester.pumpAndSettle();
  });

  group('en el enrutador de la app', () {
    /// Todas las rutas con su camino completo.
    Map<String, GoRoute> rutasDe(GoRouter router) {
      final todas = <String, GoRoute>{};
      void recorrer(List<RouteBase> rutas, String padre) {
        for (final ruta in rutas) {
          if (ruta is! GoRoute) continue;
          final camino = ruta.path.startsWith('/')
              ? ruta.path
              : '$padre/${ruta.path}';
          todas[camino] = ruta;
          recorrer(ruta.routes, camino);
        }
      }

      recorrer(router.configuration.routes, '');
      return todas;
    }

    test('ninguna ruta usa `builder`: se quedaría sin transición', () async {
      final contenedor = await conSesionAbierta(
        ProviderContainer(
          overrides: [
            autenticacionRepositorioProvider.overrideWithValue(
              AutenticacionDeMentira(),
            ),
          ],
        ),
      );
      addTearDown(contenedor.dispose);

      final conBuilder = [
        for (final MapEntry(key: camino, value: ruta) in rutasDe(
          contenedor.read(enrutadorProvider),
        ).entries)
          if (ruta.builder != null) camino,
      ];
      expect(
        conBuilder,
        isEmpty,
        reason:
            'Con `builder`, go_router monta la pagina sin transicion: usa '
            '`paginaDeVista` o `PaginaDeSeccion` en `pageBuilder`.',
      );
    });

    test('las secciones de la barra de los dos roles van sin flecha', () async {
      final contenedor = await conSesionAbierta(
        ProviderContainer(
          overrides: [
            autenticacionRepositorioProvider.overrideWithValue(
              AutenticacionDeMentira(),
            ),
          ],
        ),
      );
      addTearDown(contenedor.dispose);
      final rutas = rutasDe(contenedor.read(enrutadorProvider));

      for (final destino in [...destinosCliente, ...destinosEntrenador]) {
        final ruta = rutas[destino.ruta];
        expect(ruta, isNotNull, reason: destino.ruta);
        // La de inicio de cada rol no cuelga de nada: no necesita pagina
        // propia para quedarse sin flecha.
        if (destino.ruta.split('/').length == 2) continue;
        expect(
          ruta!.pageBuilder,
          isNotNull,
          reason: '${destino.etiqueta} tiene que usar PaginaDeSeccion',
        );
      }
    });
  });
}
