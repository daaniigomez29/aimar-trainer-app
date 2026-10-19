import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/filtro_de_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/application/controlador_packs.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/fila_de_serie.dart';

/// Anadir un ejercicio al pack, o editar el que ya hay (RF-25.1).
///
/// Es el hermano del formulario de CU-08, con dos diferencias que vienen de lo
/// que es un pack:
///
/// 1. **Lo preparado es opcional.** Se puede guardar el ejercicio sin series y
///    sin minutos: lo que falte se rellena al planificar. Por eso la tabla de
///    series empieza vacia, con un boton para anadir la primera.
/// 2. **Solo se eligen ejercicios del tipo del pack**, que es lo que impone el
///    trigger de la base. El filtro se abre ya restringido a ese tipo, asi que
///    no se puede elegir algo que luego se rechace al guardar.
class PantallaFormularioEjercicioPack extends ConsumerStatefulWidget {
  const PantallaFormularioEjercicioPack({
    required this.pack,
    this.ejercicioDelPack,
    super.key,
  });

  final Pack pack;
  final PackEjercicio? ejercicioDelPack;

  bool get esEdicion => ejercicioDelPack != null;

  @override
  ConsumerState<PantallaFormularioEjercicioPack> createState() =>
      _EstadoFormularioEjercicioPack();
}

class _EstadoFormularioEjercicioPack
    extends ConsumerState<PantallaFormularioEjercicioPack> {
  Ejercicio? _ejercicio;
  late final TextEditingController _descanso;
  late final TextEditingController _minutos;
  late List<CamposDeSerie> _series;

  @override
  void initState() {
    super.initState();
    final previo = widget.ejercicioDelPack;
    _ejercicio = previo?.ejercicio;
    _descanso = TextEditingController(
      text: previo?.descansoSeg?.toString() ?? '',
    );
    _minutos = TextEditingController(
      text: _sinDecimalSobrante(previo?.minutos),
    );
    // Vacia si no habia nada: en un pack, no preparar series es una opcion, no
    // un formulario a medias.
    _series = [
      for (final serie in previo?.seriesOrdenadas ?? const <PackSerie>[])
        CamposDeSerie.desde(
          DatosSerie(
            numeroSerie: serie.numeroSerie,
            repeticiones: serie.repeticiones,
            peso: serie.peso,
            rir: serie.rir,
          ),
        ),
    ];

    // El filtro se restringe al tipo del pack en cuanto se pinta: elegir un
    // ejercicio de otro tipo acabaria en un rechazo del trigger.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(
            filtroBibliotecaProvider(AmbitoDeFiltro.formularioPack).notifier,
          )
          .cambiarTipo(widget.pack.tipo);
    });
  }

  @override
  void dispose() {
    _descanso.dispose();
    _minutos.dispose();
    for (final serie in _series) {
      serie.dispose();
    }
    super.dispose();
  }

  static String _sinDecimalSobrante(double? valor) {
    if (valor == null) return '';
    return valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
  }

  static double? _comoDecimal(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    return limpio.isEmpty ? null : double.tryParse(limpio);
  }

  static int? _comoEntero(String texto) =>
      texto.trim().isEmpty ? null : int.tryParse(texto.trim());

  DatosPackEjercicio? get _datos {
    final ejercicio = _ejercicio;
    if (ejercicio == null) return null;

    return DatosPackEjercicio(
      packId: widget.pack.id,
      ejercicioId: ejercicio.id,
      tipo: widget.pack.tipo,
      orden: widget.ejercicioDelPack?.orden ?? widget.pack.siguienteOrden,
      descansoSeg: _comoEntero(_descanso.text),
      minutos: _comoDecimal(_minutos.text),
      series: [
        for (var i = 0; i < _series.length; i++)
          DatosSerie(
            numeroSerie: i + 1,
            repeticiones: _comoEntero(_series[i].repeticiones.text) ?? 0,
            peso: _comoDecimal(_series[i].peso.text),
            rir: _comoEntero(_series[i].rir.text),
          ),
      ],
    );
  }

  Future<void> _guardar() async {
    final datos = _datos;
    if (datos == null) return;

    final resultado = await ref
        .read(controladorPacksProvider.notifier)
        .guardarEjercicio(datos: datos, id: widget.ejercicioDelPack?.id);

    if (!mounted || resultado.esFallo) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorPacksProvider);
    final controlador = ref.read(controladorPacksProvider.notifier);
    final ejercicio = _ejercicio;

    return FormularioCentrado(
      seccion: SeccionDeNavegacion.packs,
      titulo: widget.esEdicion ? 'Editar ejercicio' : 'Añadir al pack',
      subtitulo: '${widget.pack.nombre} · ${widget.pack.tipo.etiqueta}',
      hijos: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        _SelectorEjercicio(
          tipo: widget.pack.tipo,
          elegido: ejercicio,
          habilitado: !estado.enCurso,
          error: estado.errorDelCampo('ejercicioId'),
          onElegir: (elegido) {
            controlador.limpiarError();
            setState(() => _ejercicio = elegido);
          },
        ),
        if (ejercicio != null) ...[
          const Divider(height: 32),
          if (widget.pack.tipo.vaPorMinutos)
            _Minutos(
              controlador: _minutos,
              habilitado: !estado.enCurso,
              error: estado.errorDelCampo('minutos'),
              onCambio: controlador.limpiarError,
            )
          else
            _Series(
              descanso: _descanso,
              series: _series,
              habilitado: !estado.enCurso,
              errorDescanso: estado.errorDelCampo('descansoSeg'),
              errorSeries: estado.errorDelCampo('series'),
              errorRepeticiones: estado.errorDelCampo('repeticiones'),
              errorPeso: estado.errorDelCampo('peso'),
              errorRir: estado.errorDelCampo('rir'),
              onAnadir: () => setState(() {
                // Hereda lo de la anterior, como en el planning; la primera
                // nace con las repeticiones de siempre.
                _series.add(
                  _series.isEmpty
                      ? CamposDeSerie.nueva()
                      : CamposDeSerie.comoLaAnterior(_series.last),
                );
              }),
              onQuitar: (indice) =>
                  setState(() => _series.removeAt(indice).dispose()),
              onCambio: controlador.limpiarError,
            ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_guardar_ejercicio_pack'),
          onPressed: estado.enCurso || ejercicio == null ? null : _guardar,
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.esEdicion ? 'Guardar cambios' : 'Añadir'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Elegir el ejercicio, con el buscador y el filtro de la biblioteca, ya
/// restringidos al tipo del pack.
class _SelectorEjercicio extends ConsumerWidget {
  const _SelectorEjercicio({
    required this.tipo,
    required this.elegido,
    required this.habilitado,
    required this.error,
    required this.onElegir,
  });

  final TipoEjercicio tipo;
  final Ejercicio? elegido;
  final bool habilitado;
  final String? error;
  final ValueChanged<Ejercicio?> onElegir;

  static const double _altoMaximoLista = 260;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    if (elegido case final ejercicio?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ejercicio *', style: textos.labelLarge),
          const SizedBox(height: 8),
          Tarjeta(
            padding: const EdgeInsets.all(10),
            hijo: Row(
              children: [
                MiniaturaEjercicio(ejercicio: ejercicio, lado: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ejercicio.nombre, style: textos.titleSmall),
                ),
                TextButton(
                  key: const Key('cambiar_ejercicio_pack'),
                  onPressed: habilitado ? () => onElegir(null) : null,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final filtrados = ref.watch(
      ejerciciosFiltradosProvider(AmbitoDeFiltro.formularioPack),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ejercicio *', style: textos.labelLarge),
        if (error case final mensaje?) ...[
          const SizedBox(height: 4),
          Text(
            mensaje,
            style: textos.bodySmall?.copyWith(color: Tokens.peligro),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Solo de ${tipo.etiqueta.toLowerCase()}: todos los ejercicios de un '
          'pack son de su tipo.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 8),
        FiltroDeEjercicios(
          ambito: AmbitoDeFiltro.formularioPack,
          habilitado: habilitado,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          // Acotada: dentro de un formulario que ya se desplaza, una lista sin
          // limite empuja los demas campos fuera de la pantalla.
          constraints: const BoxConstraints(maxHeight: _altoMaximoLista),
          child: filtrados.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                AvisoEnLinea(mensaje: mensajeDeErrorPacks(error)),
            data: (lista) {
              final activos = lista.where((e) => e.estado.esActivo).toList();
              if (activos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Ningún ejercicio de ${tipo.etiqueta.toLowerCase()} '
                    'coincide con la búsqueda.',
                    style: textos.bodySmall,
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: activos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, indice) {
                  final ejercicio = activos[indice];
                  return Tarjeta(
                    key: Key('elegir_para_pack_${ejercicio.id}'),
                    padding: const EdgeInsets.all(10),
                    onTap: habilitado ? () => onElegir(ejercicio) : null,
                    hijo: Row(
                      children: [
                        MiniaturaEjercicio(ejercicio: ejercicio, lado: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ejercicio.nombre, style: textos.titleSmall),
                              if (ejercicio.resumenMuscular case final resumen?)
                                Text(resumen, style: textos.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Tokens.textoTenue,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Los minutos de un pack de cardio. **Opcionales**: si no se ponen, el
/// ejercicio llega al planning sin ellos y se rellenan alli.
class _Minutos extends StatelessWidget {
  const _Minutos({
    required this.controlador,
    required this.habilitado,
    required this.onCambio,
    this.error,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final String? error;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Minutos', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        'Opcional: déjalo vacío si prefieres decidirlo al planificar.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('campo_minutos_pack'),
        controller: controlador,
        enabled: habilitado,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        onChanged: (_) => onCambio(),
        decoration: InputDecoration(labelText: 'Minutos', errorText: error),
      ),
    ],
  );
}

/// Las series preparadas. Pueden ser **ninguna**.
class _Series extends StatelessWidget {
  const _Series({
    required this.descanso,
    required this.series,
    required this.habilitado,
    required this.onAnadir,
    required this.onQuitar,
    required this.onCambio,
    this.errorDescanso,
    this.errorSeries,
    this.errorRepeticiones,
    this.errorPeso,
    this.errorRir,
  });

  final TextEditingController descanso;
  final List<CamposDeSerie> series;
  final bool habilitado;
  final String? errorDescanso;
  final String? errorSeries;
  final String? errorRepeticiones;
  final String? errorPeso;
  final String? errorRir;
  final VoidCallback onAnadir;
  final ValueChanged<int> onQuitar;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('campo_descanso_pack'),
          controller: descanso,
          enabled: habilitado,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onCambio(),
          decoration: InputDecoration(
            labelText: 'Descanso entre series (segundos)',
            helperText: 'Opcional.',
            errorText: errorDescanso,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Series', style: textos.titleSmall)),
            TextButton.icon(
              key: const Key('boton_anadir_serie_pack'),
              onPressed: habilitado ? onAnadir : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir serie'),
            ),
          ],
        ),
        if (errorSeries != null) ...[
          const SizedBox(height: 4),
          AvisoEnLinea(mensaje: errorSeries!),
        ],
        const SizedBox(height: 8),
        if (series.isEmpty)
          Text(
            'Sin series preparadas. Puedes dejarlo así y ponerlas al '
            'planificar.',
            style: textos.bodySmall,
          ),
        for (var i = 0; i < series.length; i++)
          FilaDeSerie(
            numero: i + 1,
            campos: series[i],
            habilitado: habilitado,
            onCambio: onCambio,
            // Aqui si se puede quitar la ultima: un pack sin series es valido.
            onQuitar: () => onQuitar(i),
            errorPeso: errorPeso,
            errorRepeticiones: errorRepeticiones,
            errorRir: errorRir,
          ),
      ],
    );
  }
}
