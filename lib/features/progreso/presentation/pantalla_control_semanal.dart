import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/formulario_checkin.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/formulario_medidas.dart';

/// Control semanal: medidas corporales y check-in de recuperacion.
///
/// Se muestran juntos porque se rellenan el mismo dia —el `diaControlPreferido`
/// del cliente—, pero son **dos formularios y dos guardados independientes**: cada
/// uno tiene su boton y su resultado. No hay transaccion que los una, por decision
/// del modelo de dominio; rellenar solo uno es valido.
///
/// El entrenador entra en modo consulta: puede ver lo de su cliente (RLS se lo
/// permite) pero no escribir en su nombre. El administrador no llega aqui, y si lo
/// intentara no veria nada: no tiene politica en ninguna de estas tablas.
class PantallaControlSemanal extends ConsumerStatefulWidget {
  const PantallaControlSemanal({
    required this.clienteId,
    this.soloLectura = false,
    super.key,
  });

  final String clienteId;
  final bool soloLectura;

  @override
  ConsumerState<PantallaControlSemanal> createState() =>
      _PantallaControlSemanalState();
}

class _PantallaControlSemanalState
    extends ConsumerState<PantallaControlSemanal> {
  /// `null` hasta que se sabe el dia de control del cliente; a partir de ahi, la
  /// fecha que se esta editando.
  DateTime? _fecha;

  Future<void> _elegirFecha(DateTime actual) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(actual.year - 2),
      lastDate: DateTime.now(),
      helpText: 'Dia del control',
    );
    if (elegida != null && mounted) {
      setState(
        () => _fecha = DateTime(elegida.year, elegida.month, elegida.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = ref.watch(clientePorIdProvider(widget.clienteId));
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.soloLectura ? 'Control del cliente' : 'Mi control'),
      ),
      body: cliente.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              mensajeDeErrorProgreso(error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (ficha) {
          // Por defecto, el ultimo dia de control que ha pasado: es el que el
          // cliente viene a rellenar. Puede cambiarlo si se le olvido un dia.
          final fecha = _fecha ?? ficha.diaControlPreferido.ultimaFecha();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_comoFecha(fecha), style: textos.titleLarge),
                        Text(
                          'Dia de control: '
                          '${ficha.diaControlPreferido.etiqueta}',
                          style: textos.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('boton_cambiar_fecha_control'),
                    onPressed: () => _elegirFecha(fecha),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Cambiar dia'),
                  ),
                ],
              ),
              const Divider(height: 24),
              FormularioMedidas(
                clienteId: widget.clienteId,
                fecha: fecha,
                soloLectura: widget.soloLectura,
              ),
              const Divider(height: 32),
              FormularioCheckin(
                clienteId: widget.clienteId,
                fecha: fecha,
                soloLectura: widget.soloLectura,
              ),
              const Divider(height: 32),
              _Historial(clienteId: widget.clienteId),
            ],
          );
        },
      ),
    );
  }
}

/// Las ultimas semanas, para ver de un vistazo si se esta siendo constante.
class _Historial extends ConsumerWidget {
  const _Historial({required this.clienteId});

  final String clienteId;

  static const int cuantos = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final medidas = ref.watch(historialMedidasProvider(clienteId)).value;
    final checkins = ref.watch(historialCheckinsProvider(clienteId)).value;

    if ((medidas == null || medidas.isEmpty) &&
        (checkins == null || checkins.isEmpty)) {
      return Text(
        'Todavia no hay controles registrados.',
        style: textos.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ultimos controles', style: textos.titleSmall),
        const SizedBox(height: 8),
        for (final registro in (medidas ?? const <RegistroMedidas>[]).take(
          cuantos,
        ))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.straighten, size: 20),
            title: Text(
              '${_comoFecha(registro.fecha)} - ${_numero(registro.pesoKg)} kg',
            ),
            subtitle: registro.fotos.isEmpty
                ? null
                : Text(
                    '${registro.fotos.length} '
                    '${registro.fotos.length == 1 ? "foto" : "fotos"}',
                  ),
          ),
        for (final checkin in (checkins ?? const <CheckinRecuperacion>[]).take(
          cuantos,
        ))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.self_improvement, size: 20),
            title: Text(
              '${_comoFecha(checkin.fecha)} - '
              '${_numero(checkin.horasSueno)} h de sueno',
            ),
            subtitle: Text(
              'Estres ${checkin.estres} · Agujetas ${checkin.agujetas} · '
              'Fatiga ${checkin.fatiga}',
            ),
          ),
      ],
    );
  }
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
