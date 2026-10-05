import 'dart:typed_data';

import 'package:aimar_trainer_app/core/errores/result.dart';

/// Una imagen ya lista para subir al bucket: convertida, redimensionada y con su
/// tipo MIME resuelto.
class ImagenParaSubir {
  const ImagenParaSubir({
    required this.bytes,
    required this.extension,
    required this.tipoMime,
  });

  final Uint8List bytes;

  /// Sin punto: `png`, `jpg`. La ruta del objeto se construye con ella.
  final String extension;

  /// `image/png` o `image/jpeg`: son los unicos que admite el bucket.
  final String tipoMime;

  int get tamanoKb => (bytes.lengthInBytes / 1024).round();
}

/// Elegir una foto del dispositivo y dejarla en un formato que el bucket acepte.
///
/// Es una interfaz de plataforma (RNF-03) por dos motivos: el selector de archivos
/// no existe en Dart puro, y porque un iPhone entrega **HEIC**, que el bucket no
/// admite. La conversion forma parte del contrato, no es cosa de la pantalla: quien
/// llame a [elegirFoto] recibe siempre algo subible o un error explicado.
abstract interface class ServicioImagenes {
  /// `null` dentro de un `Success` significa que el usuario cancelo el selector,
  /// que no es un error.
  Future<Result<ImagenParaSubir?>> elegirFoto();
}
