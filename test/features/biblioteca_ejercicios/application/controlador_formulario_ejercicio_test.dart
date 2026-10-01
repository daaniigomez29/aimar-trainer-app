import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

class RepositorioFalso extends Mock implements EjercicioRepositorio {}

final _ejercicio = Ejercicio(
  id: 'id-1',
  nombre: 'Press banca',
  descripcion: 'Tumbado en banco plano.',
  tipo: TipoEjercicio.fuerza,
  estado: EstadoEjercicio.activo,
  creadoEn: DateTime.utc(2026),
);

const _datosValidos = DatosEjercicio(
  nombre: 'Press banca',
  descripcion: 'Tumbado en banco plano.',
  tipo: TipoEjercicio.fuerza,
);

void main() {
  late RepositorioFalso repositorio;
  late ProviderContainer contenedor;

  setUpAll(() {
    registerFallbackValue(_datosValidos);
  });

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.listar())
        .thenAnswer((_) async => const Success(<Ejercicio>[]));
    contenedor = ProviderContainer(
      overrides: [ejercicioRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(contenedor.dispose);
  });

  ControladorFormularioEjercicio controlador() =>
      contenedor.read(controladorFormularioEjercicioProvider.notifier);

  group('CU-02 anadir ejercicio', () {
    test('no llama al repositorio si falta el nombre', () async {
      final guardado = await controlador().guardar(
        datos: const DatosEjercicio(
          nombre: '  ',
          descripcion: 'Algo.',
          tipo: TipoEjercicio.fuerza,
        ),
      );

      expect(guardado, isNull);
      expect(
        contenedor
            .read(controladorFormularioEjercicioProvider)
            .errorDelCampo('nombre'),
        isNotNull,
      );
      verifyNever(() => repositorio.crear(any()));
    });

    test('no llama al repositorio si falta la descripcion', () async {
      await controlador().guardar(
        datos: const DatosEjercicio(
          nombre: 'Sentadilla',
          descripcion: '',
          tipo: TipoEjercicio.fuerza,
        ),
      );

      expect(
        contenedor
            .read(controladorFormularioEjercicioProvider)
            .errorDelCampo('descripcion'),
        isNotNull,
      );
      verifyNever(() => repositorio.crear(any()));
    });

    test('crea el ejercicio y marca la accion como completada', () async {
      when(() => repositorio.crear(any()))
          .thenAnswer((_) async => Success(_ejercicio));

      final guardado = await controlador().guardar(datos: _datosValidos);

      expect(guardado, _ejercicio);
      expect(
        contenedor.read(controladorFormularioEjercicioProvider).completada,
        isTrue,
      );
      verify(() => repositorio.crear(any())).called(1);
      verifyNever(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      );
    });

    test('propaga el nombre duplicado (CU-02, excepcion)', () async {
      when(() => repositorio.crear(any())).thenAnswer(
        (_) async => const Failure(
          ErrorNombreDuplicado('Ya existe un ejercicio activo con ese nombre.'),
        ),
      );

      final guardado = await controlador().guardar(datos: _datosValidos);

      expect(guardado, isNull);
      final estado = contenedor.read(controladorFormularioEjercicioProvider);
      expect(estado.error, isA<ErrorNombreDuplicado>());
      expect(estado.errorGeneral, isNotNull);
      expect(estado.completada, isFalse);
    });

    test('propaga que el rol no puede escribir en la biblioteca', () async {
      when(() => repositorio.crear(any()))
          .thenAnswer((_) async => const Failure(ErrorNoAutorizado()));

      await controlador().guardar(datos: _datosValidos);

      expect(
        contenedor.read(controladorFormularioEjercicioProvider).error,
        const ErrorNoAutorizado(),
      );
    });
  });

  group('CU-03 editar ejercicio', () {
    test('con id llama a editar, no a crear', () async {
      when(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      ).thenAnswer((_) async => Success(_ejercicio));

      final guardado = await controlador().guardar(
        datos: _datosValidos,
        id: 'id-1',
      );

      expect(guardado, _ejercicio);
      verify(
        () => repositorio.editar(
          id: 'id-1',
          datos: any(named: 'datos'),
        ),
      ).called(1);
      verifyNever(() => repositorio.crear(any()));
    });

    test('valida igual que al crear', () async {
      await controlador().guardar(
        datos: const DatosEjercicio(
          nombre: 'Sentadilla',
          descripcion: 'Algo.',
          tipo: TipoEjercicio.fuerza,
          videoEjemploUrl: 'no-es-una-url',
        ),
        id: 'id-1',
      );

      expect(
        contenedor
            .read(controladorFormularioEjercicioProvider)
            .errorDelCampo('videoEjemploUrl'),
        isNotNull,
      );
      verifyNever(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      );
    });
  });

  test('limpiarError y reiniciar vuelven al estado inicial', () async {
    when(() => repositorio.crear(any()))
        .thenAnswer((_) async => const Failure(ErrorNombreDuplicado()));
    await controlador().guardar(datos: _datosValidos);

    controlador().limpiarError();
    expect(
      contenedor.read(controladorFormularioEjercicioProvider).error,
      isNull,
    );

    controlador().reiniciar();
    expect(
      contenedor.read(controladorFormularioEjercicioProvider).completada,
      isFalse,
    );
  });
}
