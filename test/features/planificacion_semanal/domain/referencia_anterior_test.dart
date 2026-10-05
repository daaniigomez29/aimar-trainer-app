import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';

import '../ayudas_planificacion.dart';

/// POR QUE ESTE TEST: lo que se ensena al entrenador tiene que ser de la semana
/// que dice ser. Ensenar de otra semana, o cruzar el ejercicio equivocado porque
/// cambio de posicion, seria peor que no ensenar nada: planificaria sobre datos
/// falsos sin enterarse.
SerieRealizada serieHecha({
  int numero = 1,
  int reps = 10,
  double? peso,
  int? rir,
}) => SerieRealizada(
  id: 'sr-$numero',
  ejercicioPlanificadoId: 'ep-1',
  numeroSerie: numero,
  repeticionesRealizadas: reps,
  pesoReal: peso,
  rirReal: rir,
  fechaHoraRegistro: DateTime.utc(2026, 9, 21),
);

void main() {
  group('planningAnteriorA', () {
    final septiembre = planningDePrueba(
      id: 'p-sep',
      fechaInicio: DateTime(2026, 9, 21),
    );
    final octubre = planningDePrueba(
      id: 'p-oct',
      fechaInicio: DateTime(2026, 9, 28),
    );
    final actual = planningDePrueba(
      id: 'p-act',
      fechaInicio: DateTime(2026, 10, 5),
    );

    test('coge el mas reciente de los anteriores', () {
      final anterior = planningAnteriorA(
        plannings: [septiembre, actual, octubre],
        idActual: actual.id,
        fechaInicioActual: actual.fechaInicio,
      );

      expect(anterior?.id, 'p-oct');
    });

    test('no se coge a si mismo', () {
      final anterior = planningAnteriorA(
        plannings: [actual],
        idActual: actual.id,
        fechaInicioActual: actual.fechaInicio,
      );

      expect(anterior, isNull);
    });

    test('ignora los posteriores', () {
      final futuro = planningDePrueba(
        id: 'p-fut',
        fechaInicio: DateTime(2026, 10, 12),
      );
      final anterior = planningAnteriorA(
        plannings: [futuro, actual],
        idActual: actual.id,
        fechaInicioActual: actual.fechaInicio,
      );

      expect(anterior, isNull);
    });

    test('sin ninguna semana anterior, nada', () {
      expect(
        planningAnteriorA(
          plannings: const [],
          idActual: 'p-act',
          fechaInicioActual: DateTime(2026, 10, 5),
        ),
        isNull,
      );
    });
  });

  group('referenciasDelDia', () {
    PlanningSemanal semanaPasada({int ordenSesion = 1}) => planningDePrueba(
      id: 'p-ant',
      fechaInicio: DateTime(2026, 9, 28),
      sesiones: [
        sesionDePrueba(
          id: 's-ant',
          orden: ordenSesion,
          fechaRealizada: DateTime(2026, 9, 30),
          bloques: [
            bloqueDePrueba(
              ejercicios: [
                ejercicioPlanificadoDePrueba(
                  id: 'ep-ant',
                  ejercicio: ejercicioDePrueba(id: 'ej-press'),
                ).copyWith(
                  seriesRealizadas: [
                    serieHecha(numero: 2, reps: 8, peso: 62.5, rir: 1),
                    serieHecha(numero: 1, reps: 10, peso: 60, rir: 2),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    test('devuelve las series ordenadas y con la fecha de aquel dia', () {
      final referencias = referenciasDelDia(anterior: semanaPasada(), orden: 1);

      final press = referencias['ej-press']!;
      expect(press.series.map((s) => s.numeroSerie), [1, 2]);
      expect(press.serieNumero(1)?.pesoReal, 60);
      expect(press.serieNumero(2)?.repeticionesRealizadas, 8);
      expect(press.fecha, DateTime(2026, 9, 30));
      expect(press.esSemanaAnterior, isTrue);
    });

    test('se cruza por ejercicio, no por posicion', () {
      // El mismo ejercicio, movido a otro bloque y a otro orden.
      final movido = planningDePrueba(
        id: 'p-ant',
        sesiones: [
          sesionDePrueba(
            orden: 1,
            bloques: [
              bloqueDePrueba(id: 'b-1', orden: 1),
              bloqueDePrueba(
                id: 'b-9',
                orden: 9,
                ejercicios: [
                  ejercicioPlanificadoDePrueba(
                    orden: 7,
                    ejercicio: ejercicioDePrueba(id: 'ej-press'),
                  ).copyWith(seriesRealizadas: [serieHecha(peso: 60)]),
                ],
              ),
            ],
          ),
        ],
      );

      expect(
        referenciasDelDia(anterior: movido, orden: 1)['ej-press']?.series,
        hasLength(1),
      );
    });

    test('un ejercicio sin nada registrado no genera referencia', () {
      final sinRegistrar = planningDePrueba(
        sesiones: [
          sesionDePrueba(
            orden: 1,
            bloques: [
              bloqueDePrueba(
                ejercicios: [
                  ejercicioPlanificadoDePrueba(
                    ejercicio: ejercicioDePrueba(id: 'ej-press'),
                    series: [serieDePrueba()],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(referenciasDelDia(anterior: sinRegistrar, orden: 1), isEmpty);
    });

    test('el cardio trae sus minutos', () {
      final conCardio = planningDePrueba(
        sesiones: [
          sesionDePrueba(
            orden: 1,
            bloques: [
              bloqueDePrueba(
                ejercicios: [
                  ejercicioPlanificadoDePrueba(
                    ejercicio: ejercicioDePrueba(id: 'ej-cinta'),
                    minutosPlanificados: 30,
                  ).copyWith(minutosRealizados: 28),
                ],
              ),
            ],
          ),
        ],
      );

      final cinta = referenciasDelDia(
        anterior: conCardio,
        orden: 1,
      )['ej-cinta'];
      expect(cinta?.minutos, 28);
      expect(cinta?.series, isEmpty);
      expect(cinta?.tieneAlgo, isTrue);
    });

    test('si aquella semana no tenia ese Dia N, no hay nada', () {
      expect(referenciasDelDia(anterior: semanaPasada(), orden: 3), isEmpty);
    });
  });

  group('comoPlanificadas (el boton de copiar)', () {
    test('copia kg, reps y RIR tal cual', () {
      final copiadas = comoPlanificadas(
        ReferenciaAnterior(
          series: [
            serieHecha(numero: 1, reps: 10, peso: 60, rir: 2),
            serieHecha(numero: 2, reps: 8, peso: 62.5, rir: 1),
          ],
          fecha: DateTime(2026, 9, 30),
          esSemanaAnterior: true,
        ),
      );

      expect(copiadas, hasLength(2));
      expect(copiadas.first.peso, 60);
      expect(copiadas.first.repeticiones, 10);
      expect(copiadas.first.rir, 2);
      expect(copiadas.last.peso, 62.5);
    });

    test('renumera del 1 aunque falte alguna serie por el camino', () {
      final copiadas = comoPlanificadas(
        ReferenciaAnterior(
          series: [
            serieHecha(numero: 1, reps: 10),
            serieHecha(numero: 3, reps: 6),
          ],
          fecha: null,
          esSemanaAnterior: false,
        ),
      );

      expect(copiadas.map((s) => s.numeroSerie), [1, 2]);
      expect(copiadas.last.repeticiones, 6);
    });

    test('un cardio no copia ninguna serie', () {
      expect(
        comoPlanificadas(
          const ReferenciaAnterior(
            series: [],
            minutos: 28,
            fecha: null,
            esSemanaAnterior: true,
          ),
        ),
        isEmpty,
      );
    });
  });
}
