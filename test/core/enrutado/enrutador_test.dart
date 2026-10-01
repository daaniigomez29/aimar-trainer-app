import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

Perfil _perfil(RolUsuario rol) =>
    Perfil(id: 'id-1', rol: rol, creadoEn: DateTime.utc(2026));

void main() {
  group('destinoDeLaRedireccion · sesion sin resolver', () {
    test('espera en la pantalla de carga', () {
      expect(
        destinoDeLaRedireccion(const SesionDesconocida(), Rutas.login),
        Rutas.cargando,
      );
    });

    test('no interrumpe a quien llega por el enlace del correo', () {
      expect(
        destinoDeLaRedireccion(
          const SesionDesconocida(),
          Rutas.restablecerContrasena,
        ),
        isNull,
      );
    });
  });

  group('destinoDeLaRedireccion · sin sesion', () {
    test('deja pasar a las rutas publicas', () {
      for (final ruta in Rutas.publicas) {
        expect(destinoDeLaRedireccion(const SesionCerrada(), ruta), isNull);
      }
    });

    test('manda al login desde cualquier ruta privada', () {
      expect(
        destinoDeLaRedireccion(const SesionCerrada(), Rutas.inicioEntrenador),
        Rutas.login,
      );
      expect(
        destinoDeLaRedireccion(const SesionCerrada(), Rutas.cargando),
        Rutas.login,
      );
    });
  });

  group('destinoDeLaRedireccion · invitacion aceptada (CU-17)', () {
    test('fuerza la pantalla de fijar contrasena', () {
      expect(
        destinoDeLaRedireccion(
          const SesionDebeFijarContrasena(),
          Rutas.inicioCliente,
        ),
        Rutas.restablecerContrasena,
      );
    });

    test('no la saca de ahi: sin contrasena no podria volver a entrar', () {
      expect(
        destinoDeLaRedireccion(const SesionDebeFijarContrasena(), Rutas.login),
        Rutas.restablecerContrasena,
      );
      expect(
        destinoDeLaRedireccion(
          const SesionDebeFijarContrasena(),
          Rutas.restablecerContrasena,
        ),
        isNull,
      );
    });
  });

  group('destinoDeLaRedireccion · recuperacion de contrasena (CU-24)', () {
    test('fuerza la pantalla de restablecer desde cualquier otra ruta', () {
      expect(
        destinoDeLaRedireccion(
          const SesionRecuperandoContrasena(),
          Rutas.inicioCliente,
        ),
        Rutas.restablecerContrasena,
      );
    });

    test('se queda si ya esta en la pantalla de restablecer', () {
      expect(
        destinoDeLaRedireccion(
          const SesionRecuperandoContrasena(),
          Rutas.restablecerContrasena,
        ),
        isNull,
      );
    });
  });

  group('destinoDeLaRedireccion · sesion activa (CU-01, paso 6)', () {
    test('lleva a cada rol a su pantalla principal', () {
      final esperado = {
        RolUsuario.entrenador: Rutas.inicioEntrenador,
        RolUsuario.cliente: Rutas.inicioCliente,
        RolUsuario.administrador: Rutas.inicioAdministrador,
      };

      for (final (rol, ruta) in esperado.entries.map((e) => (e.key, e.value))) {
        expect(
          destinoDeLaRedireccion(SesionActiva(_perfil(rol)), Rutas.login),
          ruta,
          reason: 'el rol $rol deberia acabar en $ruta',
        );
      }
    });

    test('no redirige si ya esta en su pantalla principal', () {
      expect(
        destinoDeLaRedireccion(
          SesionActiva(_perfil(RolUsuario.entrenador)),
          Rutas.inicioEntrenador,
        ),
        isNull,
      );
    });

    test('permite las subrutas de su propia seccion', () {
      expect(
        destinoDeLaRedireccion(
          SesionActiva(_perfil(RolUsuario.entrenador)),
          '${Rutas.inicioEntrenador}/ejercicios',
        ),
        isNull,
      );
    });

    test('un rol no entra en la seccion de otro', () {
      expect(
        destinoDeLaRedireccion(
          SesionActiva(_perfil(RolUsuario.cliente)),
          Rutas.inicioEntrenador,
        ),
        Rutas.inicioCliente,
      );
    });
  });
}
