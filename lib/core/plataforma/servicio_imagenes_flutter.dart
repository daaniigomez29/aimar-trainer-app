import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';

part 'servicio_imagenes_flutter.g.dart';

@Riverpod(keepAlive: true)
ServicioImagenes servicioImagenes(Ref ref) => ServicioImagenesFlutter();

/// Implementacion con `image_picker` para elegir y `dart:ui` para convertir.
///
/// POR QUE SE RECODIFICA SIEMPRE, no solo cuando el fichero es HEIC: un iPhone
/// entrega HEIC (o HEIF), que el bucket no admite y que ni siquiera todos los
/// navegadores saben decodificar. Al pasar siempre por decodificar y volver a
/// codificar en PNG, lo que sale es PNG venga lo que venga, sin tener que fiarse
/// de la extension ni del tipo MIME que declare el navegador.
///
/// El limite esta en la decodificacion: si el navegador no sabe leer el formato de
/// origen (Chrome de escritorio con un HEIC, por ejemplo), no hay conversion
/// posible desde aqui y se devuelve un error que lo explica. Safari e iOS si lo
/// decodifican, que es donde aparece el HEIC de verdad. Ademas, al subir desde
/// Safari por un `input` de archivo, iOS suele entregar ya un JPEG convertido.
class ServicioImagenesFlutter implements ServicioImagenes {
  ServicioImagenesFlutter({ImagePicker? selector})
    : _selector = selector ?? ImagePicker();

  /// Lado maximo de la imagen guardada. Una foto de progreso no necesita mas
  /// resolucion que esta, y asi el PNG no se dispara de tamano: el bucket corta
  /// en 20 MiB, y un PNG sin reducir de una camara moderna se acerca peligrosamente.
  static const int ladoMaximo = 1600;

  final ImagePicker _selector;

  @override
  Future<Result<ImagenParaSubir?>> elegirFoto() async {
    try {
      final elegida = await _selector.pickImage(source: ImageSource.gallery);
      // Cancelar el selector no es un error: no hay nada que subir y ya esta.
      if (elegida == null) return const Success(null);

      final origen = await elegida.readAsBytes();
      return await convertirAPng(origen);
    } on Object catch (error, traza) {
      return Failure(
        Registro.inesperado(error, traza, contexto: 'el selector de imagenes'),
      );
    }
  }

  /// Decodifica, reduce si hace falta y vuelve a codificar en PNG.
  ///
  /// Publica para poder probarla sin selector de archivos.
  static Future<Result<ImagenParaSubir?>> convertirAPng(
    Uint8List origen,
  ) async {
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? imagen;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(origen);
      descriptor = await ui.ImageDescriptor.encoded(buffer);

      final ladoMayor = math.max(descriptor.width, descriptor.height);
      final escala = ladoMayor > ladoMaximo ? ladoMaximo / ladoMayor : 1.0;
      codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * escala).round(),
        targetHeight: (descriptor.height * escala).round(),
      );

      final fotograma = await codec.getNextFrame();
      imagen = fotograma.image;
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (datos == null) {
        return const Failure(
          ErrorValidacion('No se ha podido preparar la imagen para subirla.'),
        );
      }

      return Success(
        ImagenParaSubir(
          bytes: datos.buffer.asUint8List(),
          extension: 'png',
          tipoMime: 'image/png',
        ),
      );
    } on Object catch (error, traza) {
      Registro.fallo(error, traza, contexto: 'la conversion de la imagen');
      return const Failure(
        ErrorValidacion(
          'No se ha podido leer esa imagen. Si es una foto de iPhone en '
          'formato HEIC, abrela y guardala como JPEG, o subela desde el '
          'propio iPhone.',
          campo: 'foto',
        ),
      );
    } finally {
      imagen?.dispose();
      codec?.dispose();
      descriptor?.dispose();
    }
  }
}
