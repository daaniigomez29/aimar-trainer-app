import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';

import '../ayudas_planificacion.dart';

class PlanningFalso extends Mock implements PlanningRepositorio {}

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

/// POR QUE ESTE TEST: la referencia tiene dos fuentes y el orden importa. Si el
/// historico pisara a la semana anterior, el entrenador veria un dato mas viejo
/// creyendo que es el ultimo; y si el historico se consultara siempre, serian
/// viajes de mas en cada planning.
void main() {
  late PlanningFalso plannings;
  late ProgresoFalso progreso;

  SerieRealizada serieHecha({int numero = 1, double? peso, int reps = 10}) =>
      SerieRealizada(
        id: 'sr-$numero',
        ejercicioPlanificadoId: 'ep-ant',
        numeroSerie: numero,
        repeticionesRealizadas: reps,
        pesoReal: peso,
        fechaHoraRegistro: DateTime.utc(2026, 9, 30),
      );

  /// El planning que el entrenador tiene abierto: Dia 1 con un press.
  PlanningSemanal actual({String ejercicioId = 'ej-press'}) => planningDePrueba(
    id: 'p-act',
    fechaInicio: DateTime(2026, 10, 5),
    sesiones: [
      sesionDePrueba(
        orden: 1,
        bloques: [
          bloqueDePrueba(
            ejercicios: [
              ejercicioPlanificadoDePrueba(
                ejercicio: ejercicioDePrueba(id: ejercicioId),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  setUp(() {
    plannings = PlanningFalso();
    progreso = ProgresoFalso();
  });

  ProviderContainer contenedor() {
    final c = ProviderContainer(
      overrides: [
        planningRepositorioProvider.overrideWithValue(plannings),
        progresoRepositorioProvider.overrideWithValue(progreso),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<Map<String, dynamic>> leer(ProviderContainer c) async {
    final referencias = await c.read(
      referenciasDeSesionProvider('p-act', 1).future,
    );
    return {for (final e in referencias.entries) e.key: e.value};
  }

  test('usa el Día 1 de la semana anterior y no toca el historico', () async {
    final anterior = planningDePrueba(
      id: 'p-ant',
      fechaInicio: DateTime(2026, 9, 28),
      sesiones: [
        sesionDePrueba(
          orden: 1,
          fechaRealizada: DateTime(2026, 9, 30),
          bloques: [
            bloqueDePrueba(
              ejercicios: [
                ejercicioPlanificadoDePrueba(
                  ejercicio: ejercicioDePrueba(id: 'ej-press'),
                ).copyWith(seriesRealizadas: [serieHecha(peso: 60)]),
              ],
            ),
          ],
        ),
      ],
    );
    when(() => plannings.obtenerPlanningCompleto('p-act'))
        .thenAnswer((_) async => Success(actual()));
    when(() => plannings.obtenerPlanningCompleto('p-ant'))
        .thenAnswer((_) async => Success(anterior));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([actual(), anterior]));

    final referencias = await leer(contenedor());

    expect(referencias['ej-press'].esSemanaAnterior, isTrue);
    expect(referencias['ej-press'].serieNumero(1).pesoReal, 60);
    expect(referencias['ej-press'].fecha, DateTime(2026, 9, 30));
    verifyNever(
      () => progreso.ultimoDeCadaEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioIds: any(named: 'ejercicioIds'),
        antesDe: any(named: 'antesDe'),
      ),
    );
  });

  test('si esa semana no lo hizo, tira del historico y lo dice', () async {
    // La semana pasada existe, pero su Dia 1 no tenia ese ejercicio.
    final anterior = planningDePrueba(
      id: 'p-ant',
      fechaInicio: DateTime(2026, 9, 28),
      sesiones: [sesionDePrueba(orden: 1)],
    );
    when(() => plannings.obtenerPlanningCompleto('p-act'))
        .thenAnswer((_) async => Success(actual()));
    when(() => plannings.obtenerPlanningCompleto('p-ant'))
        .thenAnswer((_) async => Success(anterior));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([actual(), anterior]));
    when(
      () => progreso.ultimoDeCadaEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioIds: any(named: 'ejercicioIds'),
        antesDe: any(named: 'antesDe'),
      ),
    ).thenAnswer(
      (_) async => Success([
        // Dos dias distintos: tiene que quedarse con el mas reciente.
        _registro(fecha: DateTime(2026, 9, 2), serie: 1, peso: 50),
        _registro(fecha: DateTime(2026, 9, 9), serie: 1, peso: 55),
        _registro(fecha: DateTime(2026, 9, 9), serie: 2, peso: 55),
      ]),
    );

    final referencias = await leer(contenedor());

    expect(referencias['ej-press'].esSemanaAnterior, isFalse);
    expect(referencias['ej-press'].fecha, DateTime(2026, 9, 9));
    expect(referencias['ej-press'].series, hasLength(2));
    expect(referencias['ej-press'].serieNumero(1).pesoReal, 55);
  });

  test('sin semana anterior, el historico es la única fuente', () async {
    when(() => plannings.obtenerPlanningCompleto('p-act'))
        .thenAnswer((_) async => Success(actual()));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([actual()]));
    when(
      () => progreso.ultimoDeCadaEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioIds: any(named: 'ejercicioIds'),
        antesDe: any(named: 'antesDe'),
      ),
    ).thenAnswer(
      (_) async =>
          Success([_registro(fecha: DateTime(2026, 8, 3), serie: 1, peso: 40)]),
    );

    final referencias = await leer(contenedor());

    expect(referencias['ej-press'].fecha, DateTime(2026, 8, 3));
  });

  test(
    'si el historico falla, la pantalla se queda sin referencia, no rota',
    () async {
      when(() => plannings.obtenerPlanningCompleto('p-act'))
          .thenAnswer((_) async => Success(actual()));
      when(() => plannings.listarDeCliente(any()))
          .thenAnswer((_) async => const Failure(ErrorConexion()));
      when(
        () => progreso.ultimoDeCadaEjercicio(
          clienteId: any(named: 'clienteId'),
          ejercicioIds: any(named: 'ejercicioIds'),
          antesDe: any(named: 'antesDe'),
        ),
      ).thenAnswer((_) async => const Failure(ErrorConexion()));

      expect(await leer(contenedor()), isEmpty);
    },
  );

  test('una sesión sin ejercicios no pregunta nada', () async {
    when(() => plannings.obtenerPlanningCompleto('p-act')).thenAnswer(
      (_) async => Success(
        planningDePrueba(id: 'p-act', sesiones: [sesionDePrueba(orden: 1)]),
      ),
    );

    expect(await leer(contenedor()), isEmpty);
    verifyNever(() => plannings.listarDeCliente(any()));
  });
}

RegistroProgreso _registro({
  required DateTime fecha,
  required int serie,
  required double peso,
}) => RegistroProgreso(
  clienteId: 'cli-1',
  ejercicioId: 'ej-press',
  ejercicioNombre: 'Press banca',
  ejercicioTipo: TipoEjercicio.fuerza,
  sesionId: 's-vieja',
  fecha: fecha,
  numeroSerie: serie,
  repeticionesRealizadas: 10,
  pesoReal: peso,
);
