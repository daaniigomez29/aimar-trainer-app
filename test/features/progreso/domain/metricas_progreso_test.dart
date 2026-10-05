import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';

RegistroProgreso serie({
  required DateTime fecha,
  int numeroSerie = 1,
  int? repeticiones = 10,
  double? peso = 60,
  int? rir,
}) => RegistroProgreso(
  clienteId: 'cli-1',
  ejercicioId: 'ej-1',
  ejercicioNombre: 'Press banca',
  ejercicioTipo: TipoEjercicio.fuerza,
  sesionId: 's-1',
  fecha: fecha,
  numeroSerie: numeroSerie,
  repeticionesRealizadas: repeticiones,
  pesoReal: peso,
  rirReal: rir,
);

void main() {
  final dia = DateTime(2026, 10, 1);

  group('MetricaEjercicio', () {
    test('el peso maximo se queda con la serie mas pesada del dia', () {
      final valor = MetricaEjercicio.pesoMaximo.resumir([
        serie(fecha: dia, peso: 60),
        serie(fecha: dia, numeroSerie: 2, peso: 72.5),
        serie(fecha: dia, numeroSerie: 3, peso: 70),
      ]);

      expect(valor, 72.5);
    });

    test('el volumen suma peso por repeticiones de cada serie', () {
      final valor = MetricaEjercicio.volumenTotal.resumir([
        serie(fecha: dia, peso: 60, repeticiones: 10),
        serie(fecha: dia, numeroSerie: 2, peso: 50, repeticiones: 8),
      ]);

      expect(valor, 60 * 10 + 50 * 8);
    });

    test('una serie sin peso no cuenta para el volumen', () {
      final valor = MetricaEjercicio.volumenTotal.resumir([
        serie(fecha: dia, peso: null, repeticiones: 12),
      ]);

      expect(valor, isNull);
    });

    test('las repeticiones se suman aunque no haya peso', () {
      final valor = MetricaEjercicio.repeticionesTotales.resumir([
        serie(fecha: dia, peso: null, repeticiones: 12),
        serie(fecha: dia, numeroSerie: 2, peso: null, repeticiones: 10),
      ]);

      expect(valor, 22);
    });

    test('el RIR medio ignora las series que no lo anotaron', () {
      final valor = MetricaEjercicio.rirMedio.resumir([
        serie(fecha: dia, rir: 2),
        serie(fecha: dia, numeroSerie: 2, rir: 4),
        serie(fecha: dia, numeroSerie: 3),
      ]);

      expect(valor, 3);
    });

    test('Fuerza y Cardio no comparten metricas', () {
      expect(MetricaEjercicio.deTipo(TipoEjercicio.cardio), [
        MetricaEjercicio.minutos,
      ]);
      expect(
        MetricaEjercicio.deTipo(TipoEjercicio.fuerza),
        isNot(contains(MetricaEjercicio.minutos)),
      );
    });
  });

  group('serieDeProgreso', () {
    test('agrupa por dia y devuelve los puntos en orden cronologico', () {
      final puntos = serieDeProgreso(
        registros: [
          serie(fecha: DateTime(2026, 10, 8), peso: 80),
          serie(fecha: DateTime(2026, 10, 1), peso: 70),
          serie(fecha: DateTime(2026, 10, 1, 19), numeroSerie: 2, peso: 75),
        ],
        metrica: MetricaEjercicio.pesoMaximo,
      );

      expect(puntos.map((p) => p.valor).toList(), [75, 80]);
      expect(puntos.first.fecha, DateTime(2026, 10));
    });

    test('un dia sin dato para esa metrica no genera punto', () {
      final puntos = serieDeProgreso(
        registros: [serie(fecha: dia, peso: null)],
        metrica: MetricaEjercicio.pesoMaximo,
      );

      expect(puntos, isEmpty);
    });
  });

  group('serieCorporal', () {
    RegistroMedidas medidas(DateTime fecha, {double? cintura}) =>
        RegistroMedidas(
          id: 'm-${fecha.day}',
          clienteId: 'cli-1',
          fecha: fecha,
          pesoKg: 80,
          cinturaCm: cintura,
        );

    test('solo entran los registros que tienen esa medida', () {
      final puntos = serieCorporal(
        registros: [
          medidas(DateTime(2026, 10, 8), cintura: 79),
          medidas(DateTime(2026, 10)),
        ],
        metrica: MetricaCorporal.cinturaCm,
      );

      expect(puntos.length, 1);
      expect(puntos.single.valor, 79);
    });

    test('el peso corporal siempre esta, porque es obligatorio', () {
      final puntos = serieCorporal(
        registros: [
          medidas(DateTime(2026, 10)),
          medidas(DateTime(2026, 10, 8)),
        ],
        metrica: MetricaCorporal.pesoKg,
      );

      expect(puntos.length, 2);
    });
  });

  group('RangoFechas', () {
    test('el de los ultimos meses acaba hoy', () {
      final rango = RangoFechas.ultimosMeses(3, hoy: DateTime(2026, 10, 3, 18));

      expect(rango.hasta, DateTime(2026, 10, 3));
      expect(rango.desde, DateTime(2026, 7, 3));
      expect(rango.esValido, isTrue);
    });

    test('contiene incluye los dos extremos', () {
      final rango = RangoFechas(
        desde: DateTime(2026, 10),
        hasta: DateTime(2026, 10, 31),
      );

      expect(rango.contiene(DateTime(2026, 10)), isTrue);
      expect(rango.contiene(DateTime(2026, 10, 31, 23)), isTrue);
      expect(rango.contiene(DateTime(2026, 9, 30)), isFalse);
    });
  });
}
