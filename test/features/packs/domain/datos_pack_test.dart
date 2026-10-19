import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';

/// POR QUE ESTE TEST: lo que distingue un pack de lo planificado es que **todo
/// lo preparado es opcional**. Si alguien reutiliza aquí la validación del
/// planning, un pack dejaría de poder ser solo la lista de ejercicios, que es
/// justo para lo que se pidió.
void main() {
  DatosPackEjercicio deFuerza({
    List<DatosSerie> series = const [],
    int? descanso,
    double? minutos,
  }) => DatosPackEjercicio(
    packId: 'p-1',
    ejercicioId: 'ej-1',
    tipo: TipoEjercicio.fuerza,
    orden: 1,
    descansoSeg: descanso,
    minutos: minutos,
    series: series,
  );

  group('DatosPack', () {
    test('el nombre es obligatorio', () {
      expect(
        const DatosPack(nombre: '   ', tipo: TipoEjercicio.fuerza).validar(),
        isA<ErrorValidacion>(),
      );
    });

    test('el nombre se guarda sin espacios de sobra', () {
      const datos = DatosPack(
        nombre: '  Torso A  ',
        tipo: TipoEjercicio.fuerza,
      );

      expect(datos.aJson()['nombre'], 'Torso A');
      expect(datos.aJson()['tipo'], 'fuerza');
    });

    test('un nombre larguísimo se rechaza', () {
      final largo = 'x' * (DatosPack.longitudMaximaNombre + 1);

      expect(
        DatosPack(nombre: largo, tipo: TipoEjercicio.fuerza).validar(),
        isA<ErrorValidacion>(),
      );
    });
  });

  group('DatosPackEjercicio: lo preparado es opcional', () {
    test('un ejercicio sin series ni nada es válido', () {
      expect(deFuerza().validar(), isNull);
    });

    test('con series válidas, también', () {
      expect(
        deFuerza(
          series: const [DatosSerie(numeroSerie: 1, repeticiones: 8, peso: 60)],
        ).validar(),
        isNull,
      );
    });

    test('pero una serie mal puesta se sigue rechazando', () {
      expect(
        deFuerza(series: const [DatosSerie(numeroSerie: 1, repeticiones: 0)])
            .validar(),
        isA<ErrorValidacion>(),
      );
      expect(
        deFuerza(
          series: const [DatosSerie(numeroSerie: 1, repeticiones: 8, rir: 11)],
        ).validar(),
        isA<ErrorValidacion>(),
      );
    });

    test('dos series con el mismo número, no', () {
      expect(
        deFuerza(
          series: const [
            DatosSerie(numeroSerie: 1, repeticiones: 8),
            DatosSerie(numeroSerie: 1, repeticiones: 10),
          ],
        ).validar(),
        isA<ErrorValidacion>(),
      );
    });
  });

  group('DatosPackEjercicio: series y minutos se excluyen', () {
    test('lo que va por series no manda minutos, aunque se los pongan', () {
      final datos = deFuerza(minutos: 30, descanso: 90);

      expect(datos.minutosNormalizados, isNull);
      expect(datos.descansoNormalizado, 90);
      expect(datos.aParametrosDeRpc()['p_minutos'], isNull);
    });

    test('lo que va por minutos no manda series ni descanso', () {
      const datos = DatosPackEjercicio(
        packId: 'p-1',
        ejercicioId: 'ej-1',
        tipo: TipoEjercicio.cardio,
        orden: 1,
        descansoSeg: 90,
        minutos: 30,
        series: [DatosSerie(numeroSerie: 1, repeticiones: 8)],
      );

      expect(datos.seriesNormalizadas, isEmpty);
      expect(datos.descansoNormalizado, isNull);
      expect(datos.aParametrosDeRpc()['p_minutos'], 30);
      expect(datos.aParametrosDeRpc()['p_series'], isEmpty);
    });

    test('un cardio sin minutos es válido: también son opcionales', () {
      const datos = DatosPackEjercicio(
        packId: 'p-1',
        ejercicioId: 'ej-1',
        tipo: TipoEjercicio.cardio,
        orden: 1,
      );

      expect(datos.validar(), isNull);
      expect(datos.aParametrosDeRpc()['p_minutos'], isNull);
    });

    test('fortalecimiento va por series, como la fuerza', () {
      const datos = DatosPackEjercicio(
        packId: 'p-1',
        ejercicioId: 'ej-1',
        tipo: TipoEjercicio.fortalecimiento,
        orden: 1,
        minutos: 30,
      );

      expect(datos.vaPorSeries, isTrue);
      expect(datos.minutosNormalizados, isNull);
    });
  });

  test('los parámetros de la RPC llevan los nombres que espera Postgres', () {
    final params = deFuerza(
      descanso: 90,
      series: const [
        DatosSerie(numeroSerie: 1, repeticiones: 8, peso: 60, rir: 2),
      ],
    ).aParametrosDeRpc(id: 'pe-1');

    expect(params['p_id'], 'pe-1');
    expect(params['p_pack_id'], 'p-1');
    expect(params['p_ejercicio_id'], 'ej-1');
    expect(params['p_orden'], 1);
    expect(params['p_descanso_seg'], 90);
    expect(params['p_series'], [
      {'numero_serie': 1, 'repeticiones': 8, 'peso': 60.0, 'rir': 2},
    ]);
  });
}
