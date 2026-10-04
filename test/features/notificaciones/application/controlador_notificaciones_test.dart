import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';
import 'package:aimar_trainer_app/features/notificaciones/application/controlador_notificaciones.dart';
import 'package:aimar_trainer_app/features/notificaciones/data/notificaciones_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/notificaciones/domain/preferencias_notificacion.dart';

class PushFalso extends Mock implements ServicioPush {}

class NotificacionesFalso extends Mock implements NotificacionesRepositorio {}

class _SuscripcionFalsa extends Fake implements DatosSuscripcionPush {}

const _cliente = 'cli-1';

const _suscripcion = DatosSuscripcionPush(
  endpoint: 'https://push.ejemplo/abc',
  claveP256dh: 'p256',
  claveAuth: 'auth',
);

void main() {
  late PushFalso push;
  late NotificacionesFalso repositorio;

  setUpAll(() => registerFallbackValue(_SuscripcionFalsa()));

  setUp(() {
    push = PushFalso();
    repositorio = NotificacionesFalso();
    when(() => push.estaSoportado).thenReturn(true);
    when(() => push.permiso).thenReturn(EstadoPermisoPush.sinPreguntar);
    when(
      () => repositorio.guardarSuscripcion(
        clienteId: any(named: 'clienteId'),
        suscripcion: any(named: 'suscripcion'),
      ),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => repositorio.guardarPushActivado(
        clienteId: any(named: 'clienteId'),
        activado: any(named: 'activado'),
      ),
    ).thenAnswer(
      (invocacion) async => Success(
        PreferenciasNotificacion(
          clienteId: _cliente,
          pushActivado: invocacion.namedArguments[#activado] as bool,
        ),
      ),
    );
    when(
      () => repositorio.eliminarSuscripcion(endpoint: any(named: 'endpoint')),
    ).thenAnswer((_) async => const Success(null));
  });

  ProviderContainer contenedor() {
    final container = ProviderContainer(
      overrides: [
        servicioPushProvider.overrideWithValue(push),
        notificacionesRepositorioProvider.overrideWithValue(repositorio),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('activar guarda la suscripcion y marca la preferencia', () async {
    when(() => push.suscribir(any()))
        .thenAnswer((_) async => const Success(_suscripcion));
    final container = contenedor();

    final resultado = await container
        .read(controladorNotificacionesProvider.notifier)
        .activar(_cliente);

    expect(resultado.esExito, isTrue);
    verify(
      () => repositorio.guardarSuscripcion(
        clienteId: _cliente,
        suscripcion: _suscripcion,
      ),
    ).called(1);
    verify(
      () =>
          repositorio.guardarPushActivado(clienteId: _cliente, activado: true),
    ).called(1);
  });

  test(
    'si el usuario no da permiso, NO se marca la preferencia como activada',
    () async {
      // Marcarla dejaria el push "activado" sin ningun dispositivo al que
      // enviar, y la Edge Function lo anotaria como fallido cada dia.
      when(() => push.suscribir(any()))
          .thenAnswer((_) async => const Success(null));
      final container = contenedor();

      final resultado = await container
          .read(controladorNotificacionesProvider.notifier)
          .activar(_cliente);

      expect(resultado.esFallo, isTrue);
      verifyNever(
        () => repositorio.guardarPushActivado(
          clienteId: any(named: 'clienteId'),
          activado: any(named: 'activado'),
        ),
      );
      verifyNever(
        () => repositorio.guardarSuscripcion(
          clienteId: any(named: 'clienteId'),
          suscripcion: any(named: 'suscripcion'),
        ),
      );
    },
  );

  test('un navegador sin push ni siquiera lo intenta', () async {
    when(() => push.estaSoportado).thenReturn(false);
    final container = contenedor();

    final resultado = await container
        .read(controladorNotificacionesProvider.notifier)
        .activar(_cliente);

    expect(resultado.esFallo, isTrue);
    expect(resultado.errorONulo, isA<ErrorValidacion>());
    verifyNever(() => push.suscribir(any()));
  });

  test(
    'con el permiso denegado explica que hay que cambiarlo a mano',
    () async {
      when(() => push.permiso).thenReturn(EstadoPermisoPush.denegado);
      final container = contenedor();

      final resultado = await container
          .read(controladorNotificacionesProvider.notifier)
          .activar(_cliente);

      expect(resultado.errorONulo?.mensaje, contains('bloqueado'));
      verifyNever(() => push.suscribir(any()));
    },
  );

  test('desactivar apaga la preferencia y borra el dispositivo', () async {
    when(() => push.desuscribir())
        .thenAnswer((_) async => const Success('https://push.ejemplo/abc'));
    final container = contenedor();

    final resultado = await container
        .read(controladorNotificacionesProvider.notifier)
        .desactivar(_cliente);

    expect(resultado.esExito, isTrue);
    verify(
      () =>
          repositorio.guardarPushActivado(clienteId: _cliente, activado: false),
    ).called(1);
    verify(
      () =>
          repositorio.eliminarSuscripcion(endpoint: 'https://push.ejemplo/abc'),
    ).called(1);
  });

  test('si el navegador no devuelve endpoint, la preferencia se apaga igual', () async {
    // Lo que decide si se envia o no es la preferencia, asi que apagarla es lo
    // que no puede fallar.
    when(() => push.desuscribir()).thenAnswer((_) async => const Success(null));
    final container = contenedor();

    final resultado = await container
        .read(controladorNotificacionesProvider.notifier)
        .desactivar(_cliente);

    expect(resultado.esExito, isTrue);
    verify(
      () =>
          repositorio.guardarPushActivado(clienteId: _cliente, activado: false),
    ).called(1);
    verifyNever(
      () => repositorio.eliminarSuscripcion(endpoint: any(named: 'endpoint')),
    );
  });

  test('un fallo al guardar la suscripcion no marca la preferencia', () async {
    when(() => push.suscribir(any()))
        .thenAnswer((_) async => const Success(_suscripcion));
    when(
      () => repositorio.guardarSuscripcion(
        clienteId: any(named: 'clienteId'),
        suscripcion: any(named: 'suscripcion'),
      ),
    ).thenAnswer((_) async => const Failure(ErrorNoAutorizado()));
    final container = contenedor();

    final resultado = await container
        .read(controladorNotificacionesProvider.notifier)
        .activar(_cliente);

    expect(resultado.esFallo, isTrue);
    verifyNever(
      () => repositorio.guardarPushActivado(
        clienteId: any(named: 'clienteId'),
        activado: any(named: 'activado'),
      ),
    );
  });
}
