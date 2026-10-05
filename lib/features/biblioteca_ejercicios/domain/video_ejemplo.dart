/// Lo que se puede saber de la URL del vídeo de ejemplo sin tocar la red.
///
/// El campo `videoEjemploUrl` acepta cualquier enlace http(s), pero solo los de
/// YouTube se pueden reproducir dentro de la app. Aquí se decide cuál es cuál y
/// se arma la URL del reproductor incrustado.
abstract final class VideoEjemplo {
  /// Las formas en las que YouTube reparte el mismo vídeo. `shorts/` es la que
  /// usa Aimar, pero un enlace copiado desde el escritorio llega como `watch?v=`
  /// y uno compartido desde el móvil como `youtu.be/`.
  ///
  /// El identificador son 11 caracteres de `A-Z a-z 0-9 _ -`.
  static final List<RegExp> _formas = [
    RegExp(r'^https?://(?:www\.)?youtube\.com/watch\?(?:[^#]*&)?v=([\w-]{11})'),
    RegExp(r'^https?://(?:www\.)?youtube\.com/shorts/([\w-]{11})'),
    RegExp(r'^https?://(?:www\.)?youtube\.com/embed/([\w-]{11})'),
    RegExp(r'^https?://(?:www\.)?youtube\.com/live/([\w-]{11})'),
    RegExp(r'^https?://youtu\.be/([\w-]{11})'),
  ];

  /// Identificador del vídeo, o `null` si el enlace no es de YouTube.
  static String? idDeYoutube(String? url) {
    final valor = url?.trim() ?? '';
    if (valor.isEmpty) return null;

    for (final forma in _formas) {
      final encontrado = forma.firstMatch(valor);
      if (encontrado != null) return encontrado.group(1);
    }
    return null;
  }

  /// URL del reproductor incrustado, o `null` si ese enlace no se puede
  /// reproducir aquí.
  ///
  /// Se usa el dominio **sin cookies** de YouTube: no deja rastro en el
  /// navegador del cliente mientras no le dé al play. Es la opción coherente con
  /// una app que maneja datos de salud.
  ///
  /// `rel=0` limita los vídeos sugeridos al final al propio canal, y
  /// `playsinline=1` evita que iOS se lleve el vídeo a pantalla completa él solo.
  static Uri? urlIncrustada(String? url) {
    final id = idDeYoutube(url);
    if (id == null) return null;

    return Uri.parse(
      'https://www.youtube-nocookie.com/embed/$id?rel=0&playsinline=1',
    );
  }

  /// `true` si el vídeo se puede ver sin salir de la app.
  static bool esReproducible(String? url) => idDeYoutube(url) != null;
}
