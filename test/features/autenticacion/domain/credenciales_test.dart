import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/autenticacion/domain/credenciales.dart';

void main() {
  group('Credenciales.validarCorreo', () {
    test('rechaza el correo vacio', () {
      expect(Credenciales.validarCorreo('   ')?.campo, 'correo');
    });

    test('rechaza formatos sin arroba o sin dominio', () {
      for (final invalido in [
        'sin-arroba.com',
        'sin@dominio',
        'dos@@arrobas.com',
        'con espacio@dominio.com',
      ]) {
        expect(
          Credenciales.validarCorreo(invalido),
          isNotNull,
          reason: 'deberia rechazar "$invalido"',
        );
      }
    });

    test('acepta un correo valido con espacios alrededor', () {
      expect(Credenciales.validarCorreo('  aimar@ejemplo.com '), isNull);
    });
  });

  group('Credenciales.validarContrasenaDeAcceso', () {
    test('solo exige que no este vacia', () {
      expect(Credenciales.validarContrasenaDeAcceso('')?.campo, 'contrasena');
      expect(Credenciales.validarContrasenaDeAcceso('corta'), isNull);
    });
  });

  group('Credenciales.validarContrasenaNueva', () {
    test('exige la longitud minima', () {
      final corta = 'a' * (Credenciales.longitudMinimaContrasena - 1);

      expect(Credenciales.validarContrasenaNueva(corta)?.campo, 'contrasena');
    });

    test('acepta una contrasena con la longitud minima justa', () {
      final valida = 'a' * Credenciales.longitudMinimaContrasena;

      expect(Credenciales.validarContrasenaNueva(valida), isNull);
    });
  });

  group('Credenciales', () {
    test('normaliza el correo a minusculas y sin espacios', () {
      const credenciales = Credenciales(
        correo: '  Aimar@Ejemplo.COM  ',
        contrasena: 'secreto123',
      );

      expect(credenciales.correoNormalizado, 'aimar@ejemplo.com');
    });

    test('validar devuelve primero el error de correo', () {
      const credenciales = Credenciales(correo: 'mal', contrasena: '');

      expect(credenciales.validar()?.campo, 'correo');
    });

    test('validar devuelve null cuando ambos campos son validos', () {
      const credenciales = Credenciales(
        correo: 'aimar@ejemplo.com',
        contrasena: 'secreto123',
      );

      expect(credenciales.validar(), isNull);
    });
  });
}
