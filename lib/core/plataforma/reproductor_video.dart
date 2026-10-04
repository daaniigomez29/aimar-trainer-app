import 'package:flutter/material.dart';

// Igual que con el push: la implementacion de web usa APIs del navegador, y el
// `if` del import evita que entren en la compilacion de los tests, que corren en
// la VM de Dart.
import 'package:aimar_trainer_app/core/plataforma/reproductor_video_sin_soporte.dart'
    if (dart.library.js_interop) 'package:aimar_trainer_app/core/plataforma/reproductor_video_web.dart';

/// Reproductor de video incrustado, para ver el ejemplo sin salir de la app.
///
/// La implementacion de web monta un iframe como vista de plataforma; fuera de
/// web (tests, y la app movil de una fase futura) no hay reproductor y el widget
/// se queda en nada, para que quien lo use tenga siempre una alternativa a mano.
class ReproductorVideo extends StatelessWidget {
  const ReproductorVideo({
    required this.url,
    this.relacionDeAspecto,
    super.key,
  });

  final Uri url;

  /// Por defecto, vertical 9:16: los videos del entrenador son shorts.
  final double? relacionDeAspecto;

  /// `false` donde no se puede reproducir nada. La pantalla lo consulta para
  /// decidir si ofrece el reproductor o el enlace suelto.
  static bool get estaSoportado => reproductorSoportado;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: relacionDeAspecto ?? 9 / 16,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: construirReproductor(url),
    ),
  );
}
