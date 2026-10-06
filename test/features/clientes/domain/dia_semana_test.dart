import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';

void main() {
  group('DiaSemana.ultimaFecha', () {
    // 2026-10-03 cae en sabado.
    final sabado = DateTime(2026, 10, 3);

    test('si hoy es el día de control, devuelve hoy', () {
      expect(DiaSemana.sabado.ultimaFecha(hoy: sabado), sabado);
    });

    test('devuelve el día de esta semana que ya ha pasado', () {
      expect(DiaSemana.jueves.ultimaFecha(hoy: sabado), DateTime(2026, 10));
    });

    test('si el día aun no ha llegado, se va al de la semana pasada', () {
      expect(DiaSemana.domingo.ultimaFecha(hoy: sabado), DateTime(2026, 9, 27));
    });

    test('descarta la hora: lo que se registra es un día', () {
      expect(
        DiaSemana.sabado.ultimaFecha(hoy: DateTime(2026, 10, 3, 23, 45)),
        sabado,
      );
    });

    test('se corresponde con la numeracion de DateTime', () {
      expect(DiaSemana.lunes.numeroDeDateTime, DateTime.monday);
      expect(DiaSemana.domingo.numeroDeDateTime, DateTime.sunday);
    });
  });
}
