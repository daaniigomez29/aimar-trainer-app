import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_inicio_administrador.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_login.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_biblioteca.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/pantalla_clientes.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_ajustes_entrenador.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mi_planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mis_plannings.dart';
import 'package:aimar_trainer_app/features/notificaciones/presentation/pantalla_preferencias_notificacion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_mi_control.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_mi_progreso.dart';
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
        // La pantalla de entrada del entrenador es la planificacion semanal
        // (ui-design 6.6), no un panel de accesos.
        builder: (context, state) => const PantallaPlanificacionEntrenador(),
        routes: [
          GoRoute(
            path: Rutas.biblioteca,
            builder: (context, state) => const PantallaBiblioteca(),
          ),
          GoRoute(
            path: Rutas.clientes,
            builder: (context, state) => const PantallaClientes(),
          ),
          GoRoute(
            path: Rutas.ajustes,
            builder: (context, state) => const PantallaAjustesEntrenador(),
          ),
        ],
      ),
      GoRoute(
        path: Rutas.inicioCliente,
        // La pantalla de entrada del cliente es su planning (ui-design 6.1), no
        // un panel de accesos: lo primero que ve es lo que toca hoy.
        builder: (context, state) => const PantallaMiPlanning(),
        routes: [
          GoRoute(
            path: Rutas.biblioteca,
            builder: (context, state) => const PantallaBiblioteca(),
          ),
          GoRoute(
            path: Rutas.planning,
            builder: (context, state) => const PantallaMisPlannings(),
          ),
          GoRoute(
            path: Rutas.progreso,
            builder: (context, state) => const PantallaMiProgreso(),
          ),
          GoRoute(
            path: Rutas.control,
            builder: (context, state) => const PantallaMiControl(),
          ),
          GoRoute(
            path: Rutas.avisos,
            builder: (context, state) =>
                const PantallaPreferenciasNotificacion(),
          ),
        ],
      ),
      GoRoute(
        path: Rutas.inicioAdministrador,
        builder: (context, state) => const PantallaInicioAdministrador(),
        routes: [
          GoRoute(
            path: Rutas.clientes,
            builder: (context, state) => const PantallaClientes(),
          ),
        ],
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

    // Invitacion aceptada sin contrasena y recuperacion acaban en la misma
    // pantalla; solo cambia el texto que se muestra.
    case SesionDebeFijarContrasena():
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
