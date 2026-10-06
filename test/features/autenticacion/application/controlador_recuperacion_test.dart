import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';

class RepositorioFalso extends Mock implements AutenticacionRepositorio {}

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

  group('ControladorSolicitudRecuperacion (CU-24)', () {
    ControladorSolicitudRecuperacion controlador() =>
        contenedor.read(controladorSolicitudRecuperacionProvider.notifier);

    test('no llama al repositorio con un correo invalido', () async {
      await controlador().solicitarEnlace('no-es-un-correo');

      expect(
        contenedor
            .read(controladorSolicitudRecuperacionProvider)
            .errorDelCampo('correo'),
        isNotNull,
      );
      verifyNever(() => repositorio.enviarCorreoRecuperacion(any()));
    });

    test('envía el correo normalizado', () async {
      when(() => repositorio.enviarCorreoRecuperacion(any()))
          .thenAnswer((_) async => const Success(null));

      await controlador().solicitarEnlace('  Aimar@Ejemplo.COM ');

      verify(() => repositorio.enviarCorreoRecuperacion('aimar@ejemplo.com'))
          .called(1);
      expect(
        contenedor.read(controladorSolicitudRecuperacionProvider).completada,
        isTrue,
      );
    });

    test('propaga el límite de envios', () async {
      when(() => repositorio.enviarCorreoRecuperacion(any()))
          .thenAnswer((_) async => const Failure(ErrorDemasiadasPeticiones()));

      await controlador().solicitarEnlace('aimar@ejemplo.com');

      final estado = contenedor.read(controladorSolicitudRecuperacionProvider);
      expect(estado.error, const ErrorDemasiadasPeticiones());
      expect(estado.completada, isFalse);
    });
  });

  group('ControladorRestablecerContrasena (CU-24)', () {
    ControladorRestablecerContrasena controlador() =>
        contenedor.read(controladorRestablecerContrasenaProvider.notifier);

    test('rechaza una contraseña demasiado corta', () async {
      await controlador().establecerContrasena(
        contrasena: 'corta',
        repeticion: 'corta',
      );

      expect(
        contenedor
            .read(controladorRestablecerContrasenaProvider)
            .errorDelCampo('contrasena'),
        isNotNull,
      );
      verifyNever(() => repositorio.establecerNuevaContrasena(any()));
    });

    test('rechaza que las dos contraseñas no coincidan', () async {
      await controlador().establecerContrasena(
        contrasena: 'secreto123',
        repeticion: 'secreto124',
      );

      expect(
        contenedor
            .read(controladorRestablecerContrasenaProvider)
            .errorDelCampo('repeticion'),
        isNotNull,
      );
      verifyNever(() => repositorio.establecerNuevaContrasena(any()));
    });

    test('guarda la contraseña cuando los datos son validos', () async {
      when(() => repositorio.establecerNuevaContrasena(any()))
          .thenAnswer((_) async => const Success(null));

      await controlador().establecerContrasena(
        contrasena: 'secreto123',
        repeticion: 'secreto123',
      );

      verify(() => repositorio.establecerNuevaContrasena('secreto123'))
          .called(1);
      expect(
        contenedor.read(controladorRestablecerContrasenaProvider).completada,
        isTrue,
      );
    });

    test('propaga el enlace caducado', () async {
      when(() => repositorio.establecerNuevaContrasena(any()))
          .thenAnswer((_) async => const Failure(ErrorEnlaceCaducado()));

      await controlador().establecerContrasena(
        contrasena: 'secreto123',
        repeticion: 'secreto123',
      );

      expect(
        contenedor.read(controladorRestablecerContrasenaProvider).error,
        const ErrorEnlaceCaducado(),
      );
    });
  });
}
