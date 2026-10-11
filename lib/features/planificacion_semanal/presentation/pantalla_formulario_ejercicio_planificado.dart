import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/filtro_de_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// CU-08 (anadir ejercicio a un bloque) y CU-12 (editarlo).
///
/// El formulario **cambia segun el tipo del ejercicio elegido**: Fuerza muestra la
/// tabla de series y el descanso; Cardio muestra los minutos. No es posible pedir
/// series a un Cardio ni minutos a una Fuerza, porque los campos del tipo que no
/// toca ni se pintan (punto 6 del encargo). El trigger
/// `validar_tipo_ejercicio_planificado` lo garantiza igualmente en la base de
/// datos.
class PantallaFormularioEjercicioPlanificado extends ConsumerStatefulWidget {
  const PantallaFormularioEjercicioPlanificado({
    required this.bloque,
    required this.planningId,
    this.ejercicioPlanificado,
    super.key,
  });

  final BloqueEjercicio bloque;
  final String planningId;
  final EjercicioPlanificado? ejercicioPlanificado;

  bool get esEdicion => ejercicioPlanificado != null;

  @override
  ConsumerState<PantallaFormularioEjercicioPlanificado> createState() =>
      _EstadoFormularioEjercicioPlanificado();
}

class _EstadoFormularioEjercicioPlanificado
    extends ConsumerState<PantallaFormularioEjercicioPlanificado> {
  Ejercicio? _ejercicio;
  late final TextEditingController _orden;
  late final TextEditingController _descanso;
  late final TextEditingController _minutos;
  late List<_FilaSerie> _series;

  @override
  void initState() {
    super.initState();
    final previo = widget.ejercicioPlanificado;
    _ejercicio = previo?.ejercicio;
    _orden = TextEditingController(
      text: (previo?.orden ?? widget.bloque.ejercicios.length + 1).toString(),
    );
    _descanso = TextEditingController(
      text: previo?.descansoPlanificadoSeg?.toString() ?? '',
    );
    _minutos = TextEditingController(
      text: _sinDecimalSobrante(previo?.minutosPlanificados),
    );
    _series = previo != null && previo.series.isNotEmpty
        ? [
            for (final s in previo.series)
              _FilaSerie.desde(DatosSerie.desdeSerie(s)),
          ]
        : [_FilaSerie.nueva(1)];
  }

  static String _sinDecimalSobrante(double? valor) {
    if (valor == null) return '';
    return valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _orden.dispose();
    _descanso.dispose();
    _minutos.dispose();
    for (final fila in _series) {
      fila.dispose();
    }
    super.dispose();
  }

  static double? _comoDecimal(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    return limpio.isEmpty ? null : double.tryParse(limpio);
  }

  static int? _comoEntero(String texto) =>
      texto.trim().isEmpty ? null : int.tryParse(texto.trim());

  DatosEjercicioPlanificado? get _datos {
    final ejercicio = _ejercicio;
    if (ejercicio == null) return null;

    return DatosEjercicioPlanificado(
      bloqueId: widget.bloque.id,
      ejercicioId: ejercicio.id,
      tipoEjercicio: ejercicio.tipo,
      orden: _comoEntero(_orden.text) ?? 0,
      // Los campos del tipo que no aplica van a null: asi una edicion que cambie
      // de ejercicio limpia lo que sobra.
      descansoSeg: ejercicio.tipo.vaPorSeries
          ? _comoEntero(_descanso.text)
          : null,
      minutos: ejercicio.tipo.vaPorMinutos ? _comoDecimal(_minutos.text) : null,
      series: ejercicio.tipo.vaPorSeries
          ? [
              for (var i = 0; i < _series.length; i++)
                DatosSerie(
                  numeroSerie: i + 1,
                  repeticiones: _comoEntero(_series[i].repeticiones.text) ?? 0,
                  peso: _comoDecimal(_series[i].peso.text),
                  rir: _comoEntero(_series[i].rir.text),
                ),
            ]
          : const [],
    );
  }

  Future<void> _guardar() async {
    final datos = _datos;
    if (datos == null) return;

    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final previo = widget.ejercicioPlanificado;
    final resultado = previo == null
        ? await controlador.crearEjercicio(
            datos: datos,
            bloque: widget.bloque,
            planningId: widget.planningId,
          )
        : await controlador.editarEjercicio(
            id: previo.id,
            datos: datos,
            bloque: widget.bloque,
            planningId: widget.planningId,
          );

    if (!mounted || resultado.esFallo) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Avisos.duracion,
        content: Text(
          widget.esEdicion ? 'Ejercicio actualizado.' : 'Ejercicio añadido.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorPlanificacionProvider);
    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final biblioteca = ref.watch(bibliotecaEjerciciosProvider);
    final ejercicio = _ejercicio;

    return FormularioCentrado(
      seccion: SeccionDeNavegacion.inicio,
      titulo: widget.esEdicion ? 'Editar ejercicio' : 'Añadir ejercicio',
      subtitulo: 'Bloque de ${widget.bloque.tipo.etiqueta}',
      hijos: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        biblioteca.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              AvisoEnLinea(mensaje: mensajeDeErrorPlanificacion(error)),
          data: (todos) {
            if (todos.where((e) => e.estado.esActivo).isEmpty) {
              // CU-08, excepcion: biblioteca vacia.
              return const AvisoEnLinea(
                mensaje:
                    'La biblioteca está vacía. Añade primero algún ejercicio '
                    'para poder planificarlo.',
              );
            }
            return _SelectorEjercicio(
              elegido: ejercicio,
              habilitado: !estado.enCurso,
              error: estado.errorDelCampo('ejercicioId'),
              onElegir: (elegido) {
                controlador.limpiarError();
                setState(() => _ejercicio = elegido);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_orden_ejercicio'),
          controller: _orden,
          enabled: !estado.enCurso,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Posición en el bloque',
            errorText: estado.errorDelCampo('orden'),
          ),
        ),
        if (ejercicio != null) ...[
          const Divider(height: 32),
          // Aqui esta la exclusion: solo se pinta lo que corresponde al tipo.
          if (ejercicio.tipo.vaPorMinutos)
            _CamposCardio(
              controlador: _minutos,
              habilitado: !estado.enCurso,
              error: estado.errorDelCampo('minutos'),
              onCambio: controlador.limpiarError,
            )
          else
            _CamposFuerza(
              descanso: _descanso,
              series: _series,
              habilitado: !estado.enCurso,
              errorDescanso: estado.errorDelCampo('descansoSeg'),
              errorSeries: estado.errorDelCampo('series'),
              errorRepeticiones: estado.errorDelCampo('repeticiones'),
              errorPeso: estado.errorDelCampo('peso'),
              errorRir: estado.errorDelCampo('rir'),
              onAnadirSerie: () => setState(() {
                _series.add(_FilaSerie.nueva(_series.length + 1));
              }),
              onQuitarSerie: (indice) => setState(() {
                _series.removeAt(indice).dispose();
              }),
              onCambio: controlador.limpiarError,
            ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_guardar_ejercicio_planificado'),
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

/// Campos de un ejercicio de Cardio: solo minutos.
/// Elige el ejercicio de la biblioteca: buscador, filtro muscular y lista.
///
/// Era un `DropdownButtonFormField` con la biblioteca entera dentro. Con veinte
/// ejercicios ya era una lista en la que uno se pierde nada mas abrirla, y es
/// la pantalla que el entrenador repite una vez por ejercicio de cada bloque.
///
/// Con uno ya elegido **no se pinta la lista**, solo lo elegido y un boton para
/// cambiarlo: al editar, lo que importa de esta pantalla son las series, no
/// volver a buscar el ejercicio.
class _SelectorEjercicio extends ConsumerWidget {
  const _SelectorEjercicio({
    required this.elegido,
    required this.habilitado,
    required this.error,
    required this.onElegir,
  });

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ejercicio.nombre, style: textos.titleSmall),
                      Text(
                        [
                          ?ejercicio.resumenMuscular,
                          ejercicio.tipo.etiqueta,
                        ].join(' · '),
                        style: textos.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('cambiar_ejercicio'),
                  onPressed: habilitado ? () => onElegir(null) : null,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ejercicio.tipo.descripcionPlanificacion,
            style: textos.bodySmall,
          ),
        ],
      );
    }

    final filtrados = ref.watch(
      ejerciciosFiltradosProvider(AmbitoDeFiltro.formularioBloque),
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
        FiltroDeEjercicios(
          ambito: AmbitoDeFiltro.formularioBloque,
          habilitado: habilitado,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          // Acotada a proposito: dentro de un formulario que ya se desplaza,
          // una lista sin limite empuja los demas campos fuera de la pantalla.
          constraints: const BoxConstraints(maxHeight: _altoMaximoLista),
          child: filtrados.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                AvisoEnLinea(mensaje: mensajeDeErrorPlanificacion(error)),
            data: (lista) => lista.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Ningún ejercicio coincide con la búsqueda.',
                      style: textos.bodySmall,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, indice) {
                      final ejercicio = lista[indice];
                      return Tarjeta(
                        key: Key('elegir_ejercicio_${ejercicio.id}'),
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
                                  Text(
                                    ejercicio.nombre,
                                    style: textos.titleSmall,
                                  ),
                                  Text(
                                    [
                                      ?ejercicio.resumenMuscular,
                                      ejercicio.tipo.etiqueta,
                                    ].join(' · '),
                                    style: textos.bodySmall,
                                  ),
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
                  ),
          ),
        ),
      ],
    );
  }
}

class _CamposCardio extends StatelessWidget {
  const _CamposCardio({
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
      Text('Cardio', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        'Se planifica con minutos. Las series no aplican.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('campo_minutos'),
        controller: controlador,
        enabled: habilitado,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        onChanged: (_) => onCambio(),
        decoration: InputDecoration(labelText: 'Minutos *', errorText: error),
      ),
    ],
  );
}

/// Campos de un ejercicio de Fuerza: descanso y tabla de series.
class _CamposFuerza extends StatelessWidget {
  const _CamposFuerza({
    required this.descanso,
    required this.series,
    required this.habilitado,
    required this.onAnadirSerie,
    required this.onQuitarSerie,
    required this.onCambio,
    this.errorDescanso,
    this.errorSeries,
    this.errorRepeticiones,
    this.errorPeso,
    this.errorRir,
  });

  final TextEditingController descanso;
  final List<_FilaSerie> series;
  final bool habilitado;
  final String? errorDescanso;
  final String? errorSeries;
  final String? errorRepeticiones;
  final String? errorPeso;
  final String? errorRir;
  final VoidCallback onAnadirSerie;
  final ValueChanged<int> onQuitarSerie;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fuerza', style: textos.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Se planifica con series. Los minutos no aplican.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('campo_descanso'),
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
              key: const Key('boton_anadir_serie'),
              onPressed: habilitado ? onAnadirSerie : null,
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
        for (var i = 0; i < series.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text('${i + 1}', style: textos.labelLarge),
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: Key('campo_peso_$i'),
                    controller: series[i].peso,
                    enabled: habilitado,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => onCambio(),
                    decoration: InputDecoration(
                      labelText: 'Peso',
                      isDense: true,
                      errorText: i == 0 ? errorPeso : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('campo_reps_$i'),
                    controller: series[i].repeticiones,
                    enabled: habilitado,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onCambio(),
                    decoration: InputDecoration(
                      labelText: 'Reps *',
                      isDense: true,
                      errorText: i == 0 ? errorRepeticiones : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('campo_rir_$i'),
                    controller: series[i].rir,
                    enabled: habilitado,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onCambio(),
                    decoration: InputDecoration(
                      labelText: 'RIR',
                      isDense: true,
                      helperText: i == 0 ? '0-10' : null,
                      errorText: i == 0 ? errorRir : null,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('quitar_serie_$i'),
                  tooltip: 'Quitar serie',
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  // Siempre debe quedar al menos una serie.
                  onPressed: habilitado && series.length > 1
                      ? () => onQuitarSerie(i)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Los tres controladores de texto de una fila de serie.
class _FilaSerie {
  _FilaSerie({
    required this.repeticiones,
    required this.peso,
    required this.rir,
  });

  factory _FilaSerie.nueva(int numero) => _FilaSerie(
    repeticiones: TextEditingController(),
    peso: TextEditingController(),
    rir: TextEditingController(),
  );

  factory _FilaSerie.desde(DatosSerie datos) => _FilaSerie(
    repeticiones: TextEditingController(text: datos.repeticiones.toString()),
    peso: TextEditingController(
      text: datos.peso == null
          ? ''
          : (datos.peso == datos.peso!.roundToDouble()
                ? datos.peso!.toStringAsFixed(0)
                : datos.peso!.toStringAsFixed(2)),
    ),
    rir: TextEditingController(text: datos.rir?.toString() ?? ''),
  );

  final TextEditingController repeticiones;
  final TextEditingController peso;
  final TextEditingController rir;

  void dispose() {
    repeticiones.dispose();
    peso.dispose();
    rir.dispose();
  }
}
