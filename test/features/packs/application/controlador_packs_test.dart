import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/application/controlador_packs.dart';
import 'package:aimar_trainer_app/features/packs/data/pack_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack_repositorio.dart';

class PackFalso extends Mock implements PackRepositorio {}

class _DatosFalsos extends Fake implements DatosPack {}

class _DatosEjercicioFalsos extends Fake implements DatosPackEjercicio {}

void main() {
  late PackFalso repositorio;
  late ProviderContainer contenedor;

  final pack = Pack(
    id: 'p-1',
    nombre: 'Torso A',
    tipo: TipoEjercicio.fuerza,
    creadoEn: DateTime.utc(2026, 10, 19),
  );

  setUpAll(() {
    registerFallbackValue(_DatosFalsos());
    registerFallbackValue(_DatosEjercicioFalsos());
  });

  setUp(() {
    repositorio = PackFalso();
    contenedor = ProviderContainer(
      overrides: [packRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(contenedor.dispose);
  });

  ControladorPacks controlador() =>
      contenedor.read(controladorPacksProvider.notifier);

  group('crear', () {
    test('un nombre vacío ni llega al repositorio', () async {
      final resultado = await controlador().crear(
        const DatosPack(nombre: '  ', tipo: TipoEjercicio.fuerza),
      );

      expect(resultado.esFallo, isTrue);
      // Pero sí queda en el estado, para que la pantalla lo pinte.
      expect(contenedor.read(controladorPacksProvider).error, isA<ErrorApp>());
      verifyNever(() => repositorio.crear(any()));
    });

    test('con datos válidos, guarda y recarga la lista', () async {
      when(() => repositorio.crear(any()))
          .thenAnswer((_) async => Success(pack));
      when(() => repositorio.listar()).thenAnswer((_) async => Success([pack]));
      // La lista tiene que estar viva para poder comprobar que se recarga.
      await contenedor.read(listaPacksProvider.future);

      final resultado = await controlador().crear(
        const DatosPack(nombre: 'Torso A', tipo: TipoEjercicio.fuerza),
      );

      expect(resultado.esExito, isTrue);
      expect(contenedor.read(controladorPacksProvider).completada, isTrue);
      verify(() => repositorio.crear(any())).called(1);
    });

    test('un fallo del repositorio queda en el estado', () async {
      when(() => repositorio.crear(any()))
          .thenAnswer((_) async => const Failure(ErrorConexion()));

      final resultado = await controlador().crear(
        const DatosPack(nombre: 'Torso A', tipo: TipoEjercicio.fuerza),
      );

      expect(resultado.esFallo, isTrue);
      expect(
        contenedor.read(controladorPacksProvider).error,
        isA<ErrorConexion>(),
      );
    });
  });

  group('ejercicios del pack', () {
    const datos = DatosPackEjercicio(
      packId: 'p-1',
      ejercicioId: 'ej-1',
      tipo: TipoEjercicio.fuerza,
      orden: 1,
    );

    test('guardar uno sin series es válido y llega al repositorio', () async {
      when(
        () => repositorio.guardarEjercicio(
          datos: any(named: 'datos'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Success('pe-1'));

      final resultado = await controlador().guardarEjercicio(datos: datos);

      expect(resultado.esExito, isTrue);
      verify(() => repositorio.guardarEjercicio(datos: datos, id: null))
          .called(1);
    });

    test('reordenar manda la lista entera, en orden', () async {
      when(
        () => repositorio.reordenarEjercicios(
          packId: any(named: 'packId'),
          idsEnOrden: any(named: 'idsEnOrden'),
        ),
      ).thenAnswer((_) async => const Success(null));

      await controlador().reordenarEjercicios(
        packId: 'p-1',
        idsEnOrden: const ['pe-2', 'pe-1'],
      );

      verify(
        () => repositorio.reordenarEjercicios(
          packId: 'p-1',
          idsEnOrden: const ['pe-2', 'pe-1'],
        ),
      ).called(1);
    });
  });

  test('aplicar a un bloque devuelve cuántos se quedaron fuera', () async {
    when(
      () => repositorio.aplicarABloque(
        packId: any(named: 'packId'),
        bloqueId: any(named: 'bloqueId'),
      ),
    ).thenAnswer(
      (_) async => const Success(
        ResultadoAplicarPack(ejerciciosAnadidos: 2, ejerciciosOmitidos: 1),
      ),
    );

    final resultado = await controlador().aplicarABloque(
      packId: 'p-1',
      bloqueId: 'b-1',
    );

    expect(resultado.valorONulo?.hayOmitidos, isTrue);
  });

  test('no se solapan dos operaciones', () async {
    when(() => repositorio.eliminar(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Success(null);
    });

    final primera = controlador().eliminar('p-1');
    final segunda = await controlador().eliminar('p-2');

    expect(segunda.esFallo, isTrue);
    await primera;
    verify(() => repositorio.eliminar('p-1')).called(1);
    verifyNever(() => repositorio.eliminar('p-2'));
  });
}
