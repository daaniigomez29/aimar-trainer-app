import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_registro_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/campo_numerico_pasos.dart';

/// Registro del resultado de un ejercicio (CU-20).
///
/// Para Fuerza se registra **serie a serie**: el boton grande confirma la serie en
/// curso y pasa a la siguiente. Cada confirmacion envia la lista completa de series
/// confirmadas hasta ese momento, no solo la ultima, para que la operacion sea
/// idempotente y corregir una serie anterior la actualice en su sitio.
///
/// Dejarlo a medias es valido: el ejercicio queda registrado con las series que
/// hubiera, que es justo lo que paso en el gimnasio.
class PantallaRegistroEjercicio extends ConsumerStatefulWidget {
  const PantallaRegistroEjercicio({
    required this.ejercicio,
    required this.planningId,
    required this.clienteId,
    super.key,
  });

  final EjercicioPlanificado ejercicio;
  final String planningId;
  final String clienteId;

  @override
  ConsumerState<PantallaRegistroEjercicio> createState() =>
      _PantallaRegistroEjercicioState();
}

class _PantallaRegistroEjercicioState
    extends ConsumerState<PantallaRegistroEjercicio> {
  final _peso = TextEditingController();
  final _repeticiones = TextEditingController();
  final _rir = TextEditingController();
  final _minutos = TextEditingController();

  /// Lo confirmado en esta pantalla, por numero de serie. Arranca con lo que ya
  /// estuviera registrado, para poder corregirlo.
  late final Map<int, DatosSerieRealizada> _confirmadas = {
    for (final serie in widget.ejercicio.seriesRealizadas)
      serie.numeroSerie: DatosSerieRealizada(
        numeroSerie: serie.numeroSerie,
        repeticiones: serie.repeticionesRealizadas,
        peso: serie.pesoReal,
        rir: serie.rirReal,
      ),
  };

  late int _serieActual = _primeraSinConfirmar();

  bool get _esCardio =>
      widget.ejercicio.ejercicio?.tipo == TipoEjercicio.cardio;

  /// Cuantas series se esperan. Si el cliente ya ha hecho mas de las planificadas,
  /// manda lo registrado: lo realizado no tiene que coincidir con lo previsto.
  int get _totalSeries {
    final planificadas = widget.ejercicio.series.length;
    final registradas = _confirmadas.keys.fold<int>(
      0,
      (maximo, numero) => numero > maximo ? numero : maximo,
    );
    return planificadas > registradas ? planificadas : registradas;
  }

  int _primeraSinConfirmar() {
    final planificadas = widget.ejercicio.series.length;
    for (var numero = 1; numero <= planificadas; numero++) {
      if (!_confirmadas.containsKey(numero)) return numero;
    }
    // Todas hechas: se queda en la ultima, por si hay que corregirla.
    return planificadas == 0 ? 1 : planificadas;
  }

  @override
  void initState() {
    super.initState();
    _cargarValoresDe(_serieActual);
    // Se parte de lo ya registrado y, si no hay nada, de lo planificado: igual
    // que las series de Fuerza, que llegan con los valores previstos puestos.
    final minutos =
        widget.ejercicio.minutosRealizados ??
        widget.ejercicio.minutosPlanificados;
    if (minutos != null) _minutos.text = _numero(minutos);
  }

  @override
  void dispose() {
    _peso.dispose();
    _repeticiones.dispose();
    _rir.dispose();
    _minutos.dispose();
    super.dispose();
  }

  /// Rellena los campos con lo mejor que haya para esa serie: lo ya registrado,
  /// y si no lo planificado, y si no lo de la serie anterior.
  void _cargarValoresDe(int numeroSerie) {
    final registrada = _confirmadas[numeroSerie];
    if (registrada != null) {
      _peso.text = registrada.peso == null ? '' : _numero(registrada.peso!);
      _repeticiones.text = '${registrada.repeticiones}';
      _rir.text = registrada.rir == null ? '' : '${registrada.rir}';
      return;
    }

    final planificada = widget.ejercicio.series
        .where((s) => s.numeroSerie == numeroSerie)
        .firstOrNull;
    if (planificada != null) {
      _peso.text = planificada.pesoPlanificado == null
          ? ''
          : _numero(planificada.pesoPlanificado!);
      _repeticiones.text = '${planificada.repeticionesPlanificadas}';
      _rir.text = planificada.rirPlanificado == null
          ? ''
          : '${planificada.rirPlanificado}';
      return;
    }

    final anterior = _confirmadas[numeroSerie - 1];
    if (anterior != null) {
      _peso.text = anterior.peso == null ? '' : _numero(anterior.peso!);
      _repeticiones.text = '${anterior.repeticiones}';
      _rir.text = anterior.rir == null ? '' : '${anterior.rir}';
    }
  }

  Future<void> _confirmarSerie() async {
    final repeticiones = int.tryParse(_repeticiones.text.trim());
    if (repeticiones == null) {
      _avisar('Pon cuantas repeticiones hiciste.');
      return;
    }

    final serie = DatosSerieRealizada(
      numeroSerie: _serieActual,
      repeticiones: repeticiones,
      peso: double.tryParse(_peso.text.trim().replaceAll(',', '.')),
      rir: int.tryParse(_rir.text.trim()),
    );

    final pendientes = {..._confirmadas, _serieActual: serie};
    final resultado = await ref
        .read(controladorRegistroSesionProvider.notifier)
        .registrarFuerza(
          ejercicioPlanificadoId: widget.ejercicio.id,
          series: pendientes.values.toList()
            ..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie)),
          planningId: widget.planningId,
        );
    if (!mounted) return;

    if (resultado.esFallo) return;

    setState(() {
      _confirmadas[_serieActual] = serie;
      // Siempre se avanza, incluso pasada la ultima serie prevista: el cliente
      // puede haber hecho mas de las planificadas, y eso es un dato valido.
      _serieActual++;
      _cargarValoresDe(_serieActual);
    });
  }

  Future<void> _guardarCardio() async {
    final minutos = double.tryParse(_minutos.text.trim().replaceAll(',', '.'));
    final resultado = await ref
        .read(controladorRegistroSesionProvider.notifier)
        .registrarCardio(
          ejercicioPlanificadoId: widget.ejercicio.id,
          minutos: minutos,
          planningId: widget.planningId,
        );
    if (!mounted || resultado.esFallo) return;

    Navigator.of(context).pop();
  }

  void _avisar(String mensaje) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorRegistroSesionProvider);
    final nombre = widget.ejercicio.ejercicio?.nombre ?? 'Ejercicio';

    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Historico(
            ejercicio: widget.ejercicio,
            clienteId: widget.clienteId,
            confirmadas: _confirmadas,
          ),
          const Divider(height: 32),
          if (_esCardio)
            ..._cuerpoCardio(estado.errorDelCampo('minutos'))
          else
            ..._cuerpoFuerza(estado),
          if (estado.errorGeneral case final mensaje?) ...[
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _cuerpoFuerza(EstadoAccion estado) {
    final textos = Theme.of(context).textTheme;

    return [
      Row(
        children: [
          Text('Serie', style: textos.titleSmall),
          const SizedBox(width: 12),
          Text('$_serieActual', style: textos.headlineMedium),
          Text(
            _totalSeries == 0 ? '' : ' /$_totalSeries',
            style: textos.titleMedium,
          ),
          const Spacer(),
          if (_confirmadas.containsKey(_serieActual))
            const Chip(
              avatar: Icon(Icons.check, size: 16),
              label: Text('Registrada'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      CampoNumericoPasos(
        etiqueta: 'Peso',
        controlador: _peso,
        unidad: 'kg',
        paso: 2.5,
        decimales: true,
        mensajeError: estado.errorDelCampo('peso'),
      ),
      CampoNumericoPasos(
        etiqueta: 'Reps',
        controlador: _repeticiones,
        unidad: 'x',
        mensajeError: estado.errorDelCampo('repeticiones'),
      ),
      CampoNumericoPasos(
        etiqueta: 'RIR',
        controlador: _rir,
        unidad: '',
        maximo: 10,
        mensajeError: estado.errorDelCampo('rir'),
      ),
      const SizedBox(height: 12),
      Text(
        'El peso y el RIR pueden quedarse vacios. Puedes dejar el ejercicio a '
        'medias: se guarda lo que hayas confirmado.',
        style: textos.bodySmall,
      ),
      const SizedBox(height: 24),
      Center(
        child: FilledButton.icon(
          key: const Key('boton_confirmar_serie'),
          onPressed: estado.enCurso ? null : _confirmarSerie,
          icon: const Icon(Icons.check),
          label: Text('Confirmar serie $_serieActual'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(220, 56),
            textStyle: textos.titleMedium,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Terminar ejercicio'),
        ),
      ),
    ];
  }

  List<Widget> _cuerpoCardio(String? errorMinutos) {
    final estado = ref.watch(controladorRegistroSesionProvider);
    final planificados = widget.ejercicio.minutosPlanificados;

    return [
      if (planificados != null)
        Text(
          'Planificado: ${_numero(planificados)} min',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      const SizedBox(height: 8),
      CampoNumericoPasos(
        etiqueta: 'Minutos',
        controlador: _minutos,
        unidad: 'min',
        paso: 5,
        decimales: true,
        mensajeError: errorMinutos,
      ),
      const SizedBox(height: 24),
      Center(
        child: FilledButton.icon(
          key: const Key('boton_guardar_cardio'),
          onPressed: estado.enCurso ? null : _guardarCardio,
          icon: const Icon(Icons.check),
          label: const Text('Guardar minutos'),
          style: FilledButton.styleFrom(minimumSize: const Size(220, 56)),
        ),
      ),
    ];
  }
}

/// Lo planificado para hoy, lo ya confirmado y las ultimas sesiones de este mismo
/// ejercicio: es lo que hace falta para decidir con que peso entrar a la serie.
class _Historico extends ConsumerWidget {
  const _Historico({
    required this.ejercicio,
    required this.clienteId,
    required this.confirmadas,
  });

  final EjercicioPlanificado ejercicio;
  final String clienteId;
  final Map<int, DatosSerieRealizada> confirmadas;

  /// Cuantas sesiones anteriores se muestran. Mas no caben de un vistazo.
  static const int sesionesAnteriores = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final rango = RangoFechas.ultimosMeses(6);
    final historico = ref
        .watch(
          progresoDeEjercicioProvider(
            clienteId,
            ejercicio.ejercicioId,
            rango.desde,
            rango.hasta,
          ),
        )
        .value;

    final porFecha = <DateTime, List<RegistroProgreso>>{};
    for (final registro in historico ?? const <RegistroProgreso>[]) {
      final dia = DateTime(
        registro.fecha.year,
        registro.fecha.month,
        registro.fecha.day,
      );
      porFecha.putIfAbsent(dia, () => []).add(registro);
    }
    final fechas = porFecha.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 64, child: Text('', style: textos.labelSmall)),
            Expanded(child: Text('Serie', style: textos.labelSmall)),
            Expanded(child: Text('Peso', style: textos.labelSmall)),
            Expanded(child: Text('Reps', style: textos.labelSmall)),
          ],
        ),
        const Divider(),
        _Grupo(
          etiqueta: 'Plan',
          filas: [
            for (final serie in ejercicio.series)
              (
                numero: serie.numeroSerie,
                peso: serie.pesoPlanificado,
                reps: serie.repeticionesPlanificadas,
              ),
          ],
          atenuado: true,
        ),
        if (confirmadas.isNotEmpty)
          _Grupo(
            etiqueta: 'Hoy',
            filas: [
              for (final serie
                  in confirmadas.values.toList()
                    ..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie)))
                (
                  numero: serie.numeroSerie,
                  peso: serie.peso,
                  reps: serie.repeticiones,
                ),
            ],
            atenuado: false,
          ),
        for (final fecha in fechas.take(sesionesAnteriores))
          _Grupo(
            etiqueta: _comoFechaCorta(fecha),
            filas: [
              for (final registro
                  in porFecha[fecha]!..sort(
                    (a, b) =>
                        (a.numeroSerie ?? 0).compareTo(b.numeroSerie ?? 0),
                  ))
                (
                  numero: registro.numeroSerie ?? 0,
                  peso: registro.pesoReal,
                  reps: registro.repeticionesRealizadas ?? 0,
                ),
            ],
            atenuado: true,
          ),
        if (ejercicio.series.isEmpty && fechas.isEmpty && confirmadas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin series planificadas ni historico de este ejercicio.',
              style: textos.bodySmall,
            ),
          ),
      ],
    );
  }
}

typedef _Fila = ({int numero, double? peso, int reps});

class _Grupo extends StatelessWidget {
  const _Grupo({
    required this.etiqueta,
    required this.filas,
    required this.atenuado,
  });

  final String etiqueta;
  final List<_Fila> filas;
  final bool atenuado;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return const SizedBox.shrink();

    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final estilo = textos.bodyMedium?.copyWith(
      color: atenuado ? esquema.outline : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              etiqueta,
              style: textos.labelMedium?.copyWith(color: esquema.outline),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (final fila in filas) Text('${fila.numero}', style: estilo),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (final fila in filas)
                  Text(
                    fila.peso == null ? '-' : _numero(fila.peso!),
                    style: estilo,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (final fila in filas) Text('${fila.reps}', style: estilo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFechaCorta(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
