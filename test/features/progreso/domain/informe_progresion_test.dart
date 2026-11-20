import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/domain/informe_progresion.dart';

import '../../planificacion_semanal/ayudas_planificacion.dart';
import 'informe_de_prueba.dart';

/// POR QUE ESTE TEST: el informe sustituye a tres consultas SQL con las que
/// Aimar ya hizo un informe a mano. Si las cifras no salen igual, el PDF de la
/// app contradiria al que ya tiene el cliente. Las reglas que se prueban son
/// las de aquellas consultas (ver `informe_progresion.dart`); con los datos
/// reales de un cliente se contrasto que coinciden cifra a cifra.
void main() {
  final informe = calcularInforme(planningsDePrueba());
  final primera = informe.semanas.first;
  final segunda = informe.semanas.last;

  group('resumen semanal', () {
    test('las semanas salen en orden aunque lleguen desordenadas', () {
      expect(informe.semanas.map((s) => s.semana), [
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 12),
      ]);
    });

    test('una sesión sin ejercicios no cuenta como planificada', () {
      expect(primera.sesionesPlanificadas, 2);
      expect(primera.sesionesHechas, 1);
    });

    test('una serie planificada cuenta como hecha si tiene su realizada', () {
      expect(primera.seriesPlanificadas, 4);
      expect(primera.seriesHechas, 2);
      expect(primera.pctSeries, 50);
    });

    test('el volumen es peso x reps, y el doble si el peso es por lado', () {
      // Press por lado: (8x12 + 20x8 + 20x8) x 2, mas el curl, 10x10.
      expect(primera.volumenPlanificado, 932);
      // Hechas: 8x12 y 20x8, por lado.
      expect(primera.volumenReal, 512);
    });

    test('el cardio suma minutos y no volumen', () {
      expect(primera.minutosCardioPlanificados, 10);
      expect(primera.minutosCardioHechos, 8);
    });

    test('el RIR medio es de las series, no de las medias', () {
      expect(primera.rirMedioPlanificado, closeTo(7 / 3, 0.001));
      expect(primera.rirMedioReal, 2);
      // 3, 2, 2 y 2, 2 planificados; 3, 1 y 1, 2 reales.
      expect(informe.rirMedioPlanificado, closeTo(11 / 5, 0.001));
      expect(informe.rirMedioReal, closeTo(7 / 4, 0.001));
    });

    test('cuenta las series idénticas al plan', () {
      expect(primera.seriesIdenticasAlPlan, 1);
      expect(segunda.seriesIdenticasAlPlan, 1);
      expect(informe.pctIdenticasAlPlan, 50);
    });

    test('los totales del periodo', () {
      expect(informe.sesionesPlanificadas, 3);
      expect(informe.sesionesHechas, 2);
      expect(informe.seriesPlanificadas, 6);
      expect(informe.seriesHechas, 4);
      expect(informe.volumenMedioReal, (512 + 640) / 2);
    });
  });

  group('inicio frente a final', () {
    final press = informe.inicioFinal.single;

    test('solo entran los ejercicios con un inicio y un final', () {
      // El curl no se llego a hacer.
      expect(press.nombre, 'Press');
    });

    test('el inicio es la serie más pesada de la primera semana', () {
      // No la mas ligera (8 x 12), que es de aproximacion.
      expect(press.inicio.peso, 20);
      expect(press.inicio.repeticiones, 8);
      expect(press.inicio.fecha, DateTime(2026, 10, 5));
    });

    test('el final es la mejor serie de la última sesión hecha', () {
      expect(press.fin.peso, 24);
      expect(press.fin.repeticiones, 6);
      expect(press.fin.fecha, DateTime(2026, 10, 14));
    });

    test('las diferencias', () {
      expect(press.diferenciaKg, 4);
      expect(press.diferenciaPct, 20);
      expect(press.inicio.rmEstimado, closeTo(20 * (1 + 8 / 30), 0.001));
      expect(press.fin.rmEstimado, closeTo(24 * 1.2, 0.001));
    });

    test('sin grupo muscular van a "sin clasificar"', () {
      expect(informe.inicioFinalPorGrupo.keys, [null]);
    });
  });

  test('la progresión semana a semana de cada ejercicio de fuerza', () {
    expect(informe.ejercicios.map((e) => e.nombre), ['Curl', 'Press']);
    final press = informe.ejercicios.last;
    expect(press.pesoPorLado, isTrue);
    expect(press.semanas.first.pesoMaxReal, 20);
    expect(press.semanas.first.rmEstimado, closeTo(20 * (1 + 8 / 30), 0.001));
    expect(press.semanas.last.seriesHechas, 2);
  });

  test('un ejercicio que no es de fuerza no entra en la progresión', () {
    final soloCardio = calcularInforme([
      planningDePrueba(
        fechaInicio: DateTime(2026, 10, 5),
        sesiones: [
          sesionDePrueba(
            fechaRealizada: DateTime(2026, 10, 6),
            bloques: [
              bloqueDePrueba(
                ejercicios: [
                  ejercicioPlanificadoDePrueba(
                    ejercicio: ejercicioDePrueba(tipo: TipoEjercicio.cardio),
                    minutosPlanificados: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ]);

    expect(soloCardio.ejercicios, isEmpty);
    expect(soloCardio.inicioFinal, isEmpty);
    expect(soloCardio.volumenMedioReal, isNull);
    expect(soloCardio.pctSeries, isNull);
  });

  test('sin plannings, un informe vacío', () {
    final vacio = calcularInforme(const <PlanningSemanal>[]);
    expect(vacio.estaVacio, isTrue);
    expect(vacio.rirMedioReal, isNull);
  });

  // Peticion de Aimar (2026-11-17): valora por mesociclos (p. ej. 2 de 4
  // semanas), no semana a semana. El entrenador dice desde que semana y de
  // cuantas son; el reparto es automatico.
  group('mesociclos', () {
    final desde = DateTime(2026, 9, 7);
    DateTime semana(int n) => DateTime(2026, 9, 7 + 7 * n);
    List<int> mesos(int semanasPorMesociclo, {int cuantas = 8}) => [
      for (var n = 0; n < cuantas; n++)
        mesocicloDeLaSemana(
          semana(n),
          desde: desde,
          semanasPorMesociclo: semanasPorMesociclo,
        ),
    ];

    test(
      '8 semanas en mesociclos de 4: las 4 primeras el 1, el resto el 2',
      () {
        expect(mesos(4), [1, 1, 1, 1, 2, 2, 2, 2]);
      },
    );

    test('en mesociclos de 2, cada pareja de semanas es uno', () {
      expect(mesos(2), [1, 1, 2, 2, 3, 3, 4, 4]);
    });

    test('si no salen justas, el corto es el último', () {
      expect(mesos(4, cuantas: 6), [1, 1, 1, 1, 2, 2]);
    });

    test('sin dividir, todo es el 1', () {
      expect(mesos(0), everyElement(1));
    });

    test('un cambio de hora no descuadra las semanas', () {
      // El 25/10/2026 se atrasa la hora: del 19 al 26 no son 7 x 24 horas.
      expect(semanasEntre(DateTime(2026, 10, 19), DateTime(2026, 10, 26)), 1);
      expect(semanasEntre(DateTime(2026, 3, 23), DateTime(2026, 3, 30)), 1);
    });

    group('las semanas del periodo', () {
      PlanningSemanal de(
        String id,
        DateTime fecha, {
        EstadoPlanning estado = EstadoPlanning.activo,
      }) => planningDePrueba(id: id, fechaInicio: fecha, estado: estado);

      test('solo las de su rango, en orden', () {
        final periodo = planningsDelPeriodo(
          [
            de('d', semana(3)),
            de('a', semana(-1)),
            de('b', semana(0)),
            de('e', semana(4)),
            de('c', semana(1)),
          ],
          desde: desde,
          cuantas: 4,
        );
        expect(periodo.map((p) => p.id), ['b', 'c', 'd']);
      });

      test('si una semana se rehízo, cuenta la activa', () {
        final periodo = planningsDelPeriodo(
          [
            de('vieja', semana(0), estado: EstadoPlanning.archivado),
            de('nueva', semana(0)),
          ],
          desde: desde,
          cuantas: 1,
        );
        expect(periodo.single.id, 'nueva');
      });
    });

    test('cada mesociclo resume solo sus semanas', () {
      // Las del informe de prueba son del 5/10 y el 12/10.
      final mesociclos = mesociclosDe(
        informe,
        desde: DateTime(2026, 10, 5),
        semanasPorMesociclo: 1,
      );

      expect(mesociclos.map((m) => m.numero), [1, 2]);
      expect(mesociclos.first.sesionesPlanificadas, 2);
      expect(mesociclos.first.seriesHechas, 2);
      expect(mesociclos.last.inicio, DateTime(2026, 10, 12));
      expect(mesociclos.last.fin, DateTime(2026, 10, 18));
      expect(mesociclos.last.volumenMedioReal, 640);
    });

    test('un mesociclo sin semanas no renumera a los demás', () {
      // Empezando el 28/09 en mesociclos de 1, esa semana no tiene planning:
      // el 5/10 sigue siendo el 2, no pasa a ser el 1.
      final mesociclos = mesociclosDe(
        informe,
        desde: DateTime(2026, 9, 28),
        semanasPorMesociclo: 1,
      );
      expect(mesociclos.map((m) => m.numero), [2, 3]);
    });
  });
}
