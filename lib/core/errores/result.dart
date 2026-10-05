import 'package:aimar_trainer_app/core/errores/error_app.dart';

/// Resultado de una operacion que puede fallar, en lugar de lanzar excepciones.
///
/// Convencion fijada en `AGENTS.md`: los repositorios devuelven `Result<T>` y
/// nunca propagan excepciones de Supabase.
sealed class Result<T> {
  const Result();

  const factory Result.success(T valor) = Success<T>;
  const factory Result.failure(ErrorApp error) = Failure<T>;

  bool get esExito => this is Success<T>;
  bool get esFallo => this is Failure<T>;

  /// Valor si fue exito, `null` si fue fallo.
  T? get valorONulo => switch (this) {
    Success<T>(:final valor) => valor,
    Failure<T>() => null,
  };

  /// Error si fue fallo, `null` si fue exito.
  ErrorApp? get errorONulo => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };

  /// Transforma el valor de exito manteniendo el error intacto.
  Result<R> map<R>(R Function(T valor) transformar) => switch (this) {
    Success<T>(:final valor) => Success<R>(transformar(valor)),
    Failure<T>(:final error) => Failure<R>(error),
  };

  /// Encadena otra operacion que tambien puede fallar.
  Result<R> flatMap<R>(Result<R> Function(T valor) siguiente) => switch (this) {
    Success<T>(:final valor) => siguiente(valor),
    Failure<T>(:final error) => Failure<R>(error),
  };

  /// Colapsa ambas ramas en un unico valor.
  R fold<R>({
    required R Function(T valor) enExito,
    required R Function(ErrorApp error) enFallo,
  }) => switch (this) {
    Success<T>(:final valor) => enExito(valor),
    Failure<T>(:final error) => enFallo(error),
  };
}

class Success<T> extends Result<T> {
  const Success(this.valor);

  final T valor;

  @override
  bool operator ==(Object other) => other is Success<T> && other.valor == valor;

  @override
  int get hashCode => Object.hash(Success<T>, valor);

  @override
  String toString() => 'Success<$T>($valor)';
}

class Failure<T> extends Result<T> {
  const Failure(this.error);

  final ErrorApp error;

  @override
  bool operator ==(Object other) => other is Failure<T> && other.error == error;

  @override
  int get hashCode => Object.hash(Failure<T>, error);

  @override
  String toString() => 'Failure<$T>($error)';
}
