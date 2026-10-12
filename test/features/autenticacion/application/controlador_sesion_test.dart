import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/url_de_arranque.dart';
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

  /// Contenedor con el repositorio falso y la URL de arranque que se indique.
  /// Por defecto, una URL limpia: la app abierta con normalidad.
  ProviderContainer contenedorCon({String url = 'https://app.es/'}) {
    final nuevo = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(repositorio),
        urlDeArranqueProvider.overrideWithValue(Uri.parse(url)),
      ],
    );
    addTearDown(nuevo.dispose);
    return nuevo;
  }

  setUp(() {
    repositorio = RepositorioFalso();
    eventos = StreamController<EventoAutenticacion>.broadcast();
    when(() => repositorio.cambiosDeAutenticacion)
        .thenAnswer((_) => eventos.stream);
    when(() => repositorio.debeFijarContrasena).thenReturn(false);
    contenedor = contenedorCon();
    addTearDown(eventos.close);
  });

  /// Deja que el evento recorra el stream y que se resuelva el perfil.
  Future<void> procesarEventos() => Future<void>.delayed(Duration.zero);

  test('arranca sin saber si hay sesión', () {
    expect(
      contenedor.read(controladorSesionProvider),
      isA<SesionDesconocida>(),
    );
  });

  test('resuelve el perfil al iniciarse la sesión', () async {
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

  test('el cierre de sesión deja el estado en SesionCerrada', () async {
    contenedor.listen(controladorSesionProvider, (_, _) {});

    eventos.add(EventoAutenticacion.sesionCerrada);
    await procesarEventos();

    expect(contenedor.read(controladorSesionProvider), isA<SesionCerrada>());
    verifyNever(() => repositorio.perfilDeLaSesion());
  });

  test(
    'el enlace de recuperación abre el estado de recuperación (CU-24)',
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
    'renovar el token no vuelve a pedir el perfil si ya hay sesión',
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
    test('no entra en la app: va a fijar contraseña', () async {
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

    test('tras fijar la contraseña ya entra con normalidad', () async {
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

  /// El fallo del 2026-10-12: el cliente pierde la pantalla de fijar su
  /// contrasena, vuelve a pinchar el enlace del correo —que es de un solo uso—
  /// y la app se queda cargando para siempre, sin forma de establecerla.
  group('enlace de correo que ya no vale', () {
    test('el error de la URL de arranque se sabe sin esperar eventos', () {
      final conError = contenedorCon(
        url: 'https://app.es/#error=access_denied&error_code=otp_expired',
      );

      expect(
        conError.read(controladorSesionProvider),
        const SesionEnlaceInvalido(ErrorEnlaceCaducado()),
      );
    });

    test(
      'un fallo de Auth sin evento mueve el estado, no lo deja colgado',
      () async {
        contenedor.listen(controladorSesionProvider, (_, _) {});

        // Asi reporta el SDK un enlace gastado: error del stream, no evento.
        eventos.addError(const ErrorEnlaceCaducado(), StackTrace.empty);
        await procesarEventos();

        expect(
          contenedor.read(controladorSesionProvider),
          const SesionEnlaceInvalido(ErrorEnlaceCaducado()),
        );
      },
    );

    test('el initialSession sin sesión no borra el motivo', () async {
      // El SDK emite ademas `initialSession` sin sesion. Si eso dejara un
      // `SesionCerrada` encima, el enrutador mandaria al login, donde un
      // invitado no tiene ninguna contrasena que escribir.
      final conError = contenedorCon(
        url: 'https://app.es/#error=access_denied&error_code=otp_expired',
      );
      when(() => repositorio.idUsuarioActual).thenReturn(null);
      conError.listen(controladorSesionProvider, (_, _) {});

      eventos.add(EventoAutenticacion.sesionIniciada);
      await procesarEventos();

      expect(
        conError.read(controladorSesionProvider),
        isA<SesionEnlaceInvalido>(),
      );
    });

    test('un enlace válido después del fallo sí abre sesión', () async {
      final conError = contenedorCon(
        url: 'https://app.es/#error=access_denied&error_code=otp_expired',
      );
      when(() => repositorio.idUsuarioActual).thenReturn('id-invitado');
      when(() => repositorio.debeFijarContrasena).thenReturn(true);
      conError.listen(controladorSesionProvider, (_, _) {});

      eventos.add(EventoAutenticacion.sesionIniciada);
      await procesarEventos();

      expect(
        conError.read(controladorSesionProvider),
        isA<SesionDebeFijarContrasena>(),
      );
    });

    test(
      'con sesión activa, un fallo de Auth no saca a nadie de la app',
      () async {
        when(() => repositorio.idUsuarioActual).thenReturn('id-cliente');
        when(() => repositorio.perfilDeLaSesion())
            .thenAnswer((_) async => Success(_perfilCliente));
        contenedor.listen(controladorSesionProvider, (_, _) {});
        eventos.add(EventoAutenticacion.sesionIniciada);
        await procesarEventos();

        // Por ejemplo un refresco de token que falla sin cobertura.
        eventos.addError(const ErrorConexion(), StackTrace.empty);
        await procesarEventos();

        expect(
          contenedor.read(controladorSesionProvider),
          SesionActiva(_perfilCliente),
        );
      },
    );
  });

  test('un invitado rescatado por recuperación sigue siendo invitado', () async {
    // Llega por un enlace de recuperacion (GoTrue emite `passwordRecovery`),
    // pero no tiene contrasena todavia: manda la invitacion. Si no, la pantalla
    // le habla de "contraseña nueva" y le ofrece volver al acceso, que para el
    // no lleva a ninguna parte.
    when(() => repositorio.debeFijarContrasena).thenReturn(true);
    contenedor.listen(controladorSesionProvider, (_, _) {});

    eventos.add(EventoAutenticacion.recuperacionContrasena);
    await procesarEventos();

    expect(
      contenedor.read(controladorSesionProvider),
      isA<SesionDebeFijarContrasena>(),
    );
  });
}
