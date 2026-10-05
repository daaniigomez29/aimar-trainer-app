import 'package:aimar_trainer_app/core/errores/error_app.dart';

/// Validacion de dominio de las credenciales de acceso (CU-01, paso 4).
///
/// Vive en `domain/` porque la misma regla se usa desde el formulario (feedback
/// inmediato) y antes de llamar a Supabase.
class Credenciales {
  const Credenciales({required this.correo, required this.contrasena});

  static const int longitudMinimaContrasena = 8;

  static final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final String correo;
  final String contrasena;

  String get correoNormalizado => correo.trim().toLowerCase();

  /// `null` si el correo es valido; el error de validacion si no lo es.
  static ErrorValidacion? validarCorreo(String correo) {
    final valor = correo.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion('Introduce tu correo.', campo: 'correo');
    }
    if (!_formatoCorreo.hasMatch(valor)) {
      return const ErrorValidacion(
        'El correo no tiene un formato valido.',
        campo: 'correo',
      );
    }
    return null;
  }

  /// Validacion del campo de contrasena en el formulario de acceso: solo
  /// comprueba que no este vacio, porque la politica de longitud la aplica
  /// Supabase al fijarla, no al usarla.
  static ErrorValidacion? validarContrasenaDeAcceso(String contrasena) {
    if (contrasena.isEmpty) {
      return const ErrorValidacion(
        'Introduce tu contrasena.',
        campo: 'contrasena',
      );
    }
    return null;
  }

  /// Validacion de una contrasena nueva (CU-24, al restablecerla).
  static ErrorValidacion? validarContrasenaNueva(String contrasena) {
    if (contrasena.isEmpty) {
      return const ErrorValidacion(
        'Introduce una contrasena.',
        campo: 'contrasena',
      );
    }
    if (contrasena.length < longitudMinimaContrasena) {
      return const ErrorValidacion(
        'La contrasena debe tener al menos '
        '$longitudMinimaContrasena caracteres.',
        campo: 'contrasena',
      );
    }
    return null;
  }

  /// Primer error de validacion del par correo/contrasena, o `null` si son validos.
  ErrorValidacion? validar() =>
      validarCorreo(correo) ?? validarContrasenaDeAcceso(contrasena);
}
