import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo numerico con botones de menos y mas a los lados, como en las apps de
/// gimnasio: en medio de una serie no se teclea comodo, pero dar a "+" si.
///
/// El texto sigue siendo editable para el valor que no se alcanza a pasitos.
class CampoNumericoPasos extends StatelessWidget {
  const CampoNumericoPasos({
    required this.etiqueta,
    required this.controlador,
    required this.unidad,
    this.paso = 1,
    this.minimo = 0,
    this.maximo,
    this.decimales = false,
    this.mensajeError,
    this.onCambio,
    super.key,
  });

  final String etiqueta;
  final TextEditingController controlador;

  /// Se pinta pegada al campo: `kg`, `x`, `min`.
  final String unidad;
  final double paso;
  final double minimo;
  final double? maximo;

  /// `false` para repeticiones y RIR, que son enteros.
  final bool decimales;
  final String? mensajeError;
  final VoidCallback? onCambio;

  double? get _valor => double.tryParse(controlador.text.replaceAll(',', '.'));

  void _sumar(double delta) {
    final partida = _valor ?? minimo;
    var nuevo = partida + delta;
    if (nuevo < minimo) nuevo = minimo;
    final tope = maximo;
    if (tope != null && nuevo > tope) nuevo = tope;

    controlador.text = decimales
        ? _sinDecimalSobrante(nuevo)
        : '${nuevo.round()}';
    onCambio?.call();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 72, child: Text(etiqueta, style: textos.titleSmall)),
          Expanded(
            child: TextField(
              key: Key('campo_${etiqueta.toLowerCase()}'),
              controller: controlador,
              textAlign: TextAlign.center,
              style: textos.headlineSmall,
              keyboardType: TextInputType.numberWithOptions(decimal: decimales),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  decimales ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
                ),
              ],
              decoration: InputDecoration(
                suffixText: unidad,
                errorText: mensajeError,
                isDense: true,
              ),
              onChanged: (_) => onCambio?.call(),
            ),
          ),
          const SizedBox(width: 8),
          _Boton(
            etiqueta: 'Bajar $etiqueta',
            icono: Icons.remove,
            onPulsar: () => _sumar(-paso),
          ),
          const SizedBox(width: 8),
          _Boton(
            etiqueta: 'Subir $etiqueta',
            icono: Icons.add,
            onPulsar: () => _sumar(paso),
          ),
        ],
      ),
    );
  }

  static String _sinDecimalSobrante(double valor) =>
      valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.etiqueta,
    required this.icono,
    required this.onPulsar,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback onPulsar;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    key: Key('paso_${etiqueta.toLowerCase().replaceAll(' ', '_')}'),
    tooltip: etiqueta,
    icon: Icon(icono),
    onPressed: onPulsar,
  );
}
