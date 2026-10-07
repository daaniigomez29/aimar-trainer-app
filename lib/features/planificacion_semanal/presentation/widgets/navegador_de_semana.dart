import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';

/// Flechas para moverse de semana en semana, con la etiqueta como botón que
/// abre el calendario.
///
/// POR QUE ES COMPARTIDO: lo usan el entrenador, que planifica, y el cliente,
/// que mira. Son dos pantallas muy distintas, pero "ir a una semana" es la misma
/// operación y no tiene por qué comportarse diferente en cada una.
class NavegadorDeSemana extends StatelessWidget {
  const NavegadorDeSemana({
    required this.semana,
    required this.onCambio,
    this.estilo,
    super.key,
  });

  final Semana semana;
  final ValueChanged<Semana> onCambio;

  /// Para que cada pantalla la escriba con su tipografía.
  final TextStyle? estilo;

  /// Abre el calendario y se queda con **la semana** del día que se elija.
  ///
  /// El calendario de Material elige días, no semanas, pero aquí da igual cuál
  /// se toque: lo que se elige es la semana que lo contiene. Así se salta a una
  /// semana lejana sin pulsar la flecha veinte veces.
  Future<void> _elegirEnElCalendario(BuildContext context) async {
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: semana.lunes,
      firstDate: DateTime(hoy.year - 2),
      lastDate: DateTime(hoy.year + 2),
      helpText: 'Ir a una semana',
      cancelText: 'Cancelar',
      confirmText: 'Ir',
    );
    if (elegido != null) onCambio(Semana.de(elegido));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('semana_anterior'),
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onCambio(semana.anterior),
        ),
        Flexible(
          child: TextButton(
            key: const Key('abrir_calendario_semana'),
            onPressed: () => _elegirEnElCalendario(context),
            child: Text(
              'Semana del ${semana.etiqueta}',
              style: estilo ?? Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          key: const Key('semana_siguiente'),
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onCambio(semana.siguiente),
        ),
      ],
    );
  }
}
