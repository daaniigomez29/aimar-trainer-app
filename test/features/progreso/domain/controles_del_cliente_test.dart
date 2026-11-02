import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/progreso/domain/controles_del_cliente.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

/// POR QUE ESTE TEST: medidas y check-in son dos guardados independientes, sin
/// relacion en la base. Si se listara solo uno de los dos, un dia con el otro
/// quedaria sin forma de consultarse.
void main() {
  RegistroMedidas medidas(DateTime fecha) => RegistroMedidas(
    id: 'm-${fecha.day}',
    clienteId: 'c-1',
    fecha: fecha,
    pesoKg: 80,
  );

  CheckinRecuperacion checkin(DateTime fecha) => CheckinRecuperacion(
    id: 'c-${fecha.day}',
    clienteId: 'c-1',
    fecha: fecha,
    horasSueno: 7,
    estres: 3,
    agujetas: 4,
    fatiga: 2,
  );

  group('unirControles', () {
    test('el mismo día se junta en un solo control', () {
      final dia = DateTime(2026, 10, 18);

      final controles = unirControles(
        medidas: [medidas(dia)],
        checkins: [checkin(dia)],
      );

      expect(controles, hasLength(1));
      expect(controles.single.medidas, isNotNull);
      expect(controles.single.checkin, isNotNull);
    });

    test('un día con solo una de las dos partes también cuenta', () {
      final controles = unirControles(
        medidas: [medidas(DateTime(2026, 10, 18))],
        checkins: [checkin(DateTime(2026, 10, 11))],
      );

      expect(controles, hasLength(2));
      expect(controles.first.checkin, isNull);
      expect(controles.last.medidas, isNull);
    });

    test('quedan de lo más reciente a lo más antiguo', () {
      final controles = unirControles(
        medidas: [medidas(DateTime(2026, 9, 6))],
        checkins: [
          checkin(DateTime(2026, 10, 18)),
          checkin(DateTime(2026, 10, 25)),
        ],
      );

      expect(controles.map((c) => c.fecha), [
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 18),
        DateTime(2026, 9, 6),
      ]);
    });

    test('sin nada, ninguno', () {
      expect(unirControles(medidas: const [], checkins: const []), isEmpty);
    });
  });

  test('controlesDelMes distingue el mismo mes de otro año', () {
    final controles = unirControles(
      medidas: [
        medidas(DateTime(2026, 10, 18)),
        medidas(DateTime(2025, 10, 5)),
      ],
      checkins: const [],
    );

    final delMes = controlesDelMes(controles, DateTime(2026, 10));

    expect(delMes.map((c) => c.fecha), [DateTime(2026, 10, 18)]);
  });

  group('moverse entre meses', () {
    test('mesDe se queda con el día 1', () {
      expect(mesDe(DateTime(2026, 10, 25)), DateTime(2026, 10));
    });

    test('cruza el cambio de año en los dos sentidos', () {
      expect(mesSumando(DateTime(2026, 12), 1), DateTime(2027));
      expect(mesSumando(DateTime(2026), -1), DateTime(2025, 12));
    });

    test('la etiqueta se lee en castellano', () {
      expect(etiquetaDeMes(DateTime(2026, 11)), 'Noviembre de 2026');
    });
  });
}
