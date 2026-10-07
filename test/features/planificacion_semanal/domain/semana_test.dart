import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';

void main() {
  group('Semana.de', () {
    test('cualquier día de la semana da el mismo lunes', () {
      // El miércoles 14 de octubre de 2026 cae en la semana del 12 al 18: es el
      // caso que motiva el calendario, donde se elige un día cualquiera.
      final miercoles = Semana.de(DateTime(2026, 10, 14));

      expect(miercoles.lunes, DateTime(2026, 10, 12));
      expect(miercoles.domingo, DateTime(2026, 10, 18));
      for (var dia = 12; dia <= 18; dia++) {
        expect(Semana.de(DateTime(2026, 10, dia)), miercoles);
      }
    });

    test('el domingo pertenece a la semana que acaba, no a la siguiente', () {
      expect(Semana.de(DateTime(2026, 10, 18)).lunes, DateTime(2026, 10, 12));
      expect(Semana.de(DateTime(2026, 10, 19)).lunes, DateTime(2026, 10, 19));
    });

    test('descarta la hora', () {
      expect(
        Semana.de(DateTime(2026, 10, 14, 23, 59)).lunes,
        DateTime(2026, 10, 12),
      );
    });
  });

  test('anterior y siguiente se mueven de siete en siete', () {
    final semana = Semana.de(DateTime(2026, 10, 14));

    expect(semana.anterior.lunes, DateTime(2026, 10, 5));
    expect(semana.siguiente.lunes, DateTime(2026, 10, 19));
  });

  // El fallo: la flecha de "semana siguiente" se quedaba clavada en el 19-25 de
  // octubre de 2026. Esa es la semana del cambio de hora en España (el domingo
  // 25 se atrasa el reloj), asi que dura 169 horas: sumar `Duration(days: 7)`
  // —168 horas— caia en el domingo 25 a las 23:00, que es la MISMA semana.
  test('avanzar y retroceder son siempre siete días de calendario', () {
    // Dos años seguidos: cualquier cambio de hora de la zona del que ejecuta
    // los tests cae dentro, sea cual sea esa zona.
    var dia = DateTime(2026);
    while (dia.year < 2028) {
      final semana = Semana.de(dia);
      final lunes = semana.lunes;

      expect(
        semana.siguiente.lunes,
        DateTime(lunes.year, lunes.month, lunes.day + 7),
        reason: 'la semana siguiente a $lunes',
      );
      expect(
        semana.anterior.lunes,
        DateTime(lunes.year, lunes.month, lunes.day - 7),
        reason: 'la semana anterior a $lunes',
      );
      expect(semana.siguiente, isNot(semana));
      expect(semana.domingo, DateTime(lunes.year, lunes.month, lunes.day + 6));
      // Todo lunes esta a medianoche: si no, dos semanas iguales no se
      // reconocerian como la misma.
      expect(lunes.hour, 0, reason: 'el lunes de $dia no esta a medianoche');

      dia = DateTime(dia.year, dia.month, dia.day + 1);
    }
  });

  test('contiene solo los siete días', () {
    final semana = Semana.de(DateTime(2026, 10, 12));

    expect(semana.contiene(DateTime(2026, 10, 12)), isTrue);
    expect(semana.contiene(DateTime(2026, 10, 18, 23)), isTrue);
    expect(semana.contiene(DateTime(2026, 10, 11)), isFalse);
    expect(semana.contiene(DateTime(2026, 10, 19)), isFalse);
  });

  group('etiqueta', () {
    test('dentro de un mes, el mes va una vez', () {
      expect(Semana.de(DateTime(2026, 10, 14)).etiqueta, '12-18 oct');
    });

    test('a caballo entre dos meses, cada día lleva el suyo', () {
      expect(Semana.de(DateTime(2026, 9, 30)).etiqueta, '28 sep - 4 oct');
    });
  });
}
