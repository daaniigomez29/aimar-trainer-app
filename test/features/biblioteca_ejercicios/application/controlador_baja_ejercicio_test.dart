import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_baja_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

class RepositorioFalso extends Mock implements EjercicioRepositorio {}

Ejercicio _ejercicio(EstadoEjercicio estado) => Ejercicio(
  id: 'id-1',
  nombre: 'Press banca',
  descripcion: 'Tumbado en banco plano.',
  tipo: TipoEjercicio.fuerza,
  estado: estado,
  creadoEn: DateTime.utc(2026),
);

void main() {
  late RepositorioFalso repositorio;
  late ProviderContainer contenedor;

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.listar())
        .thenAnswer((_) async => const Success(<Ejercicio>[]));
    contenedor = ProviderContainer(
      overrides: [ejercicioRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(contenedor.dispose);
  });

  ControladorBajaEjercicio controlador() =>
      contenedor.read(controladorBajaEjercicioProvider.notifier);

  group('CU-04: comprobacion de uso previa', () {
    test('devuelve el número de usos', () async {
      when(() => repositorio.contarUsosEnPlanningsActivos('id-1'))
          .thenAnswer((_) async => const Success(3));

      expect(await controlador().comprobarUsos('id-1'), 3);
    });

    test(
      'devuelve null si la comprobacion falla, para no darla por buena',
      () async {
        when(() => repositorio.contarUsosEnPlanningsActivos('id-1'))
            .thenAnswer((_) async => const Failure(ErrorConexion()));

        expect(await controlador().comprobarUsos('id-1'), isNull);
      },
    );
  });

  group('CU-04: baja logica', () {
    test('da de baja y marca la accion como completada', () async {
      when(
        () => repositorio.darDeBaja('id-1'),
      ).thenAnswer((_) async => Success(_ejercicio(EstadoEjercicio.eliminado)));

      expect((await controlador().darDeBaja('id-1')).esExito, isTrue);
      expect(
        contenedor.read(controladorBajaEjercicioProvider).completada,
        isTrue,
      );
      verify(() => repositorio.darDeBaja('id-1')).called(1);
    });

    test('propaga el error y no marca completada', () async {
      when(() => repositorio.darDeBaja('id-1'))
          .thenAnswer((_) async => const Failure(ErrorNoAutorizado()));

      expect((await controlador().darDeBaja('id-1')).esFallo, isTrue);
      final estado = contenedor.read(controladorBajaEjercicioProvider);
      expect(estado.error, const ErrorNoAutorizado());
      expect(estado.completada, isFalse);
    });

    test('reactivar deshace la baja', () async {
      when(() => repositorio.reactivar('id-1'))
          .thenAnswer((_) async => Success(_ejercicio(EstadoEjercicio.activo)));

      expect((await controlador().reactivar('id-1')).esExito, isTrue);
      verify(() => repositorio.reactivar('id-1')).called(1);
    });
  });
}
