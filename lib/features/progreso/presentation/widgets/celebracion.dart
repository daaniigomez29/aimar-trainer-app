import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Piezas de la celebracion de fin de sesion, **dibujadas a mano** con
/// `CustomPainter` y no con una animacion de diseñador (Lottie): pesan cero,
/// van en los colores de la app y las mueve un solo controlador, asi que un
/// toque lo salta todo a la vez.

/// Un check que se dibuja: primero el circulo, despues el trazo.
class CheckDibujado extends StatelessWidget {
  const CheckDibujado({
    required this.progreso,
    this.lado = 96,
    this.color = Tokens.exito,
    super.key,
  });

  /// De 0 a 1.
  final Animation<double> progreso;
  final double lado;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: lado,
    child: CustomPaint(
      painter: _PintorCheck(progreso: progreso, color: color),
    ),
  );
}

class _PintorCheck extends CustomPainter {
  _PintorCheck({required this.progreso, required this.color})
    : super(repaint: progreso);

  final Animation<double> progreso;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progreso.value;
    final centro = size.center(Offset.zero);
    final radio = size.shortestSide / 2 - 4;

    // Fondo que crece con un pequeño rebote.
    final escala = Curves.easeOutBack.transform((t / 0.5).clamp(0, 1));
    canvas.drawCircle(
      centro,
      radio * escala,
      Paint()..color = color.withValues(alpha: 0.15),
    );

    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arco = (t / 0.6).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -pi / 2,
      2 * pi * arco,
      false,
      trazo,
    );

    final marca = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    if (marca == 0) return;
    final check = Path()
      ..moveTo(size.width * 0.29, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.37);
    for (final metrica in check.computeMetrics()) {
      canvas.drawPath(
        metrica.extractPath(
          0,
          metrica.length * Curves.easeOut.transform(marca),
        ),
        trazo,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorCheck viejo) =>
      viejo.progreso != progreso || viejo.color != color;
}

/// Una rafaga de confeti que sale hacia arriba y cae. Se pinta una vez de
/// principio a fin: al acabar ya no queda nada en pantalla.
class Confeti extends StatelessWidget {
  const Confeti({required this.progreso, super.key});

  /// De 0 a 1: 0 antes de salir, 1 cuando ya ha caido todo.
  final Animation<double> progreso;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(size: Size.infinite, painter: _PintorConfeti(progreso)),
  );
}

class _Particula {
  _Particula(Random azar)
    : angulo = -pi / 2 + (azar.nextDouble() - 0.5) * pi * 0.9,
      velocidad = 0.55 + azar.nextDouble() * 0.55,
      giro = (azar.nextDouble() - 0.5) * 14,
      ancho = 5 + azar.nextDouble() * 4,
      alto = 8 + azar.nextDouble() * 6,
      color = _colores[azar.nextInt(_colores.length)];

  static const _colores = [
    Tokens.acento,
    Tokens.exito,
    Tokens.secundario,
    Tokens.terciario,
    Tokens.texto,
  ];

  final double angulo;
  final double velocidad;
  final double giro;
  final double ancho;
  final double alto;
  final Color color;
}

class _PintorConfeti extends CustomPainter {
  _PintorConfeti(this.progreso) : super(repaint: progreso);

  final Animation<double> progreso;

  /// Semilla fija: la misma rafaga siempre, y los tests ven lo mismo.
  static final List<_Particula> _particulas = () {
    final azar = Random(29);
    return [for (var i = 0; i < 80; i++) _Particula(azar)];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = progreso.value;
    if (t <= 0 || t >= 1) return;

    final origen = Offset(size.width / 2, size.height * 0.28);
    final escala = size.shortestSide;
    // Se desvanece en el ultimo tercio.
    final opacidad = t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35);
    const gravedad = 2.4;

    for (final p in _particulas) {
      final dx = cos(p.angulo) * p.velocidad * t * escala;
      final dy =
          (sin(p.angulo) * p.velocidad * t + 0.5 * gravedad * t * t) * escala;
      canvas
        ..save()
        ..translate(origen.dx + dx, origen.dy + dy)
        ..rotate(p.giro * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.ancho, height: p.alto),
        Paint()..color = p.color.withValues(alpha: opacidad),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorConfeti viejo) => viejo.progreso != progreso;
}

/// Una cifra que sube contando desde 0 hasta su valor.
class CifraQueSube extends StatelessWidget {
  const CifraQueSube({
    required this.progreso,
    required this.valor,
    required this.formato,
    this.estilo,
    super.key,
  });

  final Animation<double> progreso;
  final double valor;
  final String Function(double) formato;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progreso,
    // Lo que se lee al final tiene que ser exacto, no la ultima cifra que
    // dio tiempo a pintar.
    builder: (context, _) => Text(
      formato(
        progreso.value >= 1 ? valor : lerpDouble(0, valor, progreso.value)!,
      ),
      style: estilo,
    ),
  );
}
