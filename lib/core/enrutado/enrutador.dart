import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_inicio_administrador.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_inicio_cliente.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_inicio_entrenador.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_login.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_recuperar_contrasena.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_restablecer_contrasena.dart';

part 'enrutador.g.dart';

@Riverpod(keepAlive: true)
GoRouter enrutador(Ref ref) {
  // go_router necesita un Listenable para reevaluar los `redirect`; este puente
  // lo alimenta con los cambios de `ControladorSesion`.
  final notificador = _NotificadorDeSesion();
  ref.listen(controladorSesionProvider, (_, _) => notificador.notificar());
  ref.onDispose(notificador.dispose);

  return GoRouter(
    initialLocation: Rutas.cargando,
    refreshListenable: notificador,
    redirect: (context, estadoRuta) {
      final estadoSesion = ref.read(controladorSesionProvider);
      return _destino(estadoSesion, estadoRuta.matchedLocation);
    },
    routes: [
      GoRoute(
        path: Rutas.cargando,
        builder: (context, state) => const PantallaCargando(),
      ),
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const PantallaLogin(),
      ),
      GoRoute(
        path: Rutas.recuperarContrasena,
        builder: (context, state) => const PantallaRecuperarContrasena(),
      ),
      GoRoute(
        path: Rutas.restablecerContrasena,
        builder: (context, state) => const PantallaRestablecerContrasena(),
      ),
      GoRoute(
        path: Rutas.inicioEntrenador,
        builder: (context, state) => const PantallaInicioEntrenador(),
      ),
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => const PantallaInicioCliente(),
      ),
      GoRoute(
        path: Rutas.inicioAdministrador,
        builder: (context, state) => const PantallaInicioAdministrador(),
      ),
    ],
  );
}

/// Ruta a la que redirigir, o `null` para dejar la actual.
///
/// Funcion pura y de nivel superior para poder probarla sin montar un widget.
@visibleForTesting
String? destinoDeLaRedireccion(EstadoSesion estado, String rutaActual) =>
    _destino(estado, rutaActual);

String? _destino(EstadoSesion estado, String rutaActual) {
  switch (estado) {
    case SesionDesconocida():
      // Sesion sin resolver: se espera en la pantalla de carga, salvo que el
      // usuario venga del enlace del correo (no hay que interrumpirlo).
      return rutaActual == Rutas.restablecerContrasena ? null : Rutas.cargando;

    case SesionRecuperandoContrasena():
      return rutaActual == Rutas.restablecerContrasena
          ? null
          : Rutas.restablecerContrasena;

    case SesionCerrada():
      if (Rutas.publicas.contains(rutaActual)) return null;
      // Tras restablecer la contrasena sin sesion valida se vuelve al login.
      return Rutas.login;

    case SesionActiva(:final perfil):
      final inicio = Rutas.inicioSegunRol(perfil.rol);
      // Con sesion activa no se vuelve al login ni a la pantalla de carga, y
      // cada rol solo entra en su propia seccion (y en las subrutas que se
      // anadiran dentro de ella en fases posteriores).
      if (rutaActual == inicio || rutaActual.startsWith('$inicio/')) {
        return null;
      }
      return inicio;
  }
}

class _NotificadorDeSesion extends ChangeNotifier {
  void notificar() => notifyListeners();
}
