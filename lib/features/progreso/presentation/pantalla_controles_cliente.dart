import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/controles_del_cliente.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/fotos_progreso.dart';

/// Los controles que ha hecho un cliente, para que el entrenador los consulte.
///
/// Antes se abria el ultimo dia de control y para ver otro habia que buscarlo en
/// un calendario, sin saber que dias tenian algo. Aqui se ven directamente los
/// dias con control, separados **por meses** para que la lista no sea infinita.
class PantallaControlesCliente extends ConsumerStatefulWidget {
  const PantallaControlesCliente({required this.clienteId, super.key});

  final String clienteId;

  @override
  ConsumerState<PantallaControlesCliente> createState() =>
      _EstadoPantallaControlesCliente();
}

class _EstadoPantallaControlesCliente
    extends ConsumerState<PantallaControlesCliente> {
  /// Mes a la vista. `null` hasta que se toca: el del ultimo control.
  DateTime? _mes;

  @override
  Widget build(BuildContext context) {
    final controles = ref.watch(controlesDelClienteProvider(widget.clienteId));

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.clientes,
      appBar: AppBar(title: const Text('Control semanal')),
      cuerpo: controles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Mensaje(texto: mensajeDeErrorProgreso(error)),
        data: (lista) {
          if (lista.isEmpty) {
            return const _Mensaje(
              texto: 'Este cliente todavía no ha hecho ningún control.',
            );
          }

          // La lista viene de lo mas reciente a lo mas antiguo.
          final masReciente = mesDe(lista.first.fecha);
          final masAntiguo = mesDe(lista.last.fecha);
          final mes = _mes ?? masReciente;
          final delMes = controlesDelMes(lista, mes);

          return ListView(
            padding: const EdgeInsets.all(Tokens.margenPantalla),
            children: [
              _NavegadorDeMes(
                mes: mes,
                // Solo hasta donde hay controles: mas alla, todo seria vacio.
                onAnterior: mes.isAfter(masAntiguo)
                    ? () => setState(() => _mes = mesSumando(mes, -1))
                    : null,
                onSiguiente: mes.isBefore(masReciente)
                    ? () => setState(() => _mes = mesSumando(mes, 1))
                    : null,
              ),
              const SizedBox(height: 12),
              if (delMes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Ningún control este mes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                for (final control in delMes) ...[
                  _FilaControl(clienteId: widget.clienteId, control: control),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _NavegadorDeMes extends StatelessWidget {
  const _NavegadorDeMes({
    required this.mes,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final DateTime mes;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: const Key('mes_anterior'),
        tooltip: 'Mes anterior',
        icon: const Icon(Icons.chevron_left),
        onPressed: onAnterior,
      ),
      Expanded(
        child: Text(
          etiquetaDeMes(mes),
          key: const Key('mes_actual'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        key: const Key('mes_siguiente'),
        tooltip: 'Mes siguiente',
        icon: const Icon(Icons.chevron_right),
        onPressed: onSiguiente,
      ),
    ],
  );
}

class _FilaControl extends StatelessWidget {
  const _FilaControl({required this.clienteId, required this.control});

  final String clienteId;
  final ControlDelDia control;

  /// Lo que hay ese dia, de un vistazo. Dice ademas si falta una de las dos
  /// partes, porque son guardados independientes.
  String get _resumen {
    final medidas = control.medidas;
    final checkin = control.checkin;
    return [
      if (medidas != null) '${_numero(medidas.pesoKg)} kg' else 'Sin medidas',
      if (checkin != null)
        'Sueño ${_numero(checkin.horasSueno)} h · '
            'Estrés ${checkin.estres} · Agujetas ${checkin.agujetas} · '
            'Fatiga ${checkin.fatiga}'
      else
        'Sin check-in',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      key: Key('control_${_claveDeFecha(control.fecha)}'),
      onTap: () => context.go(
        Rutas.controlDeClienteEnDia(clienteId, _claveDeFecha(control.fecha)),
      ),
      hijo: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_diaConFecha(control.fecha), style: textos.titleSmall),
                const SizedBox(height: 2),
                Text(_resumen, style: textos.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Tokens.textoTenue),
        ],
      ),
    );
  }
}

/// Un control concreto, solo para consultar: medidas, fotos y check-in juntos.
///
/// Pantalla propia y no el formulario del cliente en solo lectura, que tenia
/// tres problemas para esto: el check-in estaba en un segundo paso al que solo
/// se llegaba guardando (el entrenador **nunca** llegaba a verlo), los campos
/// rellenos no decian que eran (la etiqueta es el `hint`, que desaparece con un
/// valor), y llevaba la barra de navegacion del cliente.
class PantallaDetalleControl extends ConsumerWidget {
  const PantallaDetalleControl({
    required this.clienteId,
    required this.fecha,
    super.key,
  });

  final String clienteId;
  final DateTime fecha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medidas = ref.watch(medidasDelDiaProvider(clienteId, fecha));
    final checkin = ref.watch(checkinDelDiaProvider(clienteId, fecha));

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.clientes,
      appBar: AppBar(title: Text(_diaConFecha(fecha))),
      cuerpo: switch ((medidas, checkin)) {
        (AsyncData(value: final m), AsyncData(value: final c)) =>
          m == null && c == null
              ? const _Mensaje(texto: 'Ese día no hay ningún control.')
              : ListView(
                  padding: const EdgeInsets.all(Tokens.margenPantalla),
                  children: [
                    _SeccionMedidas(clienteId: clienteId, registro: m),
                    const SizedBox(height: 14),
                    _SeccionCheckin(checkin: c),
                  ],
                ),
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
          _Mensaje(texto: mensajeDeErrorProgreso(error)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SeccionMedidas extends StatelessWidget {
  const _SeccionMedidas({required this.clienteId, required this.registro});

  final String clienteId;
  final RegistroMedidas? registro;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final actual = registro;

    return Tarjeta(
      key: const Key('detalle_medidas'),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medidas corporales', style: textos.titleMedium),
          const SizedBox(height: 10),
          if (actual == null)
            Text('Ese día no registró medidas.', style: textos.bodySmall)
          else ...[
            _Dato('Peso', '${_numero(actual.pesoKg)} kg'),
            for (final (etiqueta, valor) in [
              ('Pecho', actual.pechoCm),
              ('Cintura', actual.cinturaCm),
              ('Cadera', actual.caderaCm),
              ('Cuádriceps', actual.cuadricepsCm),
              ('Brazos', actual.brazosCm),
            ])
              // Los perimetros son opcionales: sin valor no hay fila.
              if (valor != null) _Dato(etiqueta, '${_numero(valor)} cm'),
            const SizedBox(height: 12),
            FotosProgreso(
              clienteId: clienteId,
              registro: actual,
              soloLectura: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SeccionCheckin extends StatelessWidget {
  const _SeccionCheckin({required this.checkin});

  final CheckinRecuperacion? checkin;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final actual = checkin;
    final notas = actual?.notas?.trim() ?? '';

    return Tarjeta(
      key: const Key('detalle_checkin'),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check-in de recuperación', style: textos.titleMedium),
          const SizedBox(height: 10),
          if (actual == null)
            Text('Ese día no hizo el check-in.', style: textos.bodySmall)
          else ...[
            _Dato('Horas de sueño', '${_numero(actual.horasSueno)} h'),
            _Dato('Estrés', '${actual.estres} / 10'),
            _Dato('Agujetas', '${actual.agujetas} / 10'),
            _Dato('Fatiga', '${actual.fatiga} / 10'),
            if (notas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Notas', style: textos.labelLarge),
              const SizedBox(height: 4),
              Text(notas, style: textos.bodyMedium),
            ],
          ],
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: textos.bodyMedium)),
          Text(valor, style: textos.titleSmall),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _dosCifras(int valor) => valor.toString().padLeft(2, '0');

/// `2026-10-19`: la fecha en la URL y en las claves.
String _claveDeFecha(DateTime fecha) =>
    '${fecha.year}-${_dosCifras(fecha.month)}-${_dosCifras(fecha.day)}';

/// "Domingo 19/10/2026".
String _diaConFecha(DateTime fecha) =>
    '${DiaSemana.values[fecha.weekday - 1].etiqueta} '
    '${_dosCifras(fecha.day)}/${_dosCifras(fecha.month)}/${fecha.year}';
