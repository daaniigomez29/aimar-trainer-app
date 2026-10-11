import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

/// Color e icono de cada tipo de ejercicio, en un solo sitio.
///
/// Estaban repetidos como ternarios en la miniatura, la tarjeta y el
/// formulario, y los tres daban por hecho que solo habia dos tipos. Es el mismo
/// motivo por el que la foto se unifico en `MiniaturaEjercicio`: una copia por
/// pantalla significa que la siguiente que se anada se olvida en dos de ellas.
///
/// Vive en `presentation` y no en el enum de dominio a proposito: el dominio no
/// depende de Flutter.
extension EstiloTipoEjercicio on TipoEjercicio {
  Color get color => switch (this) {
    TipoEjercicio.fuerza => Tokens.acento,
    TipoEjercicio.cardio => Tokens.secundario,
    TipoEjercicio.fortalecimiento => Tokens.terciario,
  };

  IconData get icono => switch (this) {
    TipoEjercicio.fuerza => Icons.fitness_center,
    TipoEjercicio.cardio => Icons.directions_run,
    TipoEjercicio.fortalecimiento => Icons.healing,
  };
}
