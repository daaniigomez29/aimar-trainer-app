import 'dart:async';

import 'package:flutter/material.dart';

/// Los avisos de la aplicación (los `SnackBar` de abajo).
///
/// POR QUE ESTA AQUI: el tema no puede fijar la duración (`SnackBarThemeData` no
/// la tiene), así que cada aviso usaba la de por defecto —cuatro segundos— o la
/// suya propia. Centralizarla deja un único sitio donde cambiarla.
abstract final class Avisos {
  /// Lo que tarda un aviso en irse solo.
  static const Duration duracion = Duration(seconds: 3);

  /// Los que ofrecen deshacer duran algo más: tres segundos no dan tiempo a
  /// leer el mensaje y decidir, y cuando el aviso se va, se va la única forma de
  /// echar atrás sin repetir el trabajo a mano.
  static const Duration duracionConAccion = Duration(seconds: 6);

  /// Muestra un aviso con el mensaje indicado.
  ///
  /// [accion] es opcional; cuando se pasa, el aviso dura [duracionConAccion].
  static void mostrar(
    BuildContext context,
    String mensaje, {
    SnackBarAction? accion,
  }) => mostrarEn(ScaffoldMessenger.of(context), mensaje, accion: accion);

  /// Igual, pero sobre un `ScaffoldMessengerState` ya capturado.
  ///
  /// Hace falta cuando el aviso sobrevive a la pantalla que lo lanzó: al dar de
  /// baja desde una ficha, esa ficha se cierra y con ella moriría su
  /// `BuildContext`. El messenger vive en el `MaterialApp`, así que sigue
  /// sirviendo.
  static void mostrarEn(
    ScaffoldMessengerState messenger,
    String mensaje, {
    SnackBarAction? accion,
  }) {
    final control = messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: accion == null ? duracion : duracionConAccion,
        action: accion,
      ),
    );

    // POR QUE UN TEMPORIZADOR A MANO: Flutter **no cierra solo** los avisos que
    // llevan acción, por mucha `duration` que se les ponga; los deja hasta que
    // alguien los aparta. Comprobado: sin acción se cierra, con acción no, ni a
    // los 3 s ni a los 20. Como aquí el aviso con acción es el de "Deshacer",
    // ese era justo el que se quedaba clavado en pantalla.
    if (accion == null) return;
    final temporizador = Timer(duracionConAccion, control.close);
    // Si se cierra antes (al pulsar Deshacer, o porque llega otro aviso), no
    // tiene sentido seguir esperando para cerrar algo que ya no está.
    control.closed.whenComplete(temporizador.cancel);
  }
}
