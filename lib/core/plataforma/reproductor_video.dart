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
///
/// EMPIEZA INERTE, Y ESO ES A PROPOSITO: un iframe se queda con la rueda y con
/// el dedo, asi que al pasar por encima del video la pantalla dejaba de
/// desplazarse sin que se entendiera por que. Mientras no se toca, el video no
/// recibe nada y los gestos le llegan a Flutter, que es quien desplaza. Un toque
/// se lo devuelve al reproductor y a partir de ahi se comporta como cualquier
/// video incrustado.
class ReproductorVideo extends StatefulWidget {
  const ReproductorVideo({
    required this.url,
    this.relacionDeAspecto,
    super.key,
  });

  final Uri url;

  /// Por defecto, vertical 9:16: los videos del entrenador son shorts.
  final double? relacionDeAspecto;

  /// Lo que se lee sobre el video hasta que se toca. Vive aqui, con el resto
  /// del texto de la aplicacion, aunque lo pinte el elemento del DOM.
  static const String avisoDeActivacion = 'Toca para activar el vídeo';

  /// `false` donde no se puede reproducir nada. La pantalla lo consulta para
  /// decidir si ofrece el reproductor o el enlace suelto.
  static bool get estaSoportado => reproductorSoportado;

  @override
  State<ReproductorVideo> createState() => _EstadoReproductorVideo();
}

class _EstadoReproductorVideo extends State<ReproductorVideo> {
  bool _activo = false;

  @override
  void initState() {
    super.initState();
    // El iframe se reutiliza entre visitas a la misma ficha, asi que puede
    // llegar activado de la vez anterior. Se vuelve a dejar inerte para que el
    // aviso diga la verdad y la pantalla se siga pudiendo desplazar.
    bloquearInteraccionConElVideo(widget.url);
  }

  @override
  void dispose() {
    // Y al salir tambien: el elemento sobrevive al widget, asi que si se queda
    // activado, el siguiente que lo monte heredaria el estado.
    bloquearInteraccionConElVideo(widget.url);
    super.dispose();
  }

  void _activar() {
    permitirInteraccionConElVideo(widget.url);
    setState(() => _activo = true);
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: widget.relacionDeAspecto ?? 9 / 16,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          construirReproductor(widget.url, ReproductorVideo.avisoDeActivacion),
          // Solo captura el toque, no pinta nada: el aviso lo dibuja el propio
          // elemento del DOM, porque una vista de plataforma va POR ENCIMA del
          // lienzo y cualquier cosa que pintara Flutter aqui quedaria debajo
          // del video. El arrastre vertical lo sigue ganando la lista de
          // debajo, que es justo lo que se quiere.
          if (!_activo)
            GestureDetector(
              key: const Key('activar_video'),
              behavior: HitTestBehavior.opaque,
              onTap: _activar,
            ),
        ],
      ),
    ),
  );
}
