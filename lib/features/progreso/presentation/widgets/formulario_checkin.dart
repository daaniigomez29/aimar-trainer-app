import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

/// Check-in semanal de recuperacion: como ha ido la semana al margen del
/// entrenamiento.
///
/// Guarda por su cuenta, igual que el formulario de medidas: comparten pantalla y
/// fecha, no transaccion.
class FormularioCheckin extends ConsumerStatefulWidget {
  const FormularioCheckin({
    required this.clienteId,
    required this.fecha,
    required this.soloLectura,
    super.key,
  });

  final String clienteId;
  final DateTime fecha;
  final bool soloLectura;

  @override
  ConsumerState<FormularioCheckin> createState() => _FormularioCheckinState();
}

class _FormularioCheckinState extends ConsumerState<FormularioCheckin> {
  final _horasSueno = TextEditingController();
  final _notas = TextEditingController();

  /// Valor de partida de las tres escalas: el punto medio, para no sugerir que lo
  /// normal sea estar fatal ni perfecto.
  static const int valorNeutro = 5;

  int _estres = valorNeutro;
  int _agujetas = valorNeutro;
  int _fatiga = valorNeutro;

  String? _idCargado;
  DateTime? _fechaCargada;

  @override
  void dispose() {
    _horasSueno.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _volcar(CheckinRecuperacion? checkin) {
    _idCargado = checkin?.id;
    _fechaCargada = widget.fecha;
    _horasSueno.text = checkin == null ? '' : _numero(checkin.horasSueno);
    _notas.text = checkin?.notas ?? '';
    _estres = checkin?.estres ?? valorNeutro;
    _agujetas = checkin?.agujetas ?? valorNeutro;
    _fatiga = checkin?.fatiga ?? valorNeutro;
  }

  Future<void> _guardar() async {
    final datos = DatosCheckin(
      clienteId: widget.clienteId,
      fecha: widget.fecha,
      horasSueno: double.tryParse(_horasSueno.text.trim().replaceAll(',', '.')),
      estres: _estres,
      agujetas: _agujetas,
      fatiga: _fatiga,
      notas: _notas.text,
    );

    final resultado = await ref
        .read(controladorControlSemanalProvider.notifier)
        .guardarCheckin(datos);
    if (!mounted || resultado.esFallo) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Check-in guardado.')));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = ref.watch(controladorControlSemanalProvider);
    final checkin = ref
        .watch(checkinDelDiaProvider(widget.clienteId, widget.fecha))
        .value;

    if (_fechaCargada != widget.fecha || _idCargado != checkin?.id) {
      _volcar(checkin);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.self_improvement),
            const SizedBox(width: 8),
            Text('Check-in de recuperacion', style: textos.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('campo_horas_sueno'),
          controller: _horasSueno,
          enabled: !widget.soloLectura,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Horas de sueno (media de la semana)',
            suffixText: 'h',
            errorText: estado.errorDelCampo('horasSueno'),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        _Escala(
          etiqueta: 'Estres',
          valor: _estres,
          habilitada: !widget.soloLectura,
          onCambio: (valor) => setState(() => _estres = valor),
        ),
        _Escala(
          etiqueta: 'Agujetas',
          valor: _agujetas,
          habilitada: !widget.soloLectura,
          onCambio: (valor) => setState(() => _agujetas = valor),
        ),
        _Escala(
          etiqueta: 'Fatiga',
          valor: _fatiga,
          habilitada: !widget.soloLectura,
          onCambio: (valor) => setState(() => _fatiga = valor),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('campo_notas_checkin'),
          controller: _notas,
          enabled: !widget.soloLectura,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            hintText: 'Lesiones, viajes, cambios de rutina...',
            isDense: true,
          ),
        ),
        if (!widget.soloLectura) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const Key('boton_guardar_checkin'),
              onPressed: estado.enCurso ? null : _guardar,
              child: const Text('Guardar check-in'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Escala de 1 a 10. No empieza en 0 a proposito: aqui el 1 ya es "nada", al
/// contrario que en el RIR, donde el 0 significa fallo muscular.
class _Escala extends StatelessWidget {
  const _Escala({
    required this.etiqueta,
    required this.valor,
    required this.habilitada,
    required this.onCambio,
  });

  final String etiqueta;
  final int valor;
  final bool habilitada;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(etiqueta, style: textos.bodyMedium)),
          Expanded(
            child: Slider(
              key: Key('escala_${etiqueta.toLowerCase()}'),
              value: valor.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$valor',
              onChanged: habilitada ? (nuevo) => onCambio(nuevo.round()) : null,
            ),
          ),
          SizedBox(width: 28, child: Text('$valor', style: textos.titleMedium)),
        ],
      ),
    );
  }
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);
