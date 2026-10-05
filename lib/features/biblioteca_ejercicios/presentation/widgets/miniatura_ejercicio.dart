import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';

/// La foto del ejercicio, o un hueco con el icono de su tipo si no la tiene.
///
/// Esta aqui, y no dentro de la tarjeta de la biblioteca, porque el mismo
/// ejercicio se pinta en cuatro sitios: el listado de la biblioteca, la
/// planificacion del entrenador, el panel desde el que los anade y la pantalla
/// de registro del cliente. Tenerlo repetido fue justo lo que hizo que en la
/// planificacion se quedara el hueco cuando se anadio la imagen a la entidad.
///
/// El bucket `imagenes-ejercicios` es publico a proposito, asi que la URL se
/// construye sin firmar y el navegador la cachea.
class MiniaturaEjercicio extends ConsumerWidget {
  const MiniaturaEjercicio({
    required this.ejercicio,
    this.lado = 40,
    this.radio = 8,
    this.iconoDeVideo = false,
    super.key,
  });

  /// Admite `null`: en la planificacion, un ejercicio planificado puede llegar
  /// sin su ficha si la consulta no la trajo.
  final Ejercicio? ejercicio;
  final double lado;
  final double radio;

  /// Superpone el triangulo de reproducir cuando el ejercicio tiene video. Solo
  /// lo pide el listado de la biblioteca; en una fila de 34 px no cabe.
  final bool iconoDeVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruta = ejercicio?.imagenRuta;
    final esFuerza = ejercicio?.tipo.esFuerza ?? true;
    final color = esFuerza ? Tokens.acento : Tokens.secundario;
    final tieneVideo = iconoDeVideo && ejercicio?.videoEjemploUrl != null;

    // Con el triangulo de video encima, el icono del tipo sobra: se pisarian.
    Widget hueco() => ColoredBox(
      color: color.withValues(alpha: 0.22),
      child: tieneVideo
          ? null
          : Center(
              child: Icon(
                esFuerza ? Icons.fitness_center : Icons.directions_run,
                size: lado * 0.42,
                color: color,
              ),
            ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        width: lado,
        height: lado,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ruta == null)
              hueco()
            else
              Image.network(
                ref.read(ejercicioRepositorioProvider).urlPublicaDeImagen(ruta),
                fit: BoxFit.cover,
                // Una imagen que no carga no debe dejar un roto: se cae al
                // mismo hueco que cuando no hay ninguna.
                errorBuilder: (_, _, _) => hueco(),
              ),
            if (tieneVideo)
              Center(
                child: Icon(
                  Icons.play_arrow,
                  color: ruta == null ? color : Colors.white,
                  size: lado * 0.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
