import 'package:aimar_trainer_app/core/errores/error_app.dart';

/// Estado de un formulario que dispara una unica accion contra el repositorio:
/// inactivo, en curso, completado o con error.
///
/// Se comparte entre login, solicitud de recuperacion y restablecimiento porque
/// los tres tienen exactamente esta forma.
class EstadoAccion {
  const EstadoAccion({
    this.enCurso = false,
    this.completada = false,
    this.error,
  });

  const EstadoAccion.inicial() : this();

  const EstadoAccion.enCurso() : this(enCurso: true);

  const EstadoAccion.completada() : this(completada: true);

  const EstadoAccion.conError(ErrorApp error) : this(error: error);

  final bool enCurso;
  final bool completada;
  final ErrorApp? error;

  /// Mensaje de error asociado al campo indicado, si el error es de validacion
  /// y apunta a ese campo. Sirve para pintarlo bajo su `TextFormField`.
  String? errorDelCampo(String campo) {
    final actual = error;
    if (actual is ErrorValidacion && actual.campo == campo) {
      return actual.mensaje;
    }
    return null;
  }

  /// Error que no pertenece a ningun campo concreto y va en el aviso general.
  String? get errorGeneral {
    final actual = error;
    if (actual == null) return null;
    if (actual is ErrorValidacion && actual.campo != null) return null;
    return actual.mensaje;
  }

  @override
  bool operator ==(Object other) =>
      other is EstadoAccion &&
      other.enCurso == enCurso &&
      other.completada == completada &&
      other.error == error;

  @override
  int get hashCode => Object.hash(enCurso, completada, error);

  @override
  String toString() =>
      'EstadoAccion(enCurso: $enCurso, completada: $completada, error: $error)';
}
