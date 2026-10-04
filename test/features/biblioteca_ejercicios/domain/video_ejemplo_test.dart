import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/video_ejemplo.dart';

void main() {
  const id = 'dQw4w9WgXcQ';

  group('idDeYoutube', () {
    test('reconoce un short, que es lo que graba el entrenador', () {
      expect(
        VideoEjemplo.idDeYoutube('https://www.youtube.com/shorts/$id'),
        id,
      );
    });

    test('reconoce las demas formas del mismo enlace', () {
      // El mismo video llega distinto segun desde donde se copie: escritorio,
      // boton de compartir del movil, o un enlace ya incrustado.
      expect(
        VideoEjemplo.idDeYoutube('https://www.youtube.com/watch?v=$id'),
        id,
      );
      expect(VideoEjemplo.idDeYoutube('https://youtu.be/$id'), id);
      expect(VideoEjemplo.idDeYoutube('https://www.youtube.com/embed/$id'), id);
      expect(VideoEjemplo.idDeYoutube('http://youtube.com/shorts/$id'), id);
    });

    test('aguanta los parametros que YouTube pega al compartir', () {
      expect(
        VideoEjemplo.idDeYoutube(
          'https://www.youtube.com/watch?app=desktop&v=$id&t=42s',
        ),
        id,
      );
      expect(
        VideoEjemplo.idDeYoutube(
          'https://www.youtube.com/shorts/$id?feature=share',
        ),
        id,
      );
    });

    test('ignora los espacios de alrededor', () {
      expect(VideoEjemplo.idDeYoutube('  https://youtu.be/$id  '), id);
    });

    test('devuelve null para lo que no es un video de YouTube', () {
      expect(VideoEjemplo.idDeYoutube(null), isNull);
      expect(VideoEjemplo.idDeYoutube(''), isNull);
      expect(VideoEjemplo.idDeYoutube('https://vimeo.com/123456'), isNull);
      expect(
        VideoEjemplo.idDeYoutube('https://www.youtube.com/@aimar'),
        isNull,
      );
      // Un identificador que no mide 11 caracteres no es un video.
      expect(VideoEjemplo.idDeYoutube('https://youtu.be/corto'), isNull);
    });
  });

  group('urlIncrustada', () {
    test('usa el dominio sin cookies', () {
      final url = VideoEjemplo.urlIncrustada('https://youtu.be/$id')!;

      // No deja rastro en el navegador del cliente mientras no le de al play.
      expect(url.host, 'www.youtube-nocookie.com');
      expect(url.path, '/embed/$id');
    });

    test('limita las sugerencias y evita la pantalla completa de iOS', () {
      final url = VideoEjemplo.urlIncrustada('https://youtu.be/$id')!;

      expect(url.queryParameters['rel'], '0');
      expect(url.queryParameters['playsinline'], '1');
    });

    test('null cuando el enlace no se puede reproducir aqui', () {
      expect(VideoEjemplo.urlIncrustada('https://vimeo.com/123456'), isNull);
      expect(VideoEjemplo.urlIncrustada(null), isNull);
    });
  });

  test('esReproducible distingue lo que se ve dentro de lo que no', () {
    expect(VideoEjemplo.esReproducible('https://youtu.be/$id'), isTrue);
    expect(VideoEjemplo.esReproducible('https://vimeo.com/123456'), isFalse);
  });
}
