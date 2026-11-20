import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Entrega un PDF ya generado al usuario.
abstract interface class DescargadorPdf {
  Future<void> descargar(Uint8List bytes, {required String nombreArchivo});
}

/// Con `printing`: en la web lo descarga el navegador; en movil abre la hoja
/// de compartir del sistema.
class DescargadorPdfPrinting implements DescargadorPdf {
  const DescargadorPdfPrinting();

  @override
  Future<void> descargar(Uint8List bytes, {required String nombreArchivo}) =>
      Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
}
