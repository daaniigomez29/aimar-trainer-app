import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const bool reproductorSoportado = true;

// Factory definido en `web/index.html`: devuelve el `<iframe>` ya configurado.
// Crear el elemento alli y no aqui ahorra tener que describir toda la API del DOM
// con interop para poner cuatro atributos.
@JS('aimarVideo.crearIframe')
external JSObject _crearIframe(String url, String aviso);

@JS('aimarVideo.permitirInteraccion')
external void _permitirInteraccion(JSObject marco);

@JS('aimarVideo.bloquearInteraccion')
external void _bloquearInteraccion(JSObject marco);

/// Las vistas de plataforma se registran una vez por tipo y el registro no se
/// puede deshacer: si se intenta repetir, el motor lanza. Como el tipo lleva la
/// URL dentro, cada video se registra una sola vez aunque su ficha se abra
/// muchas veces.
final Set<String> _registrados = <String>{};

/// El ultimo iframe creado de cada video, para poder activarlo luego.
final Map<String, JSObject> _marcos = <String, JSObject>{};

String _tipoDe(Uri url) => 'video-ejemplo-${url.hashCode}';

Widget construirReproductor(Uri url, String aviso) {
  final tipo = _tipoDe(url);
  if (_registrados.add(tipo)) {
    ui_web.platformViewRegistry.registerViewFactory(tipo, (int id) {
      final marco = _crearIframe(url.toString(), aviso);
      _marcos[tipo] = marco;
      return marco;
    });
  }
  return HtmlElementView(viewType: tipo);
}

/// Deja que el video reciba clics. Hasta que se llama, el iframe es inerte y
/// todo lo que pase por encima —rueda y dedo— le llega a Flutter, que es quien
/// desplaza la pantalla.
void permitirInteraccionConElVideo(Uri url) {
  final marco = _marcos[_tipoDe(url)];
  if (marco != null) _permitirInteraccion(marco);
}

/// Lo devuelve a inerte. Hace falta porque el iframe sobrevive a la pantalla:
/// la vista de plataforma se registra una vez y se reutiliza, asi que sin esto
/// una ficha abierta por segunda vez apareceria con el video ya activo.
void bloquearInteraccionConElVideo(Uri url) {
  final marco = _marcos[_tipoDe(url)];
  if (marco != null) _bloquearInteraccion(marco);
}
