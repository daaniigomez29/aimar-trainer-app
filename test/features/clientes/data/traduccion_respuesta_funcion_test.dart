import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';

/// Cliente de Supabase falso que simula lo que responde la capa HTTP.
///
/// No se usa `mocktail` sobre `SupabaseClient` porque habria que simular toda la
/// cadena `functions.invoke`; aqui interesa solo la traduccion de la respuesta.
void main() {
  late List<String> registrado;
  late DebugPrintCallback anterior;

  setUp(() {
    registrado = [];
    anterior = debugPrint;
    debugPrint = (mensaje, {wrapWidth}) => registrado.add(mensaje ?? '');
    Registro.activo = true;
  });

  tearDown(() {
    debugPrint = anterior;
    Registro.activo = kDebugMode;
  });

  group('Edge Function caida: el caso de "supabase functions serve" parado', () {
    test('un 503 de Kong da un mensaje accionable, no "error inesperado"', () {
      // Kong responde esto cuando el contenedor del runtime no esta levantado.
      // Antes caia en el `_` del switch y acababa en ErrorInesperado, porque el
      // cuerpo trae `message` (ingles) y el codigo solo leia `mensaje`.
      final error = ClienteRepositorioSupabase.traducirRespuestaFuncionParaTest(
        503,
        const {'message': 'name resolution failed'},
        servicio: 'alta de clientes',
      );

      expect(error, isA<ErrorServicioNoDisponible>());
      expect(error.mensaje, contains('alta de clientes'));
      expect(error.mensaje, isNot(contains('inesperado')));
    });

    test('y deja en el registro el estado, el cuerpo y como arrancarlas', () {
      ClienteRepositorioSupabase.traducirRespuestaFuncionParaTest(503, const {
        'message': 'name resolution failed',
      }, servicio: 'alta de clientes');
      final salida = registrado.join('\n');

      expect(salida, contains('503'));
      expect(salida, contains('name resolution failed'));
      expect(salida, contains('supabase functions serve'));
    });
  });

  group('codigos del contrato de architecture.md', () {
    ErrorApp traducir(int estado, Map<String, dynamic>? cuerpo) =>
        ClienteRepositorioSupabase.traducirRespuestaFuncionParaTest(
          estado,
          cuerpo,
          servicio: 'alta de clientes',
        );

    test('401 y 403 son falta de permisos', () {
      expect(traducir(401, null), isA<ErrorNoAutorizado>());
      expect(traducir(403, null), isA<ErrorNoAutorizado>());
    });

    test('409 de correo duplicado', () {
      expect(
        traducir(409, const {
          'error': 'correo_duplicado',
          'mensaje': 'Ya hay un cliente activo con ese correo.',
        }),
        isA<ErrorNombreDuplicado>(),
      );
    });

    test('409 de ya dado de baja no es un duplicado', () {
      expect(
        traducir(409, const {
          'error': 'ya_de_baja',
          'mensaje': 'Ese cliente ya estaba dado de baja.',
        }),
        isA<ErrorValidacion>(),
      );
    });

    test('400 conserva el mensaje de la funcion', () {
      final error = traducir(400, const {
        'error': 'datos_invalidos',
        'mensaje': 'El correo no tiene un formato valido.',
      });

      expect(error.mensaje, 'El correo no tiene un formato valido.');
    });

    test('404 cliente no encontrado', () {
      expect(traducir(404, null), isA<ErrorNoEncontrado>());
    });

    test('un 500 de la propia funcion conserva su mensaje en la causa', () {
      final error = traducir(500, const {
        'error': 'error_interno',
        'mensaje': 'No se pudo crear la ficha: numeric field overflow',
      });

      // 500 no es "servicio caido": la funcion respondio, pero algo fallo dentro.
      expect(error, isA<ErrorInesperado>());
      expect(
        (error as ErrorInesperado).causa.toString(),
        contains('numeric field overflow'),
      );
    });
  });

  test('el payload de alta usa las claves del contrato', () {
    // Comprobacion de contrato: si estas claves cambian, la Edge Function deja de
    // entender la peticion y devuelve 400.
    const datos = DatosCliente(
      nombre: 'Ana',
      correo: 'ana@ejemplo.com',
      diaControlPreferido: DiaSemana.lunes,
    );

    expect(datos.aJsonDeAlta().keys.toSet(), {
      'nombre',
      'correo',
      'fechaNacimiento',
      'alturaCm',
      'pesoInicialKg',
      'objetivos',
      'diaControlPreferido',
    });
  });
}
