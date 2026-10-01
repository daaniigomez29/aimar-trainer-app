import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

class RepositorioFalso extends Mock implements AutenticacionRepositorio {}

final _perfilCliente = Perfil(
  id: 'id-cliente',
  rol: RolUsuario.cliente,
  creadoEn: DateTime.utc(2026),
);

void main() {
  late RepositorioFalso repositorio;
  late StreamController<EventoAutenticacion> eventos;
  late ProviderContainer contenedor;

  setUp(() {
    repositorio = RepositorioFalso();
    eventos = StreamController<EventoAutenticacion>.broadcast();
    when(() => repositorio.cambiosDeAutenticacion)
        .thenAnswer((_) => eventos.stream);
    when(() => repositorio.debeFijarContrasena).thenReturn(false);
    contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(repositorio),
      ],
    );
    addTearDown(() {
      contenedor.dispose();
      eventos.close();
    });
  });

  /// Deja que el evento recorra el stream y que se resuelva el perfil.
  Future<void> procesarEventos() => Future<void>.delayed(Duration.zero);

  test('arranca sin saber si hay sesion', () {
    expect(
      contenedor.read(controladorSesionProvider),
      isA<SesionDesconocida>(),
    );
  });

  test('resuelve el perfil al iniciarse la sesion', () async {
    when(() => repositorio.idUsuarioActual).thenReturn('id-cliente');
    when(() => repositorio.perfilDeLaSesion())
        .thenAnswer((_) async => Success(_perfilCliente));
    contenedor.listen(controladorSesionProvider, (_, _) {});

    eventos.add(EventoAutenticacion.sesionIniciada);
    await procesarEventos();

    expect(
      contenedor.read(controladorSesionProvider),
      SesionActiva(_perfilCliente),
    );
    expect(contenedor.read(rolActualProvider), RolUsuario.cliente);
  });

  test('una cuenta sin perfil no queda autenticada a medias', () async {
    when(() => repositorio.idUsuarioActual).thenReturn('id-sin-perfil');
    when(() => repositorio.perfilDeLaSesion())
        .thenAnswer((_) async => const Failure(ErrorPerfilSinRol()));
    contenedor.listen(controladorSesionProvider, (_, _) {});

    eventos.add(EventoAutenticacion.sesionIniciada);
    await procesarEventos();

    expect(contenedor.read(controladorSesionProvider), isA<SesionCerrada>());
    expect(contenedor.read(rolActualProvider), isNull);
  });

  test('el cierre de sesion deja el estado en SesionCerrada', () async {
    contenedor.listen(controladorSesionProvider, (_, _) {});

    eventos.add(EventoAutenticacion.sesionCerrada);
    await procesarEventos();

    expect(contenedor.read(controladorSesionProvider), isA<SesionCerrada>());
    verifyNever(() => repositorio.perfilDeLaSesion());
  });

  test(
    'el enlace de recuperacion abre el estado de recuperacion (CU-24)',
    () async {
      contenedor.listen(controladorSesionProvider, (_, _) {});

      eventos.add(EventoAutenticacion.recuperacionContrasena);
      await procesarEventos();

      expect(
        contenedor.read(controladorSesionProvider),
        isA<SesionRecuperandoContrasena>(),
      );
    },
  );

  test('tras actualizar el usuario se vuelve a resolver el perfil', () async {
    when(() => repositorio.idUsuarioActual).thenReturn('id-cliente');
    when(() => repositorio.perfilDeLaSesion())
        .thenAnswer((_) async => Success(_perfilCliente));
    contenedor.listen(controladorSesionProvider, (_, _) {});

    eventos.add(EventoAutenticacion.recuperacionContrasena);
    await procesarEventos();
    eventos.add(EventoAutenticacion.usuarioActualizado);
    await procesarEventos();

    expect(
      contenedor.read(controladorSesionProvider),
      SesionActiva(_perfilCliente),
    );
  });

  test(
    'renovar el token no vuelve a pedir el perfil si ya hay sesion',
    () async {
      when(() => repositorio.idUsuarioActual).thenReturn('id-cliente');
      when(() => repositorio.perfilDeLaSesion())
          .thenAnswer((_) async => Success(_perfilCliente));
      contenedor.listen(controladorSesionProvider, (_, _) {});
      eventos.add(EventoAutenticacion.sesionIniciada);
      await procesarEventos();

      eventos.add(EventoAutenticacion.tokenRenovado);
      await procesarEventos();

      verify(() => repositorio.perfilDeLaSesion()).called(1);
    },
  );

  test('sin usuario en Auth el perfil no se consulta', () async {
    when(() => repositorio.idUsuarioActual).thenReturn(null);
    contenedor.listen(controladorSesionProvider, (_, _) {});

    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    expect(contenedor.read(controladorSesionProvider), isA<SesionCerrada>());
    verifyNever(() => repositorio.perfilDeLaSesion());
  });

  test('cerrarSesion delega en el repositorio', () async {
    when(() => repositorio.cerrarSesion())
        .thenAnswer((_) async => const Success(null));
    contenedor.listen(controladorSesionProvider, (_, _) {});

    await contenedor.read(controladorSesionProvider.notifier).cerrarSesion();

    verify(() => repositorio.cerrarSesion()).called(1);
    expect(contenedor.read(controladorSesionProvider), isA<SesionCerrada>());
  });

  group('CU-17: cliente recien invitado', () {
    test('no entra en la app: va a fijar contrasena', () async {
      // GoTrue emite `signedIn` para un enlace de invitacion, igual que para un
      // login normal. Sin distinguirlo, el cliente entraria sin contrasena y
      // despues no podria volver a entrar nunca.
      when(() => repositorio.idUsuarioActual).thenReturn('id-invitado');
      when(() => repositorio.debeFijarContrasena).thenReturn(true);
      contenedor.listen(controladorSesionProvider, (_, _) {});

      eventos.add(EventoAutenticacion.sesionIniciada);
      await procesarEventos();

      expect(
        contenedor.read(controladorSesionProvider),
        isA<SesionDebeFijarContrasena>(),
      );
      // Ni se consulta el perfil: no hay a donde enrutarlo todavia.
      verifyNever(() => repositorio.perfilDeLaSesion());
    });

    test('tras fijar la contrasena ya entra con normalidad', () async {
      when(() => repositorio.idUsuarioActual).thenReturn('id-invitado');
      when(() => repositorio.debeFijarContrasena).thenReturn(true);
      when(() => repositorio.perfilDeLaSesion())
          .thenAnswer((_) async => Success(_perfilCliente));
      contenedor.listen(controladorSesionProvider, (_, _) {});
      eventos.add(EventoAutenticacion.sesionIniciada);
      await procesarEventos();

      // `establecerNuevaContrasena` limpia la marca y Auth emite userUpdated.
      when(() => repositorio.debeFijarContrasena).thenReturn(false);
      eventos.add(EventoAutenticacion.usuarioActualizado);
      await procesarEventos();

      expect(
        contenedor.read(controladorSesionProvider),
        SesionActiva(_perfilCliente),
      );
    });
  });
}
