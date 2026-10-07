import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/grafica_progreso.dart';

/// Consulta de progreso (CU-21).
///
/// La misma pantalla para el cliente (lo suyo) y para el entrenador (lo de un
/// cliente concreto): cambia el `clienteId` y poco mas, porque quien puede ver que
/// lo decide RLS y no esta pantalla.
class PantallaProgreso extends ConsumerStatefulWidget {
  const PantallaProgreso({required this.clienteId, this.titulo, super.key});

  final String clienteId;

  /// Nombre del cliente cuando lo mira el entrenador; `null` si es el propio
  /// cliente mirando lo suyo.
  final String? titulo;

  @override
  ConsumerState<PantallaProgreso> createState() => _PantallaProgresoState();
}

/// De donde salen los datos de la grafica.
enum _Origen {
  ejercicio,
  cuerpo;

  String get etiqueta => switch (this) {
    _Origen.ejercicio => 'Ejercicio',
    _Origen.cuerpo => 'Medidas corporales',
  };
}

class _PantallaProgresoState extends ConsumerState<PantallaProgreso> {
  _Origen _origen = _Origen.ejercicio;
  String? _ejercicioId;
  MetricaEjercicio? _metricaEjercicio;
  MetricaCorporal _metricaCorporal = MetricaCorporal.pesoKg;

  /// Tres meses por defecto: suficiente para ver una tendencia sin traerse todo
  /// el historico.
  RangoFechas _rango = RangoFechas.ultimosMeses(3);

  Future<void> _elegirRango() async {
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _rango.desde, end: _rango.hasta),
      helpText: 'Rango de fechas',
    );
    if (elegido != null && mounted) {
      setState(
        () => _rango = RangoFechas(desde: elegido.start, hasta: elegido.end),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = ref.watch(
      ejerciciosConRegistroProvider(widget.clienteId),
    );

    final barra = AppBar(
      title: Text(widget.titulo == null ? 'Mi progreso' : 'Progreso'),
      bottom: widget.titulo == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.titulo!),
              ),
            ),
    );

    final cuerpo = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<_Origen>(
          segments: [
            for (final origen in _Origen.values)
              ButtonSegment(value: origen, label: Text(origen.etiqueta)),
          ],
          selected: {_origen},
          onSelectionChanged: (seleccion) =>
              setState(() => _origen = seleccion.first),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('boton_rango_fechas'),
          onPressed: _elegirRango,
          icon: const Icon(Icons.date_range, size: 18),
          label: Text(
            'Del ${_comoFecha(_rango.desde)} al ${_comoFecha(_rango.hasta)}',
          ),
        ),
        const SizedBox(height: 12),
        if (_origen == _Origen.ejercicio)
          ...ejercicios.when(
            loading: () => const [Center(child: CircularProgressIndicator())],
            error: (error, _) => [
              Text(mensajeDeErrorProgreso(error), textAlign: TextAlign.center),
            ],
            data: (lista) => _filtroYGraficaDeEjercicio(lista),
          )
        else
          ..._filtroYGraficaCorporal(),
        const SizedBox(height: 24),
        Text(
          'Las fechas son las de la sesión, no las del momento en que se '
          'anotó el resultado.',
          style: textos.bodySmall,
        ),
      ],
    );

    // Con `titulo` es el entrenador mirando a un cliente: llega empujada desde
    // la ficha y vuelve con la flecha, sin barra. Sin `titulo` es el cliente en
    // su propia pestana, y ahi la barra tiene que estar.
    if (widget.titulo != null) {
      return Scaffold(appBar: barra, body: cuerpo);
    }
    return PantallaCliente(
      rutaActual: Rutas.progresoCliente,
      appBar: barra,
      cuerpo: cuerpo,
    );
  }

  List<Widget> _filtroYGraficaDeEjercicio(List<EjercicioConRegistro> lista) {
    final textos = Theme.of(context).textTheme;
    if (lista.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            widget.titulo == null
                ? 'Todavía no has registrado el resultado de ningún ejercicio.'
                : 'Este cliente todavía no ha registrado ningún resultado.',
            textAlign: TextAlign.center,
            style: textos.bodyMedium,
          ),
        ),
      ];
    }

    // Al entrar, o si el ejercicio elegido deja de estar en la lista, se coge el
    // primero: la pantalla nunca se queda sin seleccion.
    final seleccionado =
        lista.where((e) => e.ejercicioId == _ejercicioId).firstOrNull ??
        lista.first;
    final metricas = MetricaEjercicio.deTipo(seleccionado.ejercicioTipo);
    final metrica = metricas.contains(_metricaEjercicio)
        ? _metricaEjercicio!
        : metricas.first;

    final registros = ref.watch(
      progresoDeEjercicioProvider(
        widget.clienteId,
        seleccionado.ejercicioId,
        _rango.desde,
        _rango.hasta,
      ),
    );

    return [
      DropdownButtonFormField<String>(
        key: const Key('selector_ejercicio'),
        initialValue: seleccionado.ejercicioId,
        decoration: const InputDecoration(
          labelText: 'Ejercicio',
          isDense: true,
        ),
        items: [
          for (final ejercicio in lista)
            DropdownMenuItem(
              value: ejercicio.ejercicioId,
              child: Text(ejercicio.ejercicioNombre),
            ),
        ],
        onChanged: (valor) => setState(() {
          _ejercicioId = valor;
          _metricaEjercicio = null;
        }),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<MetricaEjercicio>(
        key: const Key('selector_metrica'),
        initialValue: metrica,
        decoration: const InputDecoration(labelText: 'Métrica', isDense: true),
        items: [
          for (final opcion in metricas)
            DropdownMenuItem(value: opcion, child: Text(opcion.etiqueta)),
        ],
        onChanged: (valor) => setState(() => _metricaEjercicio = valor),
      ),
      const SizedBox(height: 4),
      Text(metrica.descripcion, style: textos.bodySmall),
      const SizedBox(height: 12),
      registros.when(
        loading: () => const SizedBox(
          height: GraficaProgreso.alto,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) =>
            Text(mensajeDeErrorProgreso(error), textAlign: TextAlign.center),
        data: (filas) => _GraficaConTabla(
          puntos: serieDeProgreso(registros: filas, metrica: metrica),
          unidad: metrica.unidad,
        ),
      ),
    ];
  }

  List<Widget> _filtroYGraficaCorporal() {
    final registros = ref.watch(
      medidasEnRangoProvider(widget.clienteId, _rango.desde, _rango.hasta),
    );

    return [
      DropdownButtonFormField<MetricaCorporal>(
        key: const Key('selector_metrica_corporal'),
        initialValue: _metricaCorporal,
        decoration: const InputDecoration(labelText: 'Medida', isDense: true),
        items: [
          for (final opcion in MetricaCorporal.values)
            DropdownMenuItem(value: opcion, child: Text(opcion.etiqueta)),
        ],
        onChanged: (valor) =>
            setState(() => _metricaCorporal = valor ?? _metricaCorporal),
      ),
      const SizedBox(height: 12),
      registros.when(
        loading: () => const SizedBox(
          height: GraficaProgreso.alto,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) =>
            Text(mensajeDeErrorProgreso(error), textAlign: TextAlign.center),
        data: (filas) => _GraficaConTabla(
          puntos: serieCorporal(registros: filas, metrica: _metricaCorporal),
          unidad: _metricaCorporal.unidad,
        ),
      ),
    ];
  }
}

/// La grafica y, debajo, los mismos datos en texto: un numero exacto se lee mejor
/// en una lista que en un punto de una linea.
class _GraficaConTabla extends StatelessWidget {
  const _GraficaConTabla({required this.puntos, required this.unidad});

  final List<PuntoProgreso> puntos;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GraficaProgreso(puntos: puntos, unidad: unidad),
        if (puntos.length > 1) ...[
          const SizedBox(height: 8),
          Text(_diferencia(puntos, unidad), style: textos.titleSmall),
        ],
        const SizedBox(height: 8),
        for (final punto in puntos.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    _comoFechaLarga(punto.fecha),
                    style: textos.bodySmall,
                  ),
                ),
                Text(
                  '${_numero(punto.valor)} $unidad',
                  style: textos.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Cuanto ha cambiado entre el primer y el ultimo registro del rango.
  static String _diferencia(List<PuntoProgreso> puntos, String unidad) {
    final delta = puntos.last.valor - puntos.first.valor;
    if (delta == 0) return 'Sin cambios en el rango.';
    final signo = delta > 0 ? '+' : '-';
    return '$signo${_numero(delta.abs())} $unidad '
        'desde el ${_comoFecha(puntos.first.fecha)}.';
  }
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';

String _comoFechaLarga(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
