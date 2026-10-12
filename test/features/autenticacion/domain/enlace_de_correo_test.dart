import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/enlace_de_correo.dart';

/// Un enlace de invitacion o de recuperacion es de **un solo uso**. Al pinchar
/// uno gastado, GoTrue no abre sesion: redirige a la app con el motivo en la
/// URL, y eso no llega como evento de Auth. Si no se lee de aqui, la app espera
/// un evento que no va a venir.
void main() {
  test('una URL normal no dice nada', () {
    expect(errorDeEnlaceDeCorreo(Uri.parse('https://app.es/')), isNull);
    expect(
      errorDeEnlaceDeCorreo(
        Uri.parse('https://app.es/#/restablecer-contrasena'),
      ),
      isNull,
    );
  });

  test('un enlace que ha funcionado tampoco', () {
    // Asi llega el canje bueno: el token en el fragmento y ningun error.
    expect(
      errorDeEnlaceDeCorreo(
        Uri.parse('https://app.es/#access_token=abc&type=invite'),
      ),
      isNull,
    );
  });

  test('el enlace gastado o caducado llega en el fragmento', () {
    final error = errorDeEnlaceDeCorreo(
      Uri.parse(
        'https://app.es/#error=access_denied&error_code=otp_expired'
        '&error_description=Email+link+is+invalid+or+has+expired',
      ),
    );

    expect(error, isA<ErrorEnlaceCaducado>());
  });

  test('tambien si viene en la query, como en el flujo PKCE', () {
    expect(
      errorDeEnlaceDeCorreo(
        Uri.parse('https://app.es/?error_code=otp_expired'),
      ),
      isA<ErrorEnlaceCaducado>(),
    );
  });

  test('cualquier otro fallo del enlace sale como inesperado', () {
    // No se miente diciendo "ha caducado" cuando el motivo es otro, pero la
    // salida que se le ofrece al usuario es la misma: pedir otro enlace.
    expect(
      errorDeEnlaceDeCorreo(
        Uri.parse('https://app.es/#error=server_error&error_code=unexpected'),
      ),
      isA<ErrorInesperado>(),
    );
  });
}
