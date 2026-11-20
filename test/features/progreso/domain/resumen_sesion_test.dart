import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';
import 'package:aimar_trainer_app/features/progreso/domain/resumen_sesion.dart';

import '../../planificacion_semanal/ayudas_planificacion.dart';

/// POR QUE ESTE TEST: lo que se celebra al terminar tiene que ser verdad. Una
/// "mejora" que no lo es, o un volumen que no cuadra con el informe, quita
/// todo el sentido a celebrarlo.
void main() {
  SerieRealizada hecha(int numero, int reps, double? peso) => SerieRealizada(
    id: 'r$numero',
    ejercicioPlanificadoId: 'ep',
    numeroSerie: numero,
    repeticionesRealizadas: reps,
    fechaHoraRegistro: DateTime(2026),
    pesoReal: peso,
  );

  EjercicioPlanificado ejercicio(
    String id, {
    String nombre = 'Press',
    TipoEjercicio tipo = TipoEjercicio.fuerza,
    bool porLado = false,
    int planificadas = 3,
    List<SerieRealizada> hechas = const [],
    double? minutos,
  }) => ejercicioPlanificadoDePrueba(
    id: id,
    ejercicio: ejercicioDePrueba(
      id: 'ej-$nombre',
      nombre: nombre,
      tipo: tipo,
    ).copyWith(pesoPorLado: porLado),
    series: [
      for (var n = 1; n <= planificadas; n++)
        serieDePrueba(id: '$id-$n', numeroSerie: n),
    ],
  ).copyWith(seriesRealizadas: hechas, minutosRealizados: minutos);

  SesionEntrenamiento sesion(List<EjercicioPlanificado> ejercicios) =>
      sesionDePrueba(bloques: [bloqueDePrueba(ejercicios: ejercicios)]);

  ReferenciaAnterior antes(List<SerieRealizada> series, {double? minutos}) =>
      ReferenciaAnterior(
        series: series,
        fecha: DateTime(2026, 10, 1),
        esSemanaAnterior: true,
        minutos: minutos,
      );

  group('lo hecho', () {
    final resumen = resumirSesion(
      sesion([
        ejercicio(
          'a',
          porLado: true,
          // Una de mas: tambien cuenta, aqui se celebra lo hecho.
          hechas: [
            hecha(1, 10, 20),
            hecha(2, 10, 20),
            hecha(3, 8, 20),
            hecha(4, 8, 20),
          ],
        ),
        ejercicio('b', nombre: 'Plancha', hechas: [hecha(1, 30, null)]),
        ejercicio('c', nombre: 'Curl'),
        ejercicio(
          'd',
          nombre: 'Cinta',
          tipo: TipoEjercicio.cardio,
          planificadas: 0,
          minutos: 15,
        ),
        ejercicio(
          'e',
          nombre: 'Movilidad',
          tipo: TipoEjercicio.fortalecimiento,
          hechas: [hecha(1, 10, 5)],
        ),
      ]),
    );

    test('cuenta los ejercicios y las series hechas', () {
      expect(resumen.ejerciciosHechos, 4);
      expect(resumen.ejerciciosPlanificados, 5);
      expect(resumen.seriesHechas, 6);
      expect(resumen.seriesPlanificadas, 12);
    });

    test('el volumen es solo de fuerza, y el doble si es por lado', () {
      // (20x10 + 20x10 + 20x8 + 20x8) x 2. La plancha no tiene peso y la
      // movilidad no es de fuerza.
      expect(resumen.volumenKg, 1440);
    });

    test('los minutos de cardio', () {
      expect(resumen.minutosCardio, 15);
    });
  });

  group('las mejoras frente a la última vez', () {
    Mejora? mejoraDe(EjercicioPlanificado hoy, ReferenciaAnterior anterior) =>
        resumirSesion(
          sesion([hoy]),
          ultimaVez: {hoy.ejercicioId: anterior},
        ).mejoras.firstOrNull;

    test('más peso en la mejor serie', () {
      final mejora = mejoraDe(
        ejercicio('a', hechas: [hecha(1, 8, 62.5), hecha(2, 10, 60)]),
        antes([hecha(1, 10, 60)]),
      );
      expect(mejora?.tipo, TipoDeMejora.peso);
      expect(mejora?.antes, 60);
      expect(mejora?.ahora, 62.5);
      expect(mejora?.diferencia, 2.5);
    });

    test('mismo peso con más repeticiones', () {
      final mejora = mejoraDe(
        ejercicio('a', hechas: [hecha(1, 10, 60)]),
        antes([hecha(1, 8, 60)]),
      );
      expect(mejora?.tipo, TipoDeMejora.repeticiones);
      expect(mejora?.diferencia, 2);
    });

    test('sin peso, más repeticiones', () {
      final mejora = mejoraDe(
        ejercicio('a', hechas: [hecha(1, 15, null)]),
        antes([hecha(1, 12, null)]),
      );
      expect(mejora?.tipo, TipoDeMejora.repeticiones);
    });

    test('más minutos de cardio', () {
      final mejora = mejoraDe(
        ejercicio(
          'a',
          tipo: TipoEjercicio.cardio,
          planificadas: 0,
          minutos: 25,
        ),
        antes(const [], minutos: 20),
      );
      expect(mejora?.tipo, TipoDeMejora.minutos);
      expect(mejora?.diferencia, 5);
    });

    test('igualar no es mejorar', () {
      expect(
        mejoraDe(
          ejercicio('a', hechas: [hecha(1, 10, 60)]),
          antes([hecha(1, 10, 60)]),
        ),
        isNull,
      );
    });

    test('más repeticiones con menos peso no es mejorar', () {
      expect(
        mejoraDe(
          ejercicio('a', hechas: [hecha(1, 12, 55)]),
          antes([hecha(1, 8, 60)]),
        ),
        isNull,
      );
    });

    test('sin nada hecho hoy, no hay mejora', () {
      expect(mejoraDe(ejercicio('a'), antes([hecha(1, 8, 60)])), isNull);
    });

    test('un ejercicio repetido en la sesión se compara una vez', () {
      final resumen = resumirSesion(
        sesion([
          ejercicio('a', hechas: [hecha(1, 8, 70)]),
          ejercicio('b', hechas: [hecha(1, 8, 70)]),
        ]),
        ultimaVez: {
          'ej-Press': antes([hecha(1, 8, 60)]),
        },
      );
      expect(resumen.mejoras, hasLength(1));
    });
  });

  group('la mejora de una serie suelta', () {
    Mejora? de({required int reps, double? peso, SerieRealizada? anterior}) =>
        mejoraDeLaSerie(
          ejercicio: 'Press',
          repeticiones: reps,
          peso: peso,
          anterior: anterior,
        );

    test('más peso que la misma serie de la última vez', () {
      expect(
        de(reps: 6, peso: 65, anterior: hecha(1, 8, 60))?.tipo,
        TipoDeMejora.peso,
      );
    });

    test('mismo peso con más repeticiones', () {
      final mejora = de(reps: 10, peso: 60, anterior: hecha(1, 8, 60));
      expect(mejora?.tipo, TipoDeMejora.repeticiones);
      expect(mejora?.diferencia, 2);
    });

    test('igualar, o menos peso, no cuenta', () {
      expect(de(reps: 8, peso: 60, anterior: hecha(1, 8, 60)), isNull);
      expect(de(reps: 12, peso: 55, anterior: hecha(1, 8, 60)), isNull);
    });

    test('sin la vez anterior, nada', () {
      expect(de(reps: 10, peso: 60), isNull);
    });
  });

  test('cada mejora dice respecto a cuándo es', () {
    final hoy = ejercicio('a', hechas: [hecha(1, 8, 70)]);
    Mejora mejoraCon(ReferenciaAnterior anterior) => resumirSesion(
      sesion([hoy]),
      ultimaVez: {hoy.ejercicioId: anterior},
    ).mejoras.single;

    final semanaPasada = mejoraCon(antes([hecha(1, 8, 60)]));
    expect(semanaPasada.deLaSemanaPasada, isTrue);

    final masAntigua = mejoraCon(
      ReferenciaAnterior(
        series: [hecha(1, 8, 60)],
        fecha: DateTime(2026, 9, 14),
        esSemanaAnterior: false,
      ),
    );
    expect(masAntigua.deLaSemanaPasada, isFalse);
    expect(masAntigua.fechaAnterior, DateTime(2026, 9, 14));
  });
}
