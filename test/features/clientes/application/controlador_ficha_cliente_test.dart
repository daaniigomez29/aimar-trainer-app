import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_ficha_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';

class RepositorioFalso extends Mock implements ClienteRepositorio {}

const _datosValidos = DatosCliente(
  nombre: 'Ana Garcia',
  correo: 'ana@ejemplo.com',
  diaControlPreferido: DiaSemana.domingo,
);

Cliente _cliente([EstadoCliente estado = EstadoCliente.activo]) => Cliente(
  id: 'id-1',
  nombre: 'Ana Garcia',
  correo: 'ana@ejemplo.com',
  diaControlPreferido: DiaSemana.domingo,
  estado: estado,
  fechaAlta: DateTime.utc(2026),
  fechaBaja: estado == EstadoCliente.baja ? DateTime.utc(2026, 6) : null,
);

void main() {
  late RepositorioFalso repositorio;
  late ProviderContainer contenedor;

  setUpAll(() => registerFallbackValue(_datosValidos));

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.listar())
        .thenAnswer((_) async => const Success(<Cliente>[]));
    contenedor = ProviderContainer(
      overrides: [clienteRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(contenedor.dispose);
  });

  ControladorFichaCliente ficha() =>
      contenedor.read(controladorFichaClienteProvider.notifier);
  ControladorBajaCliente baja() =>
      contenedor.read(controladorBajaClienteProvider.notifier);

  group('CU-17 dar de alta', () {
    test('no llama al repositorio si falta el nombre', () async {
      final resultado = await ficha().darDeAlta(
        const DatosCliente(
          nombre: '',
          correo: 'ana@ejemplo.com',
          diaControlPreferido: DiaSemana.lunes,
        ),
      );

      expect(resultado.esFallo, isTrue);
      expect(
        contenedor
            .read(controladorFichaClienteProvider)
            .errorDelCampo('nombre'),
        isNotNull,
      );
      verifyNever(() => repositorio.darDeAlta(any()));
    });

    test('no llama al repositorio con un correo invalido', () async {
      await ficha().darDeAlta(
        const DatosCliente(
          nombre: 'Ana',
          correo: 'no-es-un-correo',
          diaControlPreferido: DiaSemana.lunes,
        ),
      );

      expect(
        contenedor
            .read(controladorFichaClienteProvider)
            .errorDelCampo('correo'),
        isNotNull,
      );
      verifyNever(() => repositorio.darDeAlta(any()));
    });

    test('devuelve el resultado del alta con la invitación enviada', () async {
      when(() => repositorio.darDeAlta(any())).thenAnswer(
        (_) async => const Success(
          ResultadoAlta(clienteId: 'id-1', invitacionEnviada: true),
        ),
      );

      final resultado = await ficha().darDeAlta(_datosValidos);

      expect(resultado.valorONulo?.clienteId, 'id-1');
      expect(resultado.valorONulo?.invitacionEnviada, isTrue);
      expect(
        contenedor.read(controladorFichaClienteProvider).completada,
        isTrue,
      );
    });

    test('el alta vale aunque la invitación no haya salido', () async {
      // La ficha ya existe: fallar aqui obligaria a volver a darlo de alta.
      when(() => repositorio.darDeAlta(any())).thenAnswer(
        (_) async => const Success(
          ResultadoAlta(
            clienteId: 'id-1',
            invitacionEnviada: false,
            avisoInvitacion: 'Resend no esta configurado.',
          ),
        ),
      );

      final resultado = await ficha().darDeAlta(_datosValidos);

      expect(resultado.esExito, isTrue);
      expect(resultado.valorONulo?.invitacionEnviada, isFalse);
      expect(resultado.valorONulo?.avisoInvitacion, isNotNull);
    });

    test('propaga el correo duplicado (CU-17, excepcion)', () async {
      when(() => repositorio.darDeAlta(any()))
          .thenAnswer((_) async => const Failure(ErrorNombreDuplicado()));

      final resultado = await ficha().darDeAlta(_datosValidos);

      expect(resultado.errorONulo, isA<ErrorNombreDuplicado>());
      expect(
        contenedor.read(controladorFichaClienteProvider).completada,
        isFalse,
      );
    });

    test('propaga que el rol no puede dar de alta', () async {
      when(() => repositorio.darDeAlta(any()))
          .thenAnswer((_) async => const Failure(ErrorNoAutorizado()));

      expect(
        (await ficha().darDeAlta(_datosValidos)).errorONulo,
        const ErrorNoAutorizado(),
      );
    });
  });

  group('CU-19 editar ficha', () {
    test('edita y marca completada', () async {
      when(
        () => repositorio.editar(
          id: any(named: 'id'),
          datos: any(named: 'datos'),
        ),
      ).thenAnswer((_) async => Success(_cliente()));

      final resultado = await ficha().editar(id: 'id-1', datos: _datosValidos);

      expect(resultado.esExito, isTrue);
      verify(
        () => repositorio.editar(
          id: 'id-1',
          datos: any(named: 'datos'),
        ),
      ).called(1);
    });

    test('valida igual que el alta', () async {
      await ficha().editar(
        id: 'id-1',
        datos: const DatosCliente(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          diaControlPreferido: DiaSemana.lunes,
          alturaCm: 10000,
        ),
      );

      expect(
        contenedor
            .read(controladorFichaClienteProvider)
            .errorDelCampo('alturaCm'),
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

  group('CU-18 dar de baja', () {
    test('comprueba los plannings activos antes', () async {
      when(() => repositorio.contarPlanningsActivos('id-1'))
          .thenAnswer((_) async => const Success(2));

      expect(await baja().comprobarPlanningsActivos('id-1'), 2);
    });

    test(
      'devuelve null si no se puede comprobar, sin darlo por bueno',
      () async {
        when(() => repositorio.contarPlanningsActivos('id-1'))
            .thenAnswer((_) async => const Failure(ErrorConexion()));

        expect(await baja().comprobarPlanningsActivos('id-1'), isNull);
      },
    );

    test('da de baja y devuelve la ficha ya de baja', () async {
      when(() => repositorio.darDeBaja('id-1'))
          .thenAnswer((_) async => Success(_cliente(EstadoCliente.baja)));

      final resultado = await baja().darDeBaja('id-1');

      expect(resultado.valorONulo?.estado.estaDeBaja, isTrue);
      expect(resultado.valorONulo?.fechaBaja, isNotNull);
    });

    test('propaga que ya estaba de baja (409 de la Edge Function)', () async {
      when(() => repositorio.darDeBaja('id-1')).thenAnswer(
        (_) async => const Failure(
          ErrorValidacion('Ese cliente ya estaba dado de baja.'),
        ),
      );

      expect((await baja().darDeBaja('id-1')).esFallo, isTrue);
    });
  });
}
