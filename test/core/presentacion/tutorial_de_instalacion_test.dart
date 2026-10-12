import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/tutorial_de_instalacion.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';

/// POR QUE ESTE TEST: esto es una PWA, no hay ficha en ninguna tienda que
/// explique cómo instalarla, y en iPhone el push **no existe** hasta que la app
/// está en la pantalla de inicio. Si el tutorial se queda sin los pasos de una
/// de las dos plataformas, nadie se entera hasta que un cliente no puede.
void main() {
  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.oscuro(),
        home: const Scaffold(
          body: SingleChildScrollView(child: TutorialDeInstalacion()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empieza plegado: es un paso que se da una vez', (tester) async {
    await montar(tester);

    expect(find.text('Instalar la app en el móvil'), findsOneWidget);
    expect(find.text('iPhone y iPad'), findsNothing);
  });

  testWidgets('al abrirlo están las dos plataformas con sus pasos', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('tutorial_instalacion')));
    await tester.pumpAndSettle();

    expect(find.text('iPhone y iPad'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    // Lo que más se falla: en iOS tiene que ser Safari, porque Chrome allí no
    // puede instalar nada.
    expect(find.text('Tiene que ser con Safari.'), findsOneWidget);
    expect(
      find.textContaining('Añadir a pantalla de inicio'),
      findsOneWidget,
    );
    expect(find.textContaining('Instalar aplicación'), findsWidgets);
  });
}
