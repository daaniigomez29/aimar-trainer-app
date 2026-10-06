import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';

void main() {
  group('DatosSerieRealizada', () {
    test('acepta una serie sin peso ni RIR', () {
      const serie = DatosSerieRealizada(numeroSerie: 1, repeticiones: 12);

      expect(serie.validar(), isNull);
    });

    test('rechaza repeticiones no positivas', () {
      const serie = DatosSerieRealizada(numeroSerie: 1, repeticiones: 0);

      expect(serie.validar()?.campo, 'repeticiones');
    });

    test('rechaza un peso de cero, pero no que falte', () {
      const conCero = DatosSerieRealizada(
        numeroSerie: 1,
        repeticiones: 8,
        peso: 0,
      );

      expect(conCero.validar()?.campo, 'peso');
    });

    test('el RIR va de 0 a 10, igual que el planificado', () {
      const bajo = DatosSerieRealizada(
        numeroSerie: 1,
        repeticiones: 8,
        rir: -1,
      );
      const alto = DatosSerieRealizada(
        numeroSerie: 1,
        repeticiones: 8,
        rir: 11,
      );
      const limite = DatosSerieRealizada(
        numeroSerie: 1,
        repeticiones: 8,
        rir: 0,
      );

      expect(bajo.validar()?.campo, 'rir');
      expect(alto.validar()?.campo, 'rir');
      expect(limite.validar(), isNull);
    });
  });

  group('DatosResultadoEjercicio', () {
    test('Fuerza exige al menos una serie', () {
      const datos = DatosResultadoEjercicio.fuerza(
        ejercicioPlanificadoId: 'ep-1',
        series: [],
      );

      expect(datos.validar()?.campo, 'series');
    });

    test('Fuerza rechaza dos series con el mismo número', () {
      const datos = DatosResultadoEjercicio.fuerza(
        ejercicioPlanificadoId: 'ep-1',
        series: [
          DatosSerieRealizada(numeroSerie: 1, repeticiones: 10),
          DatosSerieRealizada(numeroSerie: 1, repeticiones: 8),
        ],
      );

      expect(datos.validar()?.campo, 'series');
    });

    test('Cardio no lleva series y Fuerza no lleva minutos', () {
      const cardio = DatosResultadoEjercicio.cardio(
        ejercicioPlanificadoId: 'ep-1',
        minutos: 30,
      );
      const fuerza = DatosResultadoEjercicio.fuerza(
        ejercicioPlanificadoId: 'ep-1',
        series: [DatosSerieRealizada(numeroSerie: 1, repeticiones: 10)],
      );

      expect(cardio.esCardio, isTrue);
      expect(cardio.series, isEmpty);
      expect(fuerza.esCardio, isFalse);
      expect(fuerza.minutos, isNull);
    });

    test('Cardio rechaza minutos no positivos', () {
      const datos = DatosResultadoEjercicio.cardio(
        ejercicioPlanificadoId: 'ep-1',
        minutos: 0,
      );

      expect(datos.validar()?.campo, 'minutos');
    });
  });

  group('DatosRegistroMedidas', () {
    DatosRegistroMedidas medidas({double? peso = 80, double? cintura}) =>
        DatosRegistroMedidas(
          clienteId: 'cli-1',
          fecha: DateTime(2026, 10, 4),
          pesoKg: peso,
          cinturaCm: cintura,
        );

    test('el peso es obligatorio y los perimetros no', () {
      expect(medidas().validar(), isNull);
      expect(medidas(peso: null).validar()?.campo, 'pesoKg');
    });

    test('un perimetro, si se pone, debe ser positivo', () {
      expect(medidas(cintura: 0).validar()?.campo, 'cinturaCm');
      expect(medidas(cintura: 74.5).validar(), isNull);
    });

    test('la fecha viaja como date, sin hora', () {
      final json = medidas().aJson();

      expect(json['fecha'], '2026-10-04');
    });
  });

  group('DatosCheckin', () {
    DatosCheckin checkin({
      double? horas = 7.5,
      int estres = 5,
      String? notas,
    }) => DatosCheckin(
      clienteId: 'cli-1',
      fecha: DateTime(2026, 10, 4),
      horasSueno: horas,
      estres: estres,
      agujetas: 4,
      fatiga: 3,
      notas: notas,
    );

    test('las escalas van de 1 a 10, no de 0', () {
      expect(checkin(estres: 0).validar()?.campo, 'estres');
      expect(checkin(estres: 11).validar()?.campo, 'estres');
      expect(checkin(estres: 1).validar(), isNull);
      expect(checkin(estres: 10).validar(), isNull);
    });

    test('las horas de sueno no tienen tope superior', () {
      expect(checkin(horas: 14).validar(), isNull);
      expect(checkin(horas: -1).validar()?.campo, 'horasSueno');
      expect(checkin(horas: null).validar()?.campo, 'horasSueno');
    });

    test('unas notas en blanco se guardan como null', () {
      expect(checkin(notas: '   ').aJson()['notas'], isNull);
      expect(checkin(notas: ' Viaje ').aJson()['notas'], 'Viaje');
    });

    test('el error de validación es un ErrorValidacion con campo', () {
      final error = checkin(estres: 0).validar();

      expect(error, isA<ErrorValidacion>());
      expect(error!.mensaje, contains('1 a 10'));
    });
  });
}
