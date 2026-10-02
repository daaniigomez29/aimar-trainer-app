import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';

import '../ayudas_planificacion.dart';

class RepositorioFalso extends Mock implements PlanningRepositorio {}

void main() {
  late RepositorioFalso repositorio;
  late ProviderContainer contenedor;

  setUpAll(() {
    registerFallbackValue(
      DatosPlanning(clienteId: 'cli-1', fechaInicio: DateTime(2026, 10, 5)),
    );
    registerFallbackValue(
      DatosSesion(planningId: 'p-1', fecha: DateTime(2026, 10, 5), nombre: 'x'),
    );
    registerFallbackValue(
      const DatosBloque(sesionId: 's-1', tipo: TipoBloque.fuerza, orden: 1),
    );
    registerFallbackValue(datosEjercicio(tipo: TipoEjercicio.fuerza));
  });

  setUp(() {
    repositorio = RepositorioFalso();
    contenedor = ProviderContainer(
      overrides: [planningRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(contenedor.dispose);
  });

  ControladorPlanificacion controlador() =>
      contenedor.read(controladorPlanificacionProvider.notifier);

  group('CU-05 crear planning', () {
    test('no llama al repositorio sin cliente', () async {
      final resultado = await controlador().crearPlanning(
        DatosPlanning(clienteId: '  ', fechaInicio: DateTime(2026, 10, 5)),
      );

      expect(resultado.esFallo, isTrue);
      verifyNever(() => repositorio.crearPlanning(any()));
    });

    test('crea y marca completada', () async {
      when(() => repositorio.crearPlanning(any()))
          .thenAnswer((_) async => Success(planningDePrueba()));

      final resultado = await controlador().crearPlanning(
        DatosPlanning(clienteId: 'cli-1', fechaInicio: DateTime(2026, 10, 5)),
      );

      expect(resultado.esExito, isTrue);
      expect(
        contenedor.read(controladorPlanificacionProvider).completada,
        isTrue,
      );
    });

    test('propaga el duplicado de semana activa (CU-05, excepcion)', () async {
      when(() => repositorio.crearPlanning(any())).thenAnswer(
        (_) async => const Failure(
          ErrorValidacion(
            'Ese cliente ya tiene un planning activo esa semana.',
          ),
        ),
      );

      final resultado = await controlador().crearPlanning(
        DatosPlanning(clienteId: 'cli-1', fechaInicio: DateTime(2026, 10, 5)),
      );

      expect(resultado.esFallo, isTrue);
      expect(
        contenedor.read(controladorPlanificacionProvider).errorGeneral,
        isNotNull,
      );
    });
  });

  group('CU-06 crear sesion', () {
    final planning = planningDePrueba(fechaInicio: DateTime(2026, 10, 5));

    test(
      'no llama al repositorio si la fecha cae fuera de la semana',
      () async {
        final resultado = await controlador().crearSesion(
          datos: DatosSesion(
            planningId: 'p-1',
            fecha: DateTime(2026, 10, 20),
            nombre: 'Empuje',
          ),
          planning: planning,
        );

        expect(resultado.errorONulo, isA<ErrorValidacion>());
        verifyNever(() => repositorio.crearSesion(any()));
      },
    );

    test('no llama al repositorio si el dia ya tiene sesion', () async {
      final ocupado = planningDePrueba(
        fechaInicio: DateTime(2026, 10, 5),
        sesiones: [sesionDePrueba(fecha: DateTime(2026, 10, 6))],
      );

      final resultado = await controlador().crearSesion(
        datos: DatosSesion(
          planningId: 'p-1',
          fecha: DateTime(2026, 10, 6),
          nombre: 'Otra',
        ),
        planning: ocupado,
      );

      expect(resultado.esFallo, isTrue);
      verifyNever(() => repositorio.crearSesion(any()));
    });

    test('crea cuando la fecha es valida', () async {
      when(() => repositorio.crearSesion(any()))
          .thenAnswer((_) async => Success(sesionDePrueba()));

      final resultado = await controlador().crearSesion(
        datos: DatosSesion(
          planningId: 'p-1',
          fecha: DateTime(2026, 10, 6),
          nombre: 'Empuje',
        ),
        planning: planning,
      );

      expect(resultado.esExito, isTrue);
      verify(() => repositorio.crearSesion(any())).called(1);
    });
  });

  group('CU-08 anadir ejercicio: la exclusion se corta antes de la red', () {
    final bloque = bloqueDePrueba();

    test('un Cardio sin minutos no llega al repositorio', () async {
      final resultado = await controlador().crearEjercicio(
        datos: datosEjercicio(tipo: TipoEjercicio.cardio),
        bloque: bloque,
        planningId: 'p-1',
      );

      expect(resultado.errorONulo, isA<ErrorValidacion>());
      verifyNever(() => repositorio.crearEjercicioPlanificado(any()));
    });

    test('una Fuerza con minutos no llega al repositorio', () async {
      final resultado = await controlador().crearEjercicio(
        datos: datosEjercicio(
          tipo: TipoEjercicio.fuerza,
          minutos: 20,
          series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
        ),
        bloque: bloque,
        planningId: 'p-1',
      );

      expect(resultado.errorONulo, isA<ErrorValidacion>());
      verifyNever(() => repositorio.crearEjercicioPlanificado(any()));
    });

    test('una combinacion valida si llega', () async {
      when(() => repositorio.crearEjercicioPlanificado(any()))
          .thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));

      final resultado = await controlador().crearEjercicio(
        datos: datosEjercicio(
          tipo: TipoEjercicio.fuerza,
          series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
        ),
        bloque: bloque,
        planningId: 'p-1',
      );

      expect(resultado.esExito, isTrue);
      verify(() => repositorio.crearEjercicioPlanificado(any())).called(1);
    });
  });

  group('CU-13 a CU-16 eliminar', () {
    test('elimina planning, sesion, bloque y ejercicio', () async {
      when(() => repositorio.eliminarPlanning(any()))
          .thenAnswer((_) async => const Success(null));
      when(() => repositorio.eliminarSesion(any()))
          .thenAnswer((_) async => const Success(null));
      when(() => repositorio.eliminarBloque(any()))
          .thenAnswer((_) async => const Success(null));
      when(() => repositorio.eliminarEjercicioPlanificado(any()))
          .thenAnswer((_) async => const Success(null));

      expect((await controlador().eliminarPlanning('p-1')).esExito, isTrue);
      controlador().reiniciar();
      expect(
        (await controlador().eliminarSesion(
          id: 's-1',
          planningId: 'p-1',
        )).esExito,
        isTrue,
      );
      controlador().reiniciar();
      expect(
        (await controlador().eliminarBloque(
          id: 'b-1',
          planningId: 'p-1',
        )).esExito,
        isTrue,
      );
      controlador().reiniciar();
      expect(
        (await controlador().eliminarEjercicio(
          id: 'ep-1',
          planningId: 'p-1',
        )).esExito,
        isTrue,
      );
    });

    test('propaga que el rol no puede escribir', () async {
      when(() => repositorio.eliminarPlanning(any()))
          .thenAnswer((_) async => const Failure(ErrorNoAutorizado()));

      expect(
        (await controlador().eliminarPlanning('p-1')).errorONulo,
        const ErrorNoAutorizado(),
      );
    });
  });

  group('archivar y reactivar', () {
    test('archivar deja el planning archivado', () async {
      when(() => repositorio.archivarPlanning('p-1'))
          .thenAnswer((_) async => Success(planningDePrueba()));

      expect((await controlador().archivarPlanning('p-1')).esExito, isTrue);
      verify(() => repositorio.archivarPlanning('p-1')).called(1);
    });
  });

  test('una segunda operacion simultanea se rechaza', () async {
    when(() => repositorio.crearPlanning(any()))
        .thenAnswer((_) async => Success(planningDePrueba()));
    final datos = DatosPlanning(
      clienteId: 'cli-1',
      fechaInicio: DateTime(2026, 10, 5),
    );

    final primera = controlador().crearPlanning(datos);
    final segunda = await controlador().crearPlanning(datos);
    await primera;

    expect(segunda.esFallo, isTrue);
    verify(() => repositorio.crearPlanning(any())).called(1);
  });
}
