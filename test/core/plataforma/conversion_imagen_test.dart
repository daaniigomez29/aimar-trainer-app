import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes_flutter.dart';

/// POR QUE ESTE TEST CORRE TAMBIEN EN NAVEGADOR (`flutter test --platform
/// chrome`): la primera version usaba `ImageDescriptor.width`, que en web lanza
/// `UnsupportedError`. En la VM funcionaba, asi que un test solo de VM no habria
/// visto nada. El valor de este archivo esta en ejecutarlo en los dos sitios.

/// Un PNG de verdad del tamano pedido, para no depender de ficheros de ejemplo.
Future<Uint8List> _pngDePrueba({required int ancho, required int alto}) async {
  final grabadora = ui.PictureRecorder();
  Canvas(grabadora).drawRect(
    Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
    Paint()..color = const Color(0xFF1C85FF),
  );
  final dibujo = grabadora.endRecording();
  final imagen = await dibujo.toImage(ancho, alto);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  imagen.dispose();
  dibujo.dispose();
  return datos!.buffer.asUint8List();
}

Future<({int ancho, int alto})> _tamanoDe(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final fotograma = await codec.getNextFrame();
  final tamano = (ancho: fotograma.image.width, alto: fotograma.image.height);
  fotograma.image.dispose();
  codec.dispose();
  return tamano;
}

void main() {
  test('una imagen pequena se convierte sin tocar su tamano', () async {
    final origen = await _pngDePrueba(ancho: 400, alto: 300);

    final resultado = await ServicioImagenesFlutter.convertirAPng(origen);

    expect(resultado.esExito, isTrue);
    final imagen = resultado.valorONulo!;
    expect(imagen.tipoMime, 'image/png');
    expect(imagen.extension, 'png');
    expect(await _tamanoDe(imagen.bytes), (ancho: 400, alto: 300));
  });

  test('una imagen grande se reduce al lado maximo, sin deformarla', () async {
    // 2400x1200 -> el lado mayor baja a 1600 y el otro mantiene la proporcion.
    final origen = await _pngDePrueba(ancho: 2400, alto: 1200);

    final resultado = await ServicioImagenesFlutter.convertirAPng(origen);

    expect(resultado.esExito, isTrue);
    final tamano = await _tamanoDe(resultado.valorONulo!.bytes);
    expect(tamano.ancho, ServicioImagenesFlutter.ladoMaximo);
    expect(tamano.alto, ServicioImagenesFlutter.ladoMaximo ~/ 2);
  });

  test('tambien reduce cuando lo largo es el alto', () async {
    final origen = await _pngDePrueba(ancho: 1000, alto: 3000);

    final resultado = await ServicioImagenesFlutter.convertirAPng(origen);

    final tamano = await _tamanoDe(resultado.valorONulo!.bytes);
    expect(tamano.alto, ServicioImagenesFlutter.ladoMaximo);
    expect(tamano.ancho, lessThan(ServicioImagenesFlutter.ladoMaximo));
  });

  test('unos bytes que no son una imagen dan un error explicado', () async {
    final resultado = await ServicioImagenesFlutter.convertirAPng(
      Uint8List.fromList(const [1, 2, 3, 4, 5]),
    );

    expect(resultado.esFallo, isTrue);
    // El mensaje habla del HEIC porque es el caso real: una foto de iPhone que
    // el navegador no sabe decodificar llega exactamente por aqui.
    expect(resultado.errorONulo!.mensaje, contains('HEIC'));
  });

  test('el resultado es un PNG de verdad, no bytes sueltos', () async {
    final origen = await _pngDePrueba(ancho: 120, alto: 120);

    final resultado = await ServicioImagenesFlutter.convertirAPng(origen);
    final bytes = resultado.valorONulo!.bytes;

    // Firma PNG: 89 50 4E 47.
    expect(bytes.take(4).toList(), [0x89, 0x50, 0x4E, 0x47]);
    expect(resultado.valorONulo, isA<ImagenParaSubir>());
  });
}
