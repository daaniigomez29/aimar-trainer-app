import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';

/// Captura lo que el registro escribe, para poder comprobarlo.
List<String> _capturar(void Function() accion) {
  final lineas = <String>[];
  final anterior = debugPrint;
  final activoAntes = Registro.activo;
  debugPrint = (mensaje, {wrapWidth}) => lineas.add(mensaje ?? '');
  Registro.activo = true;
  try {
    accion();
  } finally {
    debugPrint = anterior;
    Registro.activo = activoAntes;
  }
  return lineas;
}

void main() {
  group('Registro: saca a la luz la causa que el Result esconde', () {
    test('un PostgrestException deja su code, details y hint', () {
      // Es justo lo que explica un fallo de PostgREST y lo que la interfaz nunca
      // muestra, porque solo ve "ha ocurrido un error inesperado".
      final lineas = _capturar(
        () => Registro.fallo(
          const PostgrestException(
            message: 'permission denied for table clientes',
            code: '42501',
            details: 'detalle del motor',
            hint: 'concede el GRANT',
          ),
          StackTrace.current,
          contexto: 'el repositorio de clientes',
        ),
      );
      final salida = lineas.join('\n');

      expect(salida, contains('el repositorio de clientes'));
      expect(salida, contains('permission denied for table clientes'));
      expect(salida, contains('42501'));
      expect(salida, contains('detalle del motor'));
      expect(salida, contains('concede el GRANT'));
      expect(salida, contains('pila:'));
    });

    test('un AuthException deja su code y statusCode', () {
      final salida = _capturar(
        () => Registro.fallo(
          AuthException(
            'User is banned',
            statusCode: '400',
            code: 'user_banned',
          ),
          null,
          contexto: 'el repositorio de autenticacion',
        ),
      ).join('\n');

      expect(salida, contains('user_banned'));
      expect(salida, contains('400'));
    });

    test('inesperado registra y devuelve el ErrorApp a la vez', () {
      late ErrorApp devuelto;
      final salida = _capturar(() {
        devuelto = Registro.inesperado(
          StateError('algo raro'),
          StackTrace.current,
          contexto: 'el repositorio de ejercicios',
        );
      }).join('\n');

      expect(devuelto, isA<ErrorInesperado>());
      expect((devuelto as ErrorInesperado).causa, isA<StateError>());
      expect(salida, contains('algo raro'));
    });

    test('un error sin propiedades conocidas no rompe el registro', () {
      final salida = _capturar(
        () => Registro.fallo(
          'un error que es solo texto',
          null,
          contexto: 'cualquier sitio',
        ),
      ).join('\n');

      expect(salida, contains('un error que es solo texto'));
    });

    test(
      'callado cuando no esta activo, para no ensuciar un build de release',
      () {
        final lineas = <String>[];
        final anterior = debugPrint;
        final activoAntes = Registro.activo;
        debugPrint = (mensaje, {wrapWidth}) => lineas.add(mensaje ?? '');
        Registro.activo = false;
        try {
          Registro.fallo(StateError('x'), null, contexto: 'y');
          Registro.info('z');
        } finally {
          debugPrint = anterior;
          Registro.activo = activoAntes;
        }

        expect(lineas, isEmpty);
      },
    );
  });
}
