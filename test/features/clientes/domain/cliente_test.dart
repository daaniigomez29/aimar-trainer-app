import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';

DatosCliente _datos({
  String nombre = 'Ana Garcia',
  String correo = 'ana@ejemplo.com',
  DiaSemana dia = DiaSemana.domingo,
  DateTime? fechaNacimiento,
  double? alturaCm,
  double? pesoInicialKg,
  String? objetivos,
}) => DatosCliente(
  nombre: nombre,
  correo: correo,
  diaControlPreferido: dia,
  fechaNacimiento: fechaNacimiento,
  alturaCm: alturaCm,
  pesoInicialKg: pesoInicialKg,
  objetivos: objetivos,
);

final _hoy = DateTime(2026, 10, 1);

void main() {
  group('DatosCliente: nombre y correo (CU-17, paso 3)', () {
    test('el nombre es obligatorio', () {
      expect(DatosCliente.validarNombre('  ')?.campo, 'nombre');
    });

    test('el correo es obligatorio y con formato', () {
      expect(DatosCliente.validarCorreo('')?.campo, 'correo');
      expect(DatosCliente.validarCorreo('sin-arroba')?.campo, 'correo');
      expect(DatosCliente.validarCorreo('a@b.com'), isNull);
    });

    test('el correo se normaliza a minusculas', () {
      expect(
        _datos(correo: '  Ana@Ejemplo.COM ').correoNormalizado,
        'ana@ejemplo.com',
      );
    });
  });

  group('DatosCliente.validarFechaNacimiento', () {
    test('es opcional', () {
      expect(DatosCliente.validarFechaNacimiento(null, hoy: _hoy), isNull);
    });

    test('rechaza una fecha futura', () {
      expect(
        DatosCliente.validarFechaNacimiento(DateTime(2027), hoy: _hoy)?.campo,
        'fechaNacimiento',
      );
    });

    test('rechaza una edad por debajo del minimo', () {
      final casiMinimo = DateTime(
        _hoy.year - DatosCliente.edadMinima,
        _hoy.month,
        _hoy.day + 1,
      );

      expect(
        DatosCliente.validarFechaNacimiento(casiMinimo, hoy: _hoy)?.campo,
        'fechaNacimiento',
      );
    });

    test('acepta justo la edad minima', () {
      final minimo = DateTime(
        _hoy.year - DatosCliente.edadMinima,
        _hoy.month,
        _hoy.day,
      );

      expect(DatosCliente.validarFechaNacimiento(minimo, hoy: _hoy), isNull);
    });

    test('rechaza una edad absurda', () {
      expect(
        DatosCliente.validarFechaNacimiento(DateTime(1800), hoy: _hoy)?.campo,
        'fechaNacimiento',
      );
    });
  });

  group('DatosCliente.validarMedida: limites de numeric(5,2)', () {
    test('es opcional', () {
      expect(
        DatosCliente.validarMedida(null, campo: 'alturaCm', etiqueta: 'A'),
        isNull,
      );
    });

    test('rechaza cero y negativos', () {
      expect(
        DatosCliente.validarMedida(0, campo: 'alturaCm', etiqueta: 'A')?.campo,
        'alturaCm',
      );
      expect(
        DatosCliente.validarMedida(-5, campo: 'alturaCm', etiqueta: 'A')?.campo,
        'alturaCm',
      );
    });

    test('corta por encima del maximo, antes de que desborde en Postgres', () {
      // Sin esta validacion, la Edge Function devolveria un 500 con
      // "numeric field overflow" en lugar de un mensaje util.
      expect(
        DatosCliente.validarMedida(
          DatosCliente.valorMaximoNumerico + 0.01,
          campo: 'alturaCm',
          etiqueta: 'La altura',
        )?.campo,
        'alturaCm',
      );
      expect(
        DatosCliente.validarMedida(
          DatosCliente.valorMaximoNumerico,
          campo: 'alturaCm',
          etiqueta: 'La altura',
        ),
        isNull,
      );
    });
  });

  group('DatosCliente.validar: orden de los errores', () {
    test('primero el nombre', () {
      expect(
        _datos(nombre: '', correo: 'mal').validar(hoy: _hoy)?.campo,
        'nombre',
      );
    });

    test('datos completos y validos', () {
      expect(
        _datos(
          fechaNacimiento: DateTime(1992, 5, 10),
          alturaCm: 165,
          pesoInicialKg: 60.5,
        ).validar(hoy: _hoy),
        isNull,
      );
    });
  });

  group('DatosCliente: payloads', () {
    test(
      'el alta usa las claves camelCase del contrato de la Edge Function',
      () {
        final json = _datos(
          fechaNacimiento: DateTime(1992, 5, 10),
          alturaCm: 165,
          dia: DiaSemana.miercoles,
        ).aJsonDeAlta();

        expect(json['diaControlPreferido'], 'miercoles');
        expect(json['fechaNacimiento'], '1992-05-10');
        expect(json['alturaCm'], 165);
        expect(json['pesoInicialKg'], isNull);
        expect(json.containsKey('estado'), isFalse);
      },
    );

    test('la edicion usa snake_case y NO incluye el correo', () {
      final json = _datos().aJsonDeEdicion();

      expect(json.containsKey('dia_control_preferido'), isTrue);
      expect(
        json.containsKey('correo'),
        isFalse,
        reason: 'cambiar el correo desalinearia la ficha de la cuenta de Auth',
      );
    });

    test('los objetivos vacios se guardan como null, no como cadena vacia', () {
      expect(_datos(objetivos: '   ').aJsonDeEdicion()['objetivos'], isNull);
      expect(_datos(objetivos: ' Fuerza ').objetivosNormalizados, 'Fuerza');
    });
  });

  group('Cliente.edadEn', () {
    Cliente cliente(DateTime? nacimiento) => Cliente(
      id: 'id',
      nombre: 'Ana',
      correo: 'a@b.com',
      diaControlPreferido: DiaSemana.domingo,
      estado: EstadoCliente.activo,
      fechaAlta: DateTime.utc(2026),
      fechaNacimiento: nacimiento,
    );

    test('null si no se conoce la fecha', () {
      expect(cliente(null).edadEn(_hoy), isNull);
    });

    test('descuenta el cumpleanos no alcanzado', () {
      expect(cliente(DateTime(1992, 10, 1)).edadEn(_hoy), 34);
      expect(cliente(DateTime(1992, 10, 2)).edadEn(_hoy), 33);
    });
  });

  group('enums alineados con Postgres', () {
    test('dia_semana sin tildes, como las etiquetas del enum SQL', () {
      expect(DiaSemana.values.map((d) => d.name), [
        'lunes',
        'martes',
        'miercoles',
        'jueves',
        'viernes',
        'sabado',
        'domingo',
      ]);
    });

    test('estado_cliente', () {
      expect(EstadoCliente.values.map((e) => e.name), ['activo', 'baja']);
    });
  });
}
