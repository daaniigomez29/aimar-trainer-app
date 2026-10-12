import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';

/// Los tres campos de texto de una serie, con su ciclo de vida.
///
/// Separado del widget que los pinta porque quien los crea es la pantalla: hay
/// que poder anadirlos, quitarlos y, sobre todo, **liberarlos** (`dispose`) sin
/// depender de que la fila este montada.
class CamposDeSerie {
  CamposDeSerie({
    required this.repeticiones,
    required this.peso,
    required this.rir,
  });

  /// Una serie en blanco, salvo las repeticiones, que arrancan en lo habitual.
  factory CamposDeSerie.nueva({int? repeticiones}) => CamposDeSerie(
    repeticiones: TextEditingController(
      text: (repeticiones ?? repeticionesPorDefecto).toString(),
    ),
    peso: TextEditingController(),
    rir: TextEditingController(),
  );

  factory CamposDeSerie.desde(DatosSerie datos) => CamposDeSerie(
    repeticiones: TextEditingController(text: datos.repeticiones.toString()),
    peso: TextEditingController(text: _comoTexto(datos.peso)),
    rir: TextEditingController(text: datos.rir?.toString() ?? ''),
  );

  /// Copia lo escrito en otra serie.
  ///
  /// Las series de un mismo ejercicio casi siempre repiten peso y repeticiones:
  /// 4x8 a 60 kg se teclea una vez, no cuatro. Y si hay que variar, corregir
  /// encima es menos trabajo que rellenar de cero.
  factory CamposDeSerie.comoLaAnterior(CamposDeSerie anterior) => CamposDeSerie(
    repeticiones: TextEditingController(text: anterior.repeticiones.text),
    peso: TextEditingController(text: anterior.peso.text),
    rir: TextEditingController(text: anterior.rir.text),
  );

  final TextEditingController repeticiones;
  final TextEditingController peso;
  final TextEditingController rir;

  void dispose() {
    repeticiones.dispose();
    peso.dispose();
    rir.dispose();
  }

  static String _comoTexto(double? peso) {
    if (peso == null) return '';
    return peso == peso.roundToDouble()
        ? peso.toStringAsFixed(0)
        : peso.toStringAsFixed(2);
  }
}

/// Una fila de la tabla de series del formulario: numero, peso, reps y RIR.
///
/// Los mensajes de error solo se pintan en la **primera** fila: la validacion es
/// de la serie, pero repetir el mismo texto en cada una llenaria la pantalla de
/// rojo diciendo tres veces lo mismo.
class FilaDeSerie extends StatelessWidget {
  const FilaDeSerie({
    required this.numero,
    required this.campos,
    required this.habilitado,
    required this.onCambio,
    required this.onQuitar,
    this.errorPeso,
    this.errorRepeticiones,
    this.errorRir,
    super.key,
  });

  /// Numero de serie, empezando en 1.
  final int numero;
  final CamposDeSerie campos;
  final bool habilitado;
  final VoidCallback onCambio;

  /// `null` deshabilita el boton de quitar: siempre debe quedar una serie.
  final VoidCallback? onQuitar;

  final String? errorPeso;
  final String? errorRepeticiones;
  final String? errorRir;

  bool get _esLaPrimera => numero == 1;

  @override
  Widget build(BuildContext context) {
    // Las claves van por indice desde 0, como estaban antes de extraer la fila.
    final indice = numero - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                '$numero',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          Expanded(
            child: _Campo(
              clave: Key('campo_peso_$indice'),
              controlador: campos.peso,
              etiqueta: 'Peso',
              decimal: true,
              habilitado: habilitado,
              onCambio: onCambio,
              error: _esLaPrimera ? errorPeso : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Campo(
              clave: Key('campo_reps_$indice'),
              controlador: campos.repeticiones,
              etiqueta: 'Reps *',
              habilitado: habilitado,
              onCambio: onCambio,
              error: _esLaPrimera ? errorRepeticiones : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Campo(
              clave: Key('campo_rir_$indice'),
              controlador: campos.rir,
              etiqueta: 'RIR',
              habilitado: habilitado,
              onCambio: onCambio,
              error: _esLaPrimera ? errorRir : null,
              ayuda: _esLaPrimera ? '0-10' : null,
            ),
          ),
          IconButton(
            key: Key('quitar_serie_$indice'),
            tooltip: 'Quitar serie',
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: habilitado ? onQuitar : null,
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.clave,
    required this.controlador,
    required this.etiqueta,
    required this.habilitado,
    required this.onCambio,
    this.decimal = false,
    this.error,
    this.ayuda,
  });

  final Key clave;
  final TextEditingController controlador;
  final String etiqueta;
  final bool habilitado;
  final VoidCallback onCambio;
  final bool decimal;
  final String? error;
  final String? ayuda;

  @override
  Widget build(BuildContext context) => TextField(
    key: clave,
    controller: controlador,
    enabled: habilitado,
    keyboardType: decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
    inputFormatters: [
      decimal
          ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          : FilteringTextInputFormatter.digitsOnly,
    ],
    onChanged: (_) => onCambio(),
    decoration: InputDecoration(
      labelText: etiqueta,
      isDense: true,
      helperText: ayuda,
      errorText: error,
    ),
  );
}
