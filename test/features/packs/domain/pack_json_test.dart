import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';

/// POR QUE ESTE TEST: las relaciones incrustadas llegan con el **nombre de la
/// tabla**, no con el del campo (`pack_ejercicios`, `pack_series`,
/// `ejercicios`). Ese mismo descuido ya costó una vez en `PlanningSemanal`: la
/// lista llegaba siempre vacía y la semana se veía entera como días de
/// descanso.
void main() {
  Map<String, dynamic> filaDeLaBase() => {
    'id': 'p-1',
    'nombre': 'Torso A',
    'tipos': ['fuerza', 'cardio'],
    'creado_en': '2026-10-19T10:00:00.000Z',
    'pack_ejercicios': [
      {
        'id': 'pe-2',
        'pack_id': 'p-1',
        'ejercicio_id': 'ej-2',
        'orden': 2,
        'descanso_seg': null,
        'minutos': null,
        'ejercicios': {
          'id': 'ej-2',
          'nombre': 'Dominadas',
          'descripcion': 'Colgado de la barra.',
          'tipo': 'fuerza',
          'estado': 'activo',
          'creado_en': '2026-10-01T00:00:00.000Z',
        },
        'pack_series': [
          {
            'id': 'ps-2',
            'pack_ejercicio_id': 'pe-2',
            'numero_serie': 2,
            'repeticiones': 6,
            'peso': null,
            'rir': 1,
          },
          {
            'id': 'ps-1',
            'pack_ejercicio_id': 'pe-2',
            'numero_serie': 1,
            'repeticiones': 8,
            'peso': 60.5,
            'rir': 2,
          },
        ],
      },
      {
        'id': 'pe-1',
        'pack_id': 'p-1',
        'ejercicio_id': 'ej-1',
        'orden': 1,
        'descanso_seg': 90,
        'minutos': null,
        'ejercicios': {
          'id': 'ej-1',
          'nombre': 'Press banca',
          'descripcion': 'Tumbado.',
          'tipo': 'fuerza',
          'estado': 'eliminado',
          'creado_en': '2026-10-01T00:00:00.000Z',
        },
        'pack_series': <Map<String, dynamic>>[],
      },
    ],
  };

  test('lee el pack con sus ejercicios y sus series', () {
    final pack = Pack.fromJson(filaDeLaBase());

    expect(pack.nombre, 'Torso A');
    expect(pack.tipos, [TipoEjercicio.fuerza, TipoEjercicio.cardio]);
    expect(pack.ejercicios, hasLength(2));
    expect(pack.ejercicios.first.ejercicio?.nombre, 'Dominadas');
    expect(pack.ejercicios.first.series, hasLength(2));
  });

  test('los ordena, porque PostgREST no promete ningún orden', () {
    final pack = Pack.fromJson(filaDeLaBase());

    expect(pack.ejerciciosOrdenados.map((e) => e.orden), [1, 2]);
    expect(
      pack.ejerciciosOrdenados.last.seriesOrdenadas.map((s) => s.numeroSerie),
      [1, 2],
    );
  });

  test('un ejercicio dado de baja se reconoce', () {
    final pack = Pack.fromJson(filaDeLaBase());
    final porOrden = pack.ejerciciosOrdenados;

    expect(porOrden.first.estaDeBaja, isTrue);
    expect(porOrden.last.estaDeBaja, isFalse);
  });

  test('sabe si tiene algo preparado y si se puede aplicar', () {
    final pack = Pack.fromJson(filaDeLaBase());
    final porOrden = pack.ejerciciosOrdenados;

    expect(pack.sePuedeAplicar, isTrue);
    expect(porOrden.first.tieneAlgoPreparado, isFalse);
    expect(porOrden.last.tieneAlgoPreparado, isTrue);
    expect(pack.siguienteOrden, 3);
  });

  test('un pack vacío no se puede aplicar', () {
    final vacio = Pack.fromJson({
      ...filaDeLaBase(),
      'pack_ejercicios': <Map<String, dynamic>>[],
    });

    expect(vacio.sePuedeAplicar, isFalse);
    expect(vacio.siguienteOrden, 1);
  });

  test('el resultado de aplicar dice cuántos se quedaron fuera', () {
    final resultado = ResultadoAplicarPack.fromJson({
      'ejercicios_anadidos': 2,
      'ejercicios_omitidos': 1,
    });

    expect(resultado.ejerciciosAnadidos, 2);
    expect(resultado.hayOmitidos, isTrue);
  });
}
