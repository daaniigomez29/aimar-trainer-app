import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';

/// Grafica de linea de una metrica a lo largo del tiempo (CU-21).
///
/// Pintada a mano con `CustomPainter` en lugar de con una libreria de graficas:
/// aqui solo hace falta una linea con sus puntos, y no compensa meter una
/// dependencia nueva en el proyecto por eso.
class GraficaProgreso extends StatelessWidget {
  const GraficaProgreso({
    required this.puntos,
    required this.unidad,
    super.key,
  });

  final List<PuntoProgreso> puntos;
  final String unidad;

  static const double alto = 220;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    if (puntos.isEmpty) {
      return SizedBox(
        height: alto,
        child: Center(
          child: Text(
            'No hay datos en ese rango de fechas.',
            style: textos.bodyMedium,
          ),
        ),
      );
    }

    // Un solo punto no dibuja una linea, pero el dato sigue siendo util.
    if (puntos.length == 1) {
      return SizedBox(
        height: alto,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_numero(puntos.first.valor)} $unidad',
                style: textos.headlineMedium,
              ),
              Text(_comoFecha(puntos.first.fecha), style: textos.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Con un solo registro todavia no hay evolucion que dibujar.',
                style: textos.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: alto,
      child: LayoutBuilder(
        builder: (context, restricciones) => CustomPaint(
          size: Size(restricciones.maxWidth, alto),
          painter: _PintorGrafica(
            puntos: puntos,
            unidad: unidad,
            colorLinea: esquema.primary,
            colorEje: esquema.outlineVariant,
            colorTexto: esquema.onSurfaceVariant,
            estiloTexto: textos.labelSmall ?? const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _PintorGrafica extends CustomPainter {
  _PintorGrafica({
    required this.puntos,
    required this.unidad,
    required this.colorLinea,
    required this.colorEje,
    required this.colorTexto,
    required this.estiloTexto,
  });

  final List<PuntoProgreso> puntos;
  final String unidad;
  final Color colorLinea;
  final Color colorEje;
  final Color colorTexto;
  final TextStyle estiloTexto;

  /// Hueco para las etiquetas: a la izquierda los valores, abajo las fechas.
  static const double margenIzquierdo = 48;
  static const double margenInferior = 24;
  static const double margenSuperior = 12;
  static const double margenDerecho = 8;

  @override
  void paint(Canvas lienzo, Size tamano) {
    final valores = puntos.map((p) => p.valor).toList();
    var minimo = valores.reduce((a, b) => a < b ? a : b);
    var maximo = valores.reduce((a, b) => a > b ? a : b);
    // Si todos los valores son iguales la escala seria de altura cero: se abre un
    // poco para que la linea quede centrada en vez de pegada a un borde.
    if (minimo == maximo) {
      minimo = minimo - 1;
      maximo = maximo + 1;
    }

    final izquierda = margenIzquierdo;
    final derecha = tamano.width - margenDerecho;
    final arriba = margenSuperior;
    final abajo = tamano.height - margenInferior;

    final ejes = Paint()
      ..color = colorEje
      ..strokeWidth = 1;
    lienzo
      ..drawLine(Offset(izquierda, abajo), Offset(derecha, abajo), ejes)
      ..drawLine(Offset(izquierda, arriba), Offset(izquierda, abajo), ejes);

    double x(int indice) =>
        izquierda +
        (derecha - izquierda) *
            (indice / (puntos.length - 1).clamp(1, 1 << 30));
    double y(double valor) =>
        abajo - (abajo - arriba) * ((valor - minimo) / (maximo - minimo));

    // Linea entre puntos consecutivos.
    final trazo = Paint()
      ..color = colorLinea
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final camino = Path()..moveTo(x(0), y(puntos.first.valor));
    for (var i = 1; i < puntos.length; i++) {
      camino.lineTo(x(i), y(puntos[i].valor));
    }
    lienzo.drawPath(camino, trazo);

    final relleno = Paint()..color = colorLinea;
    for (var i = 0; i < puntos.length; i++) {
      lienzo.drawCircle(Offset(x(i), y(puntos[i].valor)), 3.5, relleno);
    }

    _texto(lienzo, '${_numero(maximo)} $unidad', Offset(0, arriba - 4));
    _texto(lienzo, '${_numero(minimo)} $unidad', Offset(0, abajo - 8));
    _texto(
      lienzo,
      _comoFecha(puntos.first.fecha),
      Offset(izquierda, abajo + 6),
    );
    _texto(
      lienzo,
      _comoFecha(puntos.last.fecha),
      Offset(derecha - 44, abajo + 6),
    );
  }

  void _texto(Canvas lienzo, String contenido, Offset donde) {
    final pintor = TextPainter(
      text: TextSpan(
        text: contenido,
        style: estiloTexto.copyWith(color: colorTexto),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pintor.paint(lienzo, donde);
  }

  @override
  bool shouldRepaint(_PintorGrafica anterior) =>
      anterior.puntos != puntos ||
      anterior.unidad != unidad ||
      anterior.colorLinea != colorLinea;
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
