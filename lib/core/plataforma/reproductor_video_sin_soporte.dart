import 'package:flutter/material.dart';

/// Sin navegador no hay iframe que montar: los tests corren en la VM de Dart y
/// la app movil de una fase futura usara otra cosa.
const bool reproductorSoportado = false;

Widget construirReproductor(Uri url, String aviso) => const SizedBox.shrink();

void permitirInteraccionConElVideo(Uri url) {}

void bloquearInteraccionConElVideo(Uri url) {}
