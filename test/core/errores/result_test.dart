import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';

void main() {
  group('Result', () {
    const error = ErrorCredencialesInvalidas();

    test('Success expone el valor y ningún error', () {
      const resultado = Success(42);

      expect(resultado.esExito, isTrue);
      expect(resultado.esFallo, isFalse);
      expect(resultado.valorONulo, 42);
      expect(resultado.errorONulo, isNull);
    });

    test('Failure expone el error y ningún valor', () {
      const resultado = Failure<int>(error);

      expect(resultado.esFallo, isTrue);
      expect(resultado.valorONulo, isNull);
      expect(resultado.errorONulo, error);
    });

    test('map transforma el exito', () {
      expect(const Success(2).map((valor) => valor * 3), const Success(6));
    });

    test('map conserva el error sin invocar la transformacion', () {
      var invocada = false;

      final resultado = const Failure<int>(error).map((valor) {
        invocada = true;
        return valor;
      });

      expect(resultado, const Failure<int>(error));
      expect(invocada, isFalse);
    });

    test('flatMap encadena solo en exito', () {
      expect(
        const Success(2).flatMap((valor) => Success('$valor')),
        const Success('2'),
      );
      expect(
        const Failure<int>(error).flatMap((valor) => Success('$valor')),
        const Failure<String>(error),
      );
    });

    test('fold colapsa ambas ramas', () {
      expect(
        const Success(
          7,
        ).fold(enExito: (valor) => 'valor $valor', enFallo: (error) => 'error'),
        'valor 7',
      );
      expect(
        const Failure<int>(error).fold(
          enExito: (valor) => 'valor $valor',
          enFallo: (error) => error.mensaje,
        ),
        error.mensaje,
      );
    });
  });
}
