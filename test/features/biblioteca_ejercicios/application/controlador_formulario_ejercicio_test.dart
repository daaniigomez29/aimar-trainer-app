import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';
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

final _imagen = ImagenParaSubir(
  bytes: Uint8List.fromList(const [1, 2, 3]),
  extension: 'png',
  tipoMime: 'image/png',
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
    registerFallbackValue(_imagen);
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

  group('CU-02 añadir ejercicio', () {
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

    test('no llama al repositorio si falta la descripción', () async {
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

  group('imagen del ejercicio', () {
    setUp(() {
      when(() => repositorio.subirImagen(any()))
          .thenAnswer((_) async => const Success('123.png'));
      when(() => repositorio.eliminarImagen(any()))
          .thenAnswer((_) async => const Success(null));
    });

    test('se sube antes de guardar y la fila se queda con su ruta', () async {
      when(() => repositorio.crear(any()))
          .thenAnswer((_) async => Success(_ejercicio));

      await controlador().guardar(datos: _datosValidos, imagenNueva: _imagen);

      verify(() => repositorio.subirImagen(_imagen)).called(1);
      final enviados =
          verify(() => repositorio.crear(captureAny())).captured.single
              as DatosEjercicio;
      expect(enviados.imagenRuta, '123.png');
    });

    test('si el guardado falla, la imagen subida se borra', () async {
      // Si no, quedaria un fichero en el bucket al que no apunta ninguna fila.
      when(() => repositorio.crear(any()))
          .thenAnswer((_) async => const Failure(ErrorNombreDuplicado()));

      final guardado = await controlador().guardar(
        datos: _datosValidos,
        imagenNueva: _imagen,
      );

      expect(guardado, isNull);
      verify(() => repositorio.eliminarImagen('123.png')).called(1);
    });

    test('al reemplazarla se borra la anterior', () async {
      when(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      ).thenAnswer((_) async => Success(_ejercicio));

      await controlador().guardar(
        datos: _datosValidos.conImagen('vieja.png'),
        id: 'id-1',
        imagenNueva: _imagen,
      );

      verify(() => repositorio.eliminarImagen('vieja.png')).called(1);
    });

    test('quitarla deja la ruta a null y borra el fichero', () async {
      when(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      ).thenAnswer((_) async => Success(_ejercicio));

      await controlador().guardar(
        datos: _datosValidos.conImagen('vieja.png'),
        id: 'id-1',
        quitarImagen: true,
      );

      final enviados =
          verify(
                () => repositorio.editar(
                  id: any(named: 'id'),
                  datos: captureAny(named: 'datos'),
                ),
              ).captured.single
              as DatosEjercicio;
      expect(enviados.imagenRuta, isNull);
      verify(() => repositorio.eliminarImagen('vieja.png')).called(1);
    });

    test('sin tocarla, la ruta que ya tenia se mantiene', () async {
      when(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      ).thenAnswer((_) async => Success(_ejercicio));

      await controlador().guardar(
        datos: _datosValidos.conImagen('vieja.png'),
        id: 'id-1',
      );

      verifyNever(() => repositorio.subirImagen(any()));
      verifyNever(() => repositorio.eliminarImagen(any()));
    });
  });
}
