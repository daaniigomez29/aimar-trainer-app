import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_registro_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

class _DatosFalsos extends Fake implements DatosResultadoEjercicio {}

void main() {
  late ProgresoFalso repositorio;

  setUpAll(() => registerFallbackValue(_DatosFalsos()));

  setUp(() => repositorio = ProgresoFalso());

  ProviderContainer contenedor() {
    final container = ProviderContainer(
      overrides: [progresoRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('registra las series y deja el estado en completada', () async {
    when(() => repositorio.registrarResultado(any()))
        .thenAnswer((_) async => const Success(null));
    final container = contenedor();

    final resultado = await container
        .read(controladorRegistroSesionProvider.notifier)
        .registrarFuerza(
          ejercicioPlanificadoId: 'ep-1',
          series: const [DatosSerieRealizada(numeroSerie: 1, repeticiones: 10)],
          planningId: 'p-1',
        );

    expect(resultado.esExito, isTrue);
    expect(container.read(controladorRegistroSesionProvider).completada, true);
  });

  test('no llega al repositorio si los datos no son validos', () async {
    final container = contenedor();

    final resultado = await container
        .read(controladorRegistroSesionProvider.notifier)
        .registrarFuerza(
          ejercicioPlanificadoId: 'ep-1',
          // Repeticiones a cero: lo rechaza el dominio antes de salir.
          series: const [DatosSerieRealizada(numeroSerie: 1, repeticiones: 0)],
          planningId: 'p-1',
        );

    expect(resultado.esFallo, isTrue);
    verifyNever(() => repositorio.registrarResultado(any()));
  });

  test('cardio sin minutos se rechaza antes de construir los datos', () async {
    final container = contenedor();

    final resultado = await container
        .read(controladorRegistroSesionProvider.notifier)
        .registrarCardio(
          ejercicioPlanificadoId: 'ep-1',
          minutos: null,
          planningId: 'p-1',
        );

    expect(resultado.esFallo, isTrue);
    expect(
      container
          .read(controladorRegistroSesionProvider)
          .errorDelCampo('minutos'),
      isNotNull,
    );
    verifyNever(() => repositorio.registrarResultado(any()));
  });

  test('un fallo del repositorio queda en el estado', () async {
    when(() => repositorio.registrarResultado(any()))
        .thenAnswer((_) async => const Failure(ErrorNoAutorizado()));
    final container = contenedor();

    final resultado = await container
        .read(controladorRegistroSesionProvider.notifier)
        .registrarCardio(
          ejercicioPlanificadoId: 'ep-1',
          minutos: 30,
          planningId: 'p-1',
        );

    expect(resultado.esFallo, isTrue);
    expect(
      container.read(controladorRegistroSesionProvider).error,
      isA<ErrorNoAutorizado>(),
    );
  });

  test('manda las series tal cual, incluidas las ya confirmadas', () async {
    when(() => repositorio.registrarResultado(any()))
        .thenAnswer((_) async => const Success(null));
    final container = contenedor();

    await container
        .read(controladorRegistroSesionProvider.notifier)
        .registrarFuerza(
          ejercicioPlanificadoId: 'ep-1',
          series: const [
            DatosSerieRealizada(numeroSerie: 1, repeticiones: 10, peso: 60),
            DatosSerieRealizada(numeroSerie: 2, repeticiones: 8, peso: 62.5),
          ],
          planningId: 'p-1',
        );

    final capturado =
        verify(() => repositorio.registrarResultado(captureAny()))
                .captured
                .single
            as DatosResultadoEjercicio;
    expect(capturado.series.length, 2);
    expect(capturado.minutos, isNull);
    expect(capturado.series.last.peso, 62.5);
  });
}
