import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';

ErrorApp _traducir({String? code, String statusCode = '400'}) =>
    AutenticacionRepositorioSupabase.traducirErrorAuth(
      AuthException('mensaje de GoTrue', statusCode: statusCode, code: code),
    );

void main() {
  group('CU-01: traduccion de errores de Auth', () {
    test('un cliente dado de baja ve "cuenta no disponible", no "credenciales '
        'incorrectas"', () {
      // Verificado contra Supabase local: tras `ban_duration`, el login con la
      // contrasena correcta responde error_code `user_banned` con statusCode
      // 400, el mismo status que las credenciales invalidas. El codigo tiene
      // que mandar sobre el status, o el cliente de baja veria el mensaje
      // equivocado.
      expect(_traducir(code: 'user_banned'), isA<ErrorCuentaNoDisponible>());
    });

    test('credenciales incorrectas', () {
      expect(
        _traducir(code: 'invalid_credentials'),
        isA<ErrorCredencialesInvalidas>(),
      );
    });

    test('un cliente invitado que aun no activo su cuenta', () {
      expect(
        _traducir(code: 'email_not_confirmed'),
        isA<ErrorCuentaSinActivar>(),
      );
    });

    test('enlace de recuperación caducado', () {
      expect(_traducir(code: 'otp_expired'), isA<ErrorEnlaceCaducado>());
    });

    test('límite de peticiones', () {
      expect(
        _traducir(code: 'over_request_rate_limit'),
        isA<ErrorDemasiadasPeticiones>(),
      );
      expect(_traducir(statusCode: '429'), isA<ErrorDemasiadasPeticiones>());
    });

    test('sin código, cae al statusCode', () {
      expect(_traducir(), isA<ErrorCredencialesInvalidas>());
      expect(_traducir(statusCode: '403'), isA<ErrorCuentaNoDisponible>());
    });

    test(
      'un status desconocido no se confunde con un fallo de credenciales',
      () {
        expect(_traducir(statusCode: '503'), isA<ErrorInesperado>());
      },
    );
  });
}
