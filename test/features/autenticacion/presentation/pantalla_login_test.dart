import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_login.dart';

class RepositorioFalso extends Mock implements AutenticacionRepositorio {}

void main() {
  late RepositorioFalso repositorio;

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => repositorio.debeFijarContrasena).thenReturn(false);
  });

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(repositorio),
      ],
      child: const MaterialApp(home: PantallaLogin()),
    ),
  );

  Future<void> rellenarYEnviar(
    WidgetTester tester, {
    required String correo,
    required String contrasena,
  }) async {
    await tester.enterText(find.byKey(const Key('campo_correo')), correo);
    await tester.enterText(
      find.byKey(const Key('campo_contrasena')),
      contrasena,
    );
    await tester.tap(find.byKey(const Key('boton_acceder')));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los campos de acceso y el enlace de recuperacion', (
    tester,
  ) async {
    await montar(tester);

    expect(find.byKey(const Key('campo_correo')), findsOneWidget);
    expect(find.byKey(const Key('campo_contrasena')), findsOneWidget);
    expect(find.text('Acceder'), findsOneWidget);
    expect(find.text('He olvidado mi contrasena'), findsOneWidget);
  });

  testWidgets('valida el correo sin llamar al repositorio', (tester) async {
    await montar(tester);

    await rellenarYEnviar(
      tester,
      correo: 'no-es-un-correo',
      contrasena: 'secreto123',
    );

    expect(find.text('El correo no tiene un formato valido.'), findsOneWidget);
    verifyNever(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    );
  });

  testWidgets('muestra el error de credenciales incorrectas (CU-01)', (
    tester,
  ) async {
    when(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) async => const Failure(ErrorCredencialesInvalidas()));
    await montar(tester);

    await rellenarYEnviar(
      tester,
      correo: 'aimar@ejemplo.com',
      contrasena: 'incorrecta',
    );

    expect(
      find.text(const ErrorCredencialesInvalidas().mensaje),
      findsOneWidget,
    );
  });

  testWidgets('avisa de que la cuenta no esta disponible (CU-01)', (
    tester,
  ) async {
    when(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) async => const Failure(ErrorCuentaNoDisponible()));
    await montar(tester);

    await rellenarYEnviar(
      tester,
      correo: 'debaja@ejemplo.com',
      contrasena: 'secreto123',
    );

    expect(find.text(const ErrorCuentaNoDisponible().mensaje), findsOneWidget);
  });

  testWidgets('envia las credenciales al repositorio', (tester) async {
    when(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer(
      (_) async => Success(
        Perfil(
          id: 'id-entrenador',
          rol: RolUsuario.entrenador,
          creadoEn: DateTime.utc(2026),
        ),
      ),
    );
    await montar(tester);

    await rellenarYEnviar(
      tester,
      correo: 'aimar@ejemplo.com',
      contrasena: 'secreto123',
    );

    verify(
      () => repositorio.iniciarSesion(
        correo: 'aimar@ejemplo.com',
        contrasena: 'secreto123',
      ),
    ).called(1);
  });

  testWidgets('la contrasena se oculta y se puede revelar', (tester) async {
    await montar(tester);

    TextField campo() =>
        tester.widget<TextField>(find.byKey(const Key('campo_contrasena')));
    expect(campo().obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contrasena'));
    await tester.pump();

    expect(campo().obscureText, isFalse);
  });
}
