import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/fotos_progreso.dart';

/// POR QUE ESTE TEST: la miniatura recorta la foto a un cuadrado, y en una foto
/// vertical se perdia casi todo sin forma de verla entera. Vale igual para el
/// cliente, que puede quitarla, y para el entrenador, que solo la consulta.
void main() {
  final foto = FotoProgreso(
    id: 'f-1',
    registroMedidasId: 'm-1',
    rutaStorage: 'c-1/m-1/f.png',
    subidaEn: DateTime(2026, 10, 18),
  );

  final registro = RegistroMedidas(
    id: 'm-1',
    clienteId: 'c-1',
    fecha: DateTime(2026, 10, 18),
    pesoKg: 80,
    fotos: [foto],
  );

  Future<void> montar(WidgetTester tester, {required bool soloLectura}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlDeFotoProvider(
              foto,
            ).overrideWith((ref) async => Uri.parse('http://localhost/f.png')),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FotosProgreso(
                clienteId: 'c-1',
                registro: registro,
                soloLectura: soloLectura,
              ),
            ),
          ),
        ),
      );

  Image fotoCompleta(WidgetTester tester) =>
      tester.widget<Image>(find.byKey(const Key('foto_completa')));

  for (final soloLectura in [true, false]) {
    final quien = soloLectura ? 'el entrenador' : 'el cliente';

    testWidgets('$quien abre la foto entera y la cierra', (tester) async {
      await montar(tester, soloLectura: soloLectura);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ver_foto_f-1')));
      await tester.pumpAndSettle();

      // Entera, no recortada como en la miniatura.
      expect(fotoCompleta(tester).fit, BoxFit.contain);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byKey(const Key('cerrar_foto')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('foto_completa')), findsNothing);
    });
  }

  testWidgets('quitar sigue al alcance del cliente, y solo del cliente', (
    tester,
  ) async {
    const quitar = Key('eliminar_foto_f-1');

    await montar(tester, soloLectura: false);
    await tester.pumpAndSettle();
    // Encima de la miniatura, que ahora tambien se puede tocar.
    expect(find.byKey(quitar).hitTestable(), findsOneWidget);

    await montar(tester, soloLectura: true);
    await tester.pumpAndSettle();
    expect(find.byKey(quitar), findsNothing);
  });

  testWidgets('si no carga, lo dice en vez de quedarse en negro', (
    tester,
  ) async {
    await montar(tester, soloLectura: true);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ver_foto_f-1')));
    await tester.pumpAndSettle();

    // En los tests no hay red: la imagen siempre falla.
    expect(
      find.textContaining('No se ha podido cargar la foto'),
      findsOneWidget,
    );
  });
}
