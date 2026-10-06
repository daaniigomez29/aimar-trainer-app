import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_login.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

class RepositorioFalso extends Mock implements AutenticacionRepositorio {}

final _perfilEntrenador = Perfil(
  id: 'id-entrenador',
  rol: RolUsuario.entrenador,
  creadoEn: DateTime.utc(2026),
);

void main() {
  late RepositorioFalso repositorio;
  late ProviderContainer contenedor;

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => repositorio.debeFijarContrasena).thenReturn(false);
    contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(repositorio),
      ],
    );
    addTearDown(contenedor.dispose);
  });

  ControladorLogin controlador() =>
      contenedor.read(controladorLoginProvider.notifier);

  test('parte de un estado inicial vacío', () {
    final estado = contenedor.read(controladorLoginProvider);

    expect(estado.enCurso, isFalse);
    expect(estado.completada, isFalse);
    expect(estado.error, isNull);
  });

  test('no llama al repositorio si el correo no es valido', () async {
    await controlador().iniciarSesion(correo: 'mal', contrasena: 'secreto123');

    final estado = contenedor.read(controladorLoginProvider);
    expect(estado.errorDelCampo('correo'), isNotNull);
    verifyNever(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    );
  });

  test('no llama al repositorio si falta la contraseña', () async {
    await controlador().iniciarSesion(
      correo: 'aimar@ejemplo.com',
      contrasena: '',
    );

    expect(
      contenedor.read(controladorLoginProvider).errorDelCampo('contrasena'),
      isNotNull,
    );
    verifyNever(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    );
  });

  test(
    'envía el correo normalizado y marca la accion como completada',
    () async {
      when(
        () => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => Success(_perfilEntrenador));

      await controlador().iniciarSesion(
        correo: '  Aimar@Ejemplo.COM ',
        contrasena: 'secreto123',
      );

      expect(contenedor.read(controladorLoginProvider).completada, isTrue);
      verify(
        () => repositorio.iniciarSesion(
          correo: 'aimar@ejemplo.com',
          contrasena: 'secreto123',
        ),
      ).called(1);
    },
  );

  test(
    'propaga el error de credenciales incorrectas (CU-01, excepcion)',
    () async {
      when(
        () => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const Failure(ErrorCredencialesInvalidas()));

      await controlador().iniciarSesion(
        correo: 'aimar@ejemplo.com',
        contrasena: 'incorrecta',
      );

      final estado = contenedor.read(controladorLoginProvider);
      expect(estado.error, const ErrorCredencialesInvalidas());
      expect(estado.errorGeneral, isNotNull);
      expect(estado.completada, isFalse);
    },
  );

  test('propaga el error de cuenta dada de baja (CU-01, excepcion)', () async {
    when(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) async => const Failure(ErrorCuentaNoDisponible()));

    await controlador().iniciarSesion(
      correo: 'debaja@ejemplo.com',
      contrasena: 'secreto123',
    );

    expect(
      contenedor.read(controladorLoginProvider).error,
      const ErrorCuentaNoDisponible(),
    );
  });

  test('ignora un segundo envio mientras el primero esta en curso', () async {
    final pendiente = Completer<Result<Perfil>>();
    when(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) => pendiente.future);

    final primero = controlador().iniciarSesion(
      correo: 'aimar@ejemplo.com',
      contrasena: 'secreto123',
    );
    expect(contenedor.read(controladorLoginProvider).enCurso, isTrue);

    await controlador().iniciarSesion(
      correo: 'aimar@ejemplo.com',
      contrasena: 'secreto123',
    );

    pendiente.complete(Success(_perfilEntrenador));
    await primero;

    verify(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).called(1);
  });

  test('limpiarError vuelve al estado inicial', () async {
    when(
      () => repositorio.iniciarSesion(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) async => const Failure(ErrorCredencialesInvalidas()));
    await controlador().iniciarSesion(
      correo: 'aimar@ejemplo.com',
      contrasena: 'incorrecta',
    );

    controlador().limpiarError();

    expect(contenedor.read(controladorLoginProvider).error, isNull);
  });
}
