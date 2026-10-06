import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_inicio_administrador.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/pantalla_login.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_detalle_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/pantalla_detalle_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/pantalla_formulario_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_plannings_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_formulario_ejercicio_planificado.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/resolver_del_planning.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_ejercicio.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_control_semanal.dart';
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
            routes: [
              // `nuevo` va antes que `:idEjercicio`: si no, se tomaría
              // "nuevo" por un identificador.
              GoRoute(
                path: Rutas.nuevo,
                builder: (context, state) =>
                    const PantallaFormularioEjercicio(),
              ),
              GoRoute(
                path: Rutas.detalleEjercicio,
                builder: (context, state) => PantallaDetalleEjercicio(
                  idEjercicio: state.pathParameters['idEjercicio']!,
                ),
                routes: [
                  GoRoute(
                    path: Rutas.editar,
                    builder: (context, state) => PantallaFormularioEjercicio(
                      idEjercicio: state.pathParameters['idEjercicio'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Rutas.clientes,
            builder: (context, state) => const PantallaClientes(),
            routes: [
              GoRoute(
                path: Rutas.nuevo,
                builder: (context, state) => const PantallaFormularioCliente(),
              ),
              GoRoute(
                path: Rutas.detalleCliente,
                builder: (context, state) => PantallaDetalleCliente(
                  idCliente: state.pathParameters['idCliente']!,
                ),
                routes: [
                  GoRoute(
                    path: Rutas.editar,
                    builder: (context, state) => PantallaFormularioCliente(
                      idCliente: state.pathParameters['idCliente'],
                    ),
                  ),
                  GoRoute(
                    path: Rutas.plannings,
                    builder: (context, state) => PantallaPlanningsCliente(
                      clienteId: state.pathParameters['idCliente']!,
                    ),
                    routes: [
                      GoRoute(
                        path: Rutas.unPlanning,
                        builder: (context, state) => PantallaPlanning(
                          planningId: state.pathParameters['planningId']!,
                        ),
                        routes: [
                          GoRoute(
                            path:
                                '${Rutas.bloques}/${Rutas.unBloque}/'
                                '${Rutas.ejercicioDelBloque}',
                            builder: (context, state) =>
                                _formularioDeEjercicio(state),
                            routes: [
                              GoRoute(
                                path: Rutas.unEjercicioPlanificado,
                                builder: (context, state) =>
                                    _formularioDeEjercicio(state),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Rutas.progreso,
                    builder: (context, state) => PantallaProgreso(
                      clienteId: state.pathParameters['idCliente']!,
                      titulo: state.uri.queryParameters['nombre'],
                    ),
                  ),
                  GoRoute(
                    path: Rutas.controlDelCliente,
                    builder: (context, state) => PantallaControlSemanal(
                      clienteId: state.pathParameters['idCliente']!,
                      soloLectura: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // El entrenador edita el planning en su pantalla de entrada, así que
          // esta ruta solo existe para lo que se abre encima: el formulario de
          // un ejercicio dentro de un bloque.
          GoRoute(
            path:
                '${Rutas.plannings}/${Rutas.unPlanning}/'
                '${Rutas.bloques}/${Rutas.unBloque}/'
                '${Rutas.ejercicioDelBloque}',
            builder: (context, state) => _formularioDeEjercicio(state),
            routes: [
              GoRoute(
                path: Rutas.unEjercicioPlanificado,
                builder: (context, state) => _formularioDeEjercicio(state),
              ),
            ],
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
            routes: [
              GoRoute(
                path: Rutas.detalleEjercicio,
                builder: (context, state) => PantallaDetalleEjercicio(
                  idEjercicio: state.pathParameters['idEjercicio']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Rutas.planning,
            builder: (context, state) => const PantallaMisPlannings(),
            routes: [
              GoRoute(
                path: Rutas.unPlanning,
                builder: (context, state) => PantallaPlanning(
                  planningId: state.pathParameters['planningId']!,
                ),
                routes: [
                  GoRoute(
                    path: '${Rutas.sesiones}/${Rutas.unaSesion}',
                    builder: (context, state) => _registroDeSesion(state),
                    routes: [
                      GoRoute(
                        path:
                            '${Rutas.ejerciciosDeSesion}/'
                            '${Rutas.unEjercicioPlanificado}',
                        builder: (context, state) =>
                            _registroDeEjercicio(state),
                      ),
                    ],
                  ),
                  GoRoute(
                    path:
                        '${Rutas.bloques}/${Rutas.unBloque}/'
                        '${Rutas.ejercicioDelBloque}',
                    builder: (context, state) => _formularioDeEjercicio(state),
                    routes: [
                      GoRoute(
                        path: Rutas.unEjercicioPlanificado,
                        builder: (context, state) =>
                            _formularioDeEjercicio(state),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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

/// El formulario de un ejercicio dentro de un bloque. El bloque y, si se edita,
/// el ejercicio, se resuelven desde el planning: por la URL solo llegan ids.
Widget _formularioDeEjercicio(GoRouterState state) {
  final planningId = state.pathParameters['planningId']!;
  final idBloque = state.pathParameters['idBloque']!;
  final idEjercicio = state.pathParameters['idEjercicioPlanificado'];

  return ResolverDelPlanning<BloqueEjercicio>(
    planningId: planningId,
    buscar: (planning) => bloquePorId(planning, idBloque),
    noEncontrado: 'Ese bloque ya no existe.',
    construir: (planning, bloque) => PantallaFormularioEjercicioPlanificado(
      bloque: bloque,
      planningId: planningId,
      ejercicioPlanificado: idEjercicio == null
          ? null
          : ejercicioPlanificadoPorId(planning, idEjercicio),
    ),
  );
}

/// Registro del resultado de una sesión (CU-20).
Widget _registroDeSesion(GoRouterState state) {
  final planningId = state.pathParameters['planningId']!;
  final idSesion = state.pathParameters['idSesion']!;

  return ResolverDelPlanning<SesionEntrenamiento>(
    planningId: planningId,
    buscar: (planning) => sesionPorId(planning, idSesion),
    noEncontrado: 'Esa sesión ya no existe.',
    construir: (planning, sesion) => PantallaRegistroSesion(
      planningId: planningId,
      sesionId: sesion.id,
      clienteId: planning.clienteId,
    ),
  );
}

/// Registro de un ejercicio suelto dentro de una sesión.
Widget _registroDeEjercicio(GoRouterState state) {
  final planningId = state.pathParameters['planningId']!;
  final idSesion = state.pathParameters['idSesion']!;
  final idEjercicio = state.pathParameters['idEjercicioPlanificado']!;

  return ResolverDelPlanning<EjercicioPlanificado>(
    planningId: planningId,
    buscar: (planning) => ejercicioPlanificadoPorId(planning, idEjercicio),
    noEncontrado: 'Ese ejercicio ya no está en la sesión.',
    construir: (planning, ejercicio) => PantallaRegistroEjercicio(
      ejercicio: ejercicio,
      planningId: planningId,
      clienteId: planning.clienteId,
      sesion: sesionPorId(planning, idSesion),
    ),
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
