import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/url_de_arranque.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_restablecer_contrasena.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

/// El fallo del 2026-10-12: el cliente invitado pierde la pantalla de fijar su
/// contrasena (se sale, o instala la PWA), vuelve a pinchar el enlace del
/// correo —que es de **un solo uso**— y se queda sin forma de establecerla.
void main() {
  late AutenticacionFalsa autenticacion;
  late StreamController<EventoAutenticacion> eventos;

  setUp(() {
    autenticacion = AutenticacionFalsa();
    eventos = StreamController<EventoAutenticacion>.broadcast();
    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => eventos.stream);
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn(null);
    addTearDown(eventos.close);
  });

  /// Monta la pantalla tal como la abre el enlace del correo: lo que decide el
  /// modo es la URL de arranque, igual que en produccion.
  Future<void> montar(WidgetTester tester, {required String url}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            autenticacionRepositorioProvider.overrideWithValue(autenticacion),
            urlDeArranqueProvider.overrideWithValue(Uri.parse(url)),
          ],
          child: const MaterialApp(home: PantallaRestablecerContrasena()),
        ),
      );

  const enlaceGastado =
      'https://app.es/#error=access_denied&error_code=otp_expired';

  testWidgets('con el enlace gastado no se pide una contraseña imposible', (
    tester,
  ) async {
    await montar(tester, url: enlaceGastado);

    expect(find.text('Este enlace ya no vale'), findsOneWidget);
    // Lo que no puede pasar: ofrecer un formulario que no tiene donde guardar.
    expect(find.byKey(const Key('campo_contrasena')), findsNothing);
    expect(find.byKey(const Key('boton_guardar_contrasena')), findsNothing);
  });

  testWidgets('ofrece pedir otro enlace sin salir de la pantalla', (
    tester,
  ) async {
    when(() => autenticacion.enviarCorreoRecuperacion(any()))
        .thenAnswer((_) async => const Success(null));
    await montar(tester, url: enlaceGastado);

    await tester.enterText(
      find.byKey(const Key('campo_correo')),
      'cliente@correo.es',
    );
    await tester.tap(find.byKey(const Key('boton_enviar_enlace')));
    await tester.pumpAndSettle();

    verify(() => autenticacion.enviarCorreoRecuperacion('cliente@correo.es'))
        .called(1);
    expect(find.text('Revisa tu correo'), findsOneWidget);
  });

  testWidgets('con el enlace bueno se fija la contraseña, como siempre', (
    tester,
  ) async {
    when(() => autenticacion.idUsuarioActual).thenReturn('id-invitado');
    when(() => autenticacion.debeFijarContrasena).thenReturn(true);
    await montar(tester, url: 'https://app.es/');

    eventos.add(EventoAutenticacion.sesionIniciada);
    await tester.pumpAndSettle();

    expect(find.text('Elige tu contraseña'), findsOneWidget);
    expect(find.byKey(const Key('campo_contrasena')), findsOneWidget);
    // Sin salida al login: no tiene ninguna contrasena que escribir alli.
    expect(find.text('Volver al acceso'), findsNothing);
  });

  testWidgets('un invitado que llega por recuperación ve su propio texto', (
    tester,
  ) async {
    // Es el rescate: el entrenador (o el propio cliente) pide un enlace de
    // recuperacion, pero sigue sin tener contrasena, asi que no es una
    // "contraseña nueva" ni se le ofrece volver al acceso.
    when(() => autenticacion.idUsuarioActual).thenReturn('id-invitado');
    when(() => autenticacion.debeFijarContrasena).thenReturn(true);
    await montar(tester, url: 'https://app.es/');

    eventos.add(EventoAutenticacion.recuperacionContrasena);
    await tester.pumpAndSettle();

    expect(find.text('Elige tu contraseña'), findsOneWidget);
    expect(find.text('Volver al acceso'), findsNothing);
  });
}
