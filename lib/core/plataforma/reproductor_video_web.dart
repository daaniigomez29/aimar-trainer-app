import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const bool reproductorSoportado = true;

// Factory definido en `web/index.html`: devuelve el `<iframe>` ya configurado.
// Crear el elemento alli y no aqui ahorra tener que describir toda la API del DOM
// con interop para poner cuatro atributos.
@JS('aimarVideo.crearIframe')
external JSObject _crearIframe(String url);

/// Las vistas de plataforma se registran una vez por tipo y el registro no se
/// puede deshacer: si se intenta repetir, el motor lanza. Como el tipo lleva la
/// URL dentro, cada video se registra una sola vez aunque su ficha se abra
/// muchas veces.
final Set<String> _registrados = <String>{};

Widget construirReproductor(Uri url) {
  final tipo = 'video-ejemplo-${url.hashCode}';
  if (_registrados.add(tipo)) {
    ui_web.platformViewRegistry.registerViewFactory(
      tipo,
      (int id) => _crearIframe(url.toString()),
    );
  }
  return HtmlElementView(viewType: tipo);
}
