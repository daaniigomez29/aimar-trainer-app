import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/fotos_progreso.dart';

/// Control semanal en dos pasos (`docs/ui-design.md`, 6.3).
///
/// **Siguen siendo dos guardados independientes**, como manda el modelo de
/// dominio: "Continuar" guarda las medidas y pasa al check-in; el boton del
/// paso 2 guarda el check-in. Si el cliente abandona entre medias, lo del paso 1
/// ya esta guardado. Lo unico que cambia respecto a la version anterior es que
/// no se ven los dos formularios a la vez.
///
/// La flecha atras del paso 2 vuelve al 1 **sin perder nada**: los controladores
/// de texto viven en este estado, no en cada paso.
class PantallaControlSemanal extends ConsumerStatefulWidget {
  const PantallaControlSemanal({
    required this.clienteId,
    this.soloLectura = false,
    super.key,
  });

  final String clienteId;

  /// El entrenador entra asi: ve lo de su cliente, sin poder escribir por el.
  final bool soloLectura;

  @override
  ConsumerState<PantallaControlSemanal> createState() =>
      _PantallaControlSemanalState();
}

class _PantallaControlSemanalState
    extends ConsumerState<PantallaControlSemanal> {
  // --- Paso 1: medidas ---
  final _peso = TextEditingController();
  final _pecho = TextEditingController();
  final _cintura = TextEditingController();
  final _cadera = TextEditingController();
  final _cuadriceps = TextEditingController();
  final _brazos = TextEditingController();

  // --- Paso 2: check-in ---
  final _horasSueno = TextEditingController();
  final _notas = TextEditingController();
  static const int _valorNeutro = 5;
  int _estres = _valorNeutro;
  int _agujetas = _valorNeutro;
  int _fatiga = _valorNeutro;

  int _paso = 0;
  DateTime? _fecha;

  /// De que registro se volcaron los campos, para no pisar lo que el cliente
  /// esta escribiendo cada vez que el provider emite.
  String? _idMedidas;
  String? _idCheckin;
  DateTime? _fechaCargada;

  @override
  void dispose() {
    for (final controlador in [
      _peso,
      _pecho,
      _cintura,
      _cadera,
      _cuadriceps,
      _brazos,
      _horasSueno,
      _notas,
    ]) {
      controlador.dispose();
    }
    super.dispose();
  }

  void _volcarMedidas(RegistroMedidas? registro, DateTime fecha) {
    _idMedidas = registro?.id;
    _fechaCargada = fecha;
    _peso.text = registro == null ? '' : _numero(registro.pesoKg);
    _pecho.text = _opcional(registro?.pechoCm);
    _cintura.text = _opcional(registro?.cinturaCm);
    _cadera.text = _opcional(registro?.caderaCm);
    _cuadriceps.text = _opcional(registro?.cuadricepsCm);
    _brazos.text = _opcional(registro?.brazosCm);
  }

  void _volcarCheckin(CheckinRecuperacion? checkin) {
    _idCheckin = checkin?.id;
    _horasSueno.text = checkin == null ? '' : _numero(checkin.horasSueno);
    _notas.text = checkin?.notas ?? '';
    _estres = checkin?.estres ?? _valorNeutro;
    _agujetas = checkin?.agujetas ?? _valorNeutro;
    _fatiga = checkin?.fatiga ?? _valorNeutro;
  }

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

  Future<void> _guardarMedidasYContinuar(DateTime fecha) async {
    final datos = DatosRegistroMedidas(
      clienteId: widget.clienteId,
      fecha: fecha,
      pesoKg: _comoDouble(_peso.text),
      pechoCm: _comoDouble(_pecho.text),
      cinturaCm: _comoDouble(_cintura.text),
      caderaCm: _comoDouble(_cadera.text),
      cuadricepsCm: _comoDouble(_cuadriceps.text),
      brazosCm: _comoDouble(_brazos.text),
    );

    final resultado = await ref
        .read(controladorControlSemanalProvider.notifier)
        .guardarMedidas(datos);
    if (!mounted || resultado.esFallo) return;

    setState(() => _paso = 1);
  }

  Future<void> _guardarCheckin(DateTime fecha) async {
    final datos = DatosCheckin(
      clienteId: widget.clienteId,
      fecha: fecha,
      horasSueno: _comoDouble(_horasSueno.text),
      estres: _estres,
      agujetas: _agujetas,
      fatiga: _fatiga,
      notas: _notas.text,
    );

    final resultado = await ref
        .read(controladorControlSemanalProvider.notifier)
        .guardarCheckin(datos);
    if (!mounted || resultado.esFallo) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Control semanal guardado.')));
  }

  @override
  Widget build(BuildContext context) {
    final ficha = ref.watch(clientePorIdProvider(widget.clienteId));

    return ficha.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Mi control')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              mensajeDeErrorProgreso(error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (cliente) {
        // Por defecto, el ultimo dia de control que ha pasado: es el que el
        // cliente viene a rellenar.
        final fecha = _fecha ?? cliente.diaControlPreferido.ultimaFecha();
        final medidas = ref
            .watch(medidasDelDiaProvider(widget.clienteId, fecha))
            .value;
        final checkin = ref
            .watch(checkinDelDiaProvider(widget.clienteId, fecha))
            .value;

        // Se vuelca una sola vez por fecha y registro.
        if (_fechaCargada != fecha || _idMedidas != medidas?.id) {
          _volcarMedidas(medidas, fecha);
        }
        if (_idCheckin != checkin?.id) _volcarCheckin(checkin);

        final estado = ref.watch(controladorControlSemanalProvider);
        final cuerpo = _paso == 0
            ? _PasoMedidas(
                fecha: fecha,
                diaDeControl: cliente.diaControlPreferido.etiqueta,
                campos: _camposMedidas,
                registro: medidas,
                clienteId: widget.clienteId,
                soloLectura: widget.soloLectura,
                onCambiarFecha: () => _elegirFecha(fecha),
              )
            : _PasoCheckin(
                horasSueno: _horasSueno,
                notas: _notas,
                estres: _estres,
                agujetas: _agujetas,
                fatiga: _fatiga,
                soloLectura: widget.soloLectura,
                onEstres: (v) => setState(() => _estres = v),
                onAgujetas: (v) => setState(() => _agujetas = v),
                onFatiga: (v) => setState(() => _fatiga = v),
              );

        return PantallaCliente(
          rutaActual: Rutas.controlCliente,
          appBar: AppBar(
            leading: _paso == 0
                ? null
                : BackButton(
                    key: const Key('boton_volver_a_medidas'),
                    // Vuelve al paso 1 sin perder lo escrito: los campos viven
                    // en este estado, no en el paso.
                    onPressed: () => setState(() => _paso = 0),
                  ),
            title: Text(
              widget.soloLectura ? 'Control del cliente' : 'Mi control',
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Tokens.margenPantalla),
                child: _Pasos(actual: _paso),
              ),
            ],
          ),
          cuerpo: ListView(
            padding: const EdgeInsets.fromLTRB(
              Tokens.margenPantalla,
              8,
              Tokens.margenPantalla,
              24,
            ),
            children: [
              cuerpo,
              if (estado.errorGeneral case final mensaje?) ...[
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Tokens.peligro),
                ),
              ],
            ],
          ),
          ctaInferior: widget.soloLectura
              ? null
              : _paso == 0
              ? BotonCta(
                  key: const Key('boton_guardar_medidas'),
                  etiqueta: 'Continuar',
                  cargando: estado.enCurso,
                  onPulsar: () => _guardarMedidasYContinuar(fecha),
                )
              : BotonCta(
                  key: const Key('boton_guardar_checkin'),
                  etiqueta: 'Guardar check-in',
                  icono: Icons.check,
                  cargando: estado.enCurso,
                  onPulsar: () => _guardarCheckin(fecha),
                ),
        );
      },
    );
  }

  List<(String, String, TextEditingController, String)> get _camposMedidas => [
    ('Peso (kg) · obligatorio', 'pesoKg', _peso, 'peso'),
    ('Pecho (cm)', 'pechoCm', _pecho, 'pecho'),
    ('Cintura (cm)', 'cinturaCm', _cintura, 'cintura'),
    ('Cadera (cm)', 'caderaCm', _cadera, 'cadera'),
    ('Cuadriceps (cm)', 'cuadricepsCm', _cuadriceps, 'cuadriceps'),
    ('Brazos (cm)', 'brazosCm', _brazos, 'brazos'),
  ];

  static String _opcional(double? valor) => valor == null ? '' : _numero(valor);

  static double? _comoDouble(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));
}

class _PasoMedidas extends ConsumerWidget {
  const _PasoMedidas({
    required this.fecha,
    required this.diaDeControl,
    required this.campos,
    required this.registro,
    required this.clienteId,
    required this.soloLectura,
    required this.onCambiarFecha,
  });

  final DateTime fecha;
  final String diaDeControl;
  final List<(String, String, TextEditingController, String)> campos;
  final RegistroMedidas? registro;
  final String clienteId;
  final bool soloLectura;
  final VoidCallback onCambiarFecha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final estado = ref.watch(controladorControlSemanalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_comoFecha(fecha), style: textos.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Dia de control: $diaDeControl',
                    style: textos.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              key: const Key('boton_cambiar_fecha_control'),
              onPressed: onCambiarFecha,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('Cambiar dia'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.straighten, size: 18, color: Tokens.acento),
            const SizedBox(width: 8),
            Text('Medidas corporales', style: textos.titleMedium),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Solo el peso es obligatorio. Deja en blanco lo que no te hayas medido.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 14),
        for (final (etiqueta, campo, controlador, clave) in campos) ...[
          TextField(
            key: Key('medida_$clave'),
            controller: controlador,
            enabled: !soloLectura,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: etiqueta,
              errorText: estado.errorDelCampo(campo),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        // Las fotos no estan en el prototipo, pero si en el dominio (entidad 9):
        // quitarlas seria perder una funcionalidad ya entregada.
        FotosProgreso(
          clienteId: clienteId,
          registro: registro,
          soloLectura: soloLectura,
        ),
      ],
    );
  }
}

class _PasoCheckin extends StatelessWidget {
  const _PasoCheckin({
    required this.horasSueno,
    required this.notas,
    required this.estres,
    required this.agujetas,
    required this.fatiga,
    required this.soloLectura,
    required this.onEstres,
    required this.onAgujetas,
    required this.onFatiga,
  });

  final TextEditingController horasSueno;
  final TextEditingController notas;
  final int estres;
  final int agujetas;
  final int fatiga;
  final bool soloLectura;
  final ValueChanged<int> onEstres;
  final ValueChanged<int> onAgujetas;
  final ValueChanged<int> onFatiga;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.self_improvement, size: 18, color: Tokens.acento),
            const SizedBox(width: 8),
            Text('Check-in de recuperacion', style: textos.titleMedium),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Como ha ido la semana al margen del entrenamiento.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_horas_sueno'),
          controller: horasSueno,
          enabled: !soloLectura,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Horas de sueno (media de la semana)',
            suffixText: 'h',
          ),
        ),
        const SizedBox(height: 18),
        // Escala 1-10, no 0-10: aqui el 1 ya es "nada", al contrario que en el
        // RIR, donde el 0 significa fallo muscular.
        SliderConValor(
          key: const Key('escala_estres'),
          etiqueta: 'Estres',
          valor: estres.toDouble(),
          minimo: 1,
          maximo: 10,
          divisiones: 9,
          habilitado: !soloLectura,
          onCambio: (v) => onEstres(v.round()),
        ),
        SliderConValor(
          key: const Key('escala_agujetas'),
          etiqueta: 'Agujetas',
          valor: agujetas.toDouble(),
          minimo: 1,
          maximo: 10,
          divisiones: 9,
          habilitado: !soloLectura,
          onCambio: (v) => onAgujetas(v.round()),
        ),
        SliderConValor(
          key: const Key('escala_fatiga'),
          etiqueta: 'Fatiga',
          valor: fatiga.toDouble(),
          minimo: 1,
          maximo: 10,
          divisiones: 9,
          habilitado: !soloLectura,
          onCambio: (v) => onFatiga(v.round()),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('campo_notas_checkin'),
          controller: notas,
          enabled: !soloLectura,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Notas (opcional): lesiones, viajes, cambios de rutina...',
          ),
        ),
      ],
    );
  }
}

/// Los dos trazos de la cabecera: en que paso del flujo esta.
class _Pasos extends StatelessWidget {
  const _Pasos({required this.actual});

  final int actual;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 2; i++)
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: i <= actual ? Tokens.acento : Tokens.superficie3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
    ],
  );
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
