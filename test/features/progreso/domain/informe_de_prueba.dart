import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

import '../../planificacion_semanal/ayudas_planificacion.dart';

/// Dos semanas con lo justo para comprobar cada regla del informe.
///
/// Semana del 5/10:
/// - Dia 1, hecho el 6/10: Press **por lado** (8x12 de aproximacion y dos de
///   20x8; hechas la primera igual que el plan y la segunda a 20x8 con RIR 1)
///   y Cinta (10 min planificados, 8 hechos).
/// - Dia 2, sin hacer: Curl, 10x10.
/// - Dia 3, sin ningun ejercicio.
///
/// Semana del 12/10:
/// - Dia 1, hecho el 14/10: Press 22x8 dos veces; hechas 24x6 y 22x8 (igual
///   que el plan).
///
/// Se devuelven al reves a proposito: el informe tiene que ordenarlas.
List<PlanningSemanal> planningsDePrueba() {
  final press = ejercicioDePrueba(
    id: 'ej-press',
    nombre: 'Press',
  ).copyWith(pesoPorLado: true);
  final curl = ejercicioDePrueba(id: 'ej-curl', nombre: 'Curl');
  final cinta = ejercicioDePrueba(
    id: 'ej-cinta',
    nombre: 'Cinta',
    tipo: TipoEjercicio.cardio,
  );

  SerieRealizada hecha(String ep, int numero, int reps, double peso, int rir) =>
      SerieRealizada(
        id: '$ep-r$numero',
        ejercicioPlanificadoId: ep,
        numeroSerie: numero,
        repeticionesRealizadas: reps,
        fechaHoraRegistro: DateTime(2026),
        pesoReal: peso,
        rirReal: rir,
      );

  final semana1 = planningDePrueba(
    id: 'p-1',
    fechaInicio: DateTime(2026, 10, 5),
    sesiones: [
      sesionDePrueba(
        id: 's-1',
        planningId: 'p-1',
        fechaRealizada: DateTime(2026, 10, 6),
        bloques: [
          bloqueDePrueba(
            id: 'b-1',
            sesionId: 's-1',
            ejercicios: [
              ejercicioPlanificadoDePrueba(
                id: 'ep-1',
                bloqueId: 'b-1',
                ejercicio: press,
                series: [
                  serieDePrueba(
                    id: 'sp-1',
                    ejercicioPlanificadoId: 'ep-1',
                    repeticiones: 12,
                    peso: 8,
                    rir: 3,
                  ),
                  serieDePrueba(
                    id: 'sp-2',
                    ejercicioPlanificadoId: 'ep-1',
                    numeroSerie: 2,
                    repeticiones: 8,
                    peso: 20,
                    rir: 2,
                  ),
                  serieDePrueba(
                    id: 'sp-3',
                    ejercicioPlanificadoId: 'ep-1',
                    numeroSerie: 3,
                    repeticiones: 8,
                    peso: 20,
                    rir: 2,
                  ),
                ],
              ).copyWith(
                seriesRealizadas: [
                  hecha('ep-1', 1, 12, 8, 3),
                  hecha('ep-1', 2, 8, 20, 1),
                ],
              ),
              ejercicioPlanificadoDePrueba(
                id: 'ep-2',
                bloqueId: 'b-1',
                orden: 2,
                ejercicio: cinta,
                minutosPlanificados: 10,
              ).copyWith(minutosRealizados: 8),
            ],
          ),
        ],
      ),
      sesionDePrueba(
        id: 's-2',
        planningId: 'p-1',
        orden: 2,
        bloques: [
          bloqueDePrueba(
            id: 'b-2',
            sesionId: 's-2',
            ejercicios: [
              ejercicioPlanificadoDePrueba(
                id: 'ep-3',
                bloqueId: 'b-2',
                ejercicio: curl,
                series: [
                  serieDePrueba(
                    id: 'sp-4',
                    ejercicioPlanificadoId: 'ep-3',
                    peso: 10,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      sesionDePrueba(id: 's-3', planningId: 'p-1', orden: 3),
    ],
  );

  final semana2 = planningDePrueba(
    id: 'p-2',
    fechaInicio: DateTime(2026, 10, 12),
    sesiones: [
      sesionDePrueba(
        id: 's-4',
        planningId: 'p-2',
        fechaRealizada: DateTime(2026, 10, 14),
        bloques: [
          bloqueDePrueba(
            id: 'b-4',
            sesionId: 's-4',
            ejercicios: [
              ejercicioPlanificadoDePrueba(
                id: 'ep-4',
                bloqueId: 'b-4',
                ejercicio: press,
                series: [
                  serieDePrueba(
                    id: 'sp-5',
                    ejercicioPlanificadoId: 'ep-4',
                    repeticiones: 8,
                    peso: 22,
                    rir: 2,
                  ),
                  serieDePrueba(
                    id: 'sp-6',
                    ejercicioPlanificadoId: 'ep-4',
                    numeroSerie: 2,
                    repeticiones: 8,
                    peso: 22,
                    rir: 2,
                  ),
                ],
              ).copyWith(
                seriesRealizadas: [
                  hecha('ep-4', 1, 6, 24, 1),
                  hecha('ep-4', 2, 8, 22, 2),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return [semana2, semana1];
}
