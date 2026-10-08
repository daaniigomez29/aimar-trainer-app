import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

/// Sección de la navegación en la que está la pantalla, sea quien sea quien
/// mire.
///
/// POR QUE UN ENUM Y NO LA RUTA: una misma pantalla la ven los dos roles y cada
/// uno la tiene colgando de un destino distinto. El planning de un cliente es
/// "Mi planning" para él y "Clientes" para el entrenador; pedir la ruta obligaría
/// a cada pantalla a resolver el rol por su cuenta.
enum SeccionDeNavegacion {
  inicio,
  biblioteca,
  clientes,
  progreso,
  control,
  ajustes;

  /// La ruta del destino que queda marcado para [rol].
  String rutaPara(RolUsuario rol) {
    final esEntrenador = rol.esEntrenador || rol == RolUsuario.administrador;
    return switch (this) {
      SeccionDeNavegacion.inicio => Rutas.inicioSegunRol(rol),
      SeccionDeNavegacion.biblioteca => Rutas.bibliotecaSegunRol(rol),
      // El entrenador no tiene destino de progreso ni de control: lo consulta
      // dentro de la ficha del cliente, que cuelga de Clientes.
      SeccionDeNavegacion.clientes ||
      SeccionDeNavegacion.progreso ||
      SeccionDeNavegacion.control =>
        esEntrenador
            ? Rutas.clientesEntrenador
            : switch (this) {
                SeccionDeNavegacion.progreso => Rutas.progresoCliente,
                SeccionDeNavegacion.control => Rutas.controlCliente,
                _ => Rutas.inicioCliente,
              },
      SeccionDeNavegacion.ajustes =>
        esEntrenador ? Rutas.ajustesEntrenador : Rutas.avisosCliente,
    };
  }
}

/// Andamio de cualquier pantalla con sesión abierta: le pone la navegación que
/// corresponde al rol de quien mira.
///
/// POR QUE EXISTE: la barra no debe desaparecer nunca. Las pantallas de detalle
/// y los formularios montaban un `Scaffold` pelado, así que entrar en un
/// ejercicio, en una ficha o en el registro de una sesión dejaba al usuario sin
/// ninguna navegación a la vista: solo podía salir con la flecha de atrás.
///
/// Las de autenticación son la excepción y no usan esto: sin sesión no hay a
/// dónde navegar.
class PantallaConNavegacion extends ConsumerWidget {
  const PantallaConNavegacion({
    required this.seccion,
    required this.cuerpo,
    this.appBar,
    this.ctaInferior,
    this.botonFlotante,
    super.key,
  });

  final SeccionDeNavegacion seccion;
  final Widget cuerpo;
  final PreferredSizeWidget? appBar;

  /// Botón fijo sobre la barra, para el cliente (registrar, guardar...).
  final Widget? ctaInferior;

  /// Botón flotante, para el entrenador (nuevo planning, nuevo cliente...).
  final Widget? botonFlotante;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sin rol resuelto todavía se pinta el cuerpo tal cual: es un instante, y
    // es mejor que parpadear con la barra del rol equivocado.
    final rol = ref.watch(rolActualProvider);
    if (rol == null) return Scaffold(appBar: appBar, body: cuerpo);

    final ruta = seccion.rutaPara(rol);

    return rol.esCliente
        ? PantallaCliente(
            rutaActual: ruta,
            appBar: appBar,
            ctaInferior: ctaInferior,
            cuerpo: cuerpo,
          )
        : PantallaEntrenador(
            rutaActual: ruta,
            appBar: appBar,
            botonFlotante: botonFlotante,
            cuerpo: ctaInferior == null
                ? cuerpo
                : Column(
                    children: [
                      Expanded(child: cuerpo),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ctaInferior,
                      ),
                    ],
                  ),
          );
  }
}
