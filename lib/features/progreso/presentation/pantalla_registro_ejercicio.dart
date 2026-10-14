import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/boton_atras.dart';
import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';

import 'package:aimar_trainer_app/core/plataforma/reproductor_video.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/video_ejemplo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_registro_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';

/// Registro del resultado de un ejercicio (CU-20, `docs/ui-design.md` 6.2).
///
/// Cada serie tiene su propio check. Confirmar una envia **la lista completa de
/// series confirmadas**, no solo esa: asi la llamada es idempotente y corregir
/// una serie anterior la actualiza en su sitio, no anade otra.
///
/// Lo planificado por el entrenador se pinta en ambar y no se puede editar aqui;
/// lo que el cliente escribe va en los campos. Son datos independientes por
/// regla de dominio, y el color es lo que lo hace evidente.
class PantallaRegistroEjercicio extends ConsumerStatefulWidget {
  const PantallaRegistroEjercicio({
    required this.ejercicio,
    required this.planningId,
    required this.clienteId,
    this.sesion,
    super.key,
  });

  final EjercicioPlanificado ejercicio;
  final String planningId;
  final String clienteId;

  /// Si llega, la cabecera puede decir "Ejercicio 2 de 5" y el CTA encadena con
  /// el siguiente. Sin ella la pantalla funciona igual, solo que suelta.
  final SesionEntrenamiento? sesion;

  @override
  ConsumerState<PantallaRegistroEjercicio> createState() =>
      _PantallaRegistroEjercicioState();
}

class _PantallaRegistroEjercicioState
    extends ConsumerState<PantallaRegistroEjercicio> {
  /// Un juego de campos por serie, indexado por numero de serie.
  final Map<int, _CamposSerie> _campos = {};

  /// Series ya confirmadas en esta pantalla, por numero. Se rellena en
  /// `_prepararEjercicio`, no en la declaracion: al encadenar ejercicios hay
  /// que rehacerla.
  ///
  /// Es lo que enciende el check verde, y se **vacia al editar** esa serie: a
  /// partir de ahi lo que hay escrito ya no es lo guardado.
  final Map<int, DatosSerieRealizada> _confirmadas = {};

  /// Series que han llegado a guardarse alguna vez en esta pantalla.
  ///
  /// POR QUE NO VALE `_confirmadas` PARA ESTO: desde que el check se apaga al
  /// editar, "sin check" ya no significa "no registrada". Y lo que decide si
  /// una serie de mas se puede quitar es si existe en la base de datos, no si
  /// el check esta encendido: `series_realizadas` no tiene `delete`, asi que
  /// quitarla de la pantalla la dejaria registrada y sin verse.
  final Set<int> _guardadas = {};

  final _minutos = TextEditingController();

  /// Se registran minutos o series segun el modo del tipo, no segun el tipo:
  /// Fortalecimiento se registra como Fuerza.
  bool get _vaPorMinutos =>
      widget.ejercicio.ejercicio?.tipo.vaPorMinutos ?? false;

  /// Cuantas series se muestran: las planificadas, y al menos tantas como el
  /// cliente haya registrado ya. Lo realizado no tiene que coincidir con lo
  /// planificado.
  int get _totalSeries {
    var maximo = widget.ejercicio.series.length;
    for (final numero in {..._confirmadas.keys, ..._campos.keys}) {
      if (numero > maximo) maximo = numero;
    }
    return maximo;
  }

  @override
  void initState() {
    super.initState();
    _prepararEjercicio();
  }

  /// Rehace los campos cuando cambia el ejercicio **sin cambiar el `State`**.
  ///
  /// POR QUE PASA: al encadenar ejercicios con `context.go`, el widget ocupa el
  /// mismo sitio del arbol y Flutter reutiliza su `State`. Sin esto, el
  /// siguiente ejercicio heredaba los campos del anterior: ensenaba sus series
  /// con el plan del nuevo, y si el anterior era un cardio (que no crea
  /// ninguna) la pantalla reventaba al pedir una serie que no existia.
  ///
  /// El enrutador ademas le pone una clave por ejercicio, asi que normalmente
  /// el `State` se crea de cero; esto es para que la pantalla sea correcta
  /// tambien si alguien la monta sin ella.
  @override
  void didUpdateWidget(covariant PantallaRegistroEjercicio anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.ejercicio.id != widget.ejercicio.id) _prepararEjercicio();
  }

  void _prepararEjercicio() {
    for (final campos in _campos.values) {
      campos.dispose();
    }
    _campos.clear();

    _guardadas
      ..clear()
      ..addAll(widget.ejercicio.seriesRealizadas.map((s) => s.numeroSerie));

    _confirmadas
      ..clear()
      ..addEntries([
        for (final serie in widget.ejercicio.seriesRealizadas)
          MapEntry(
            serie.numeroSerie,
            DatosSerieRealizada(
              numeroSerie: serie.numeroSerie,
              repeticiones: serie.repeticionesRealizadas,
              peso: serie.pesoReal,
              rir: serie.rirReal,
            ),
          ),
      ]);

    for (var numero = 1; numero <= _totalSeries; numero++) {
      _campos[numero] = _CamposSerie.desde(
        confirmada: _confirmadas[numero],
        planificada: _planificadaDe(numero),
        anterior: _confirmadas[numero - 1],
      );
    }

    final minutos =
        widget.ejercicio.minutosRealizados ??
        widget.ejercicio.minutosPlanificados;
    _minutos.text = minutos == null ? '' : _numero(minutos);
  }

  /// Los campos de esa serie, creandolos si faltaran.
  ///
  /// Antes era `_campos[numero]!`, y cualquier desajuste entre lo que se pinta
  /// y lo que hay preparado se convertia en una pantalla roja a mitad del
  /// entrenamiento. Una serie sin campos es recuperable: se crea vacia.
  _CamposSerie _camposDe(int numero) => _campos.putIfAbsent(
    numero,
    () => _CamposSerie.desde(
      confirmada: _confirmadas[numero],
      planificada: _planificadaDe(numero),
      anterior: _confirmadas[numero - 1],
    ),
  );

  @override
  void dispose() {
    for (final campos in _campos.values) {
      campos.dispose();
    }
    _minutos.dispose();
    super.dispose();
  }

  SeriePlanificada? _planificadaDe(int numero) =>
      widget.ejercicio.series.where((s) => s.numeroSerie == numero).firstOrNull;

  Future<void> _confirmarSerie(int numero) async {
    final campos = _camposDe(numero);
    final repeticiones = int.tryParse(campos.repeticiones.text.trim());
    if (repeticiones == null) {
      _avisar('Pon cuántas repeticiones hiciste en la serie $numero.');
      return;
    }

    final serie = DatosSerieRealizada(
      numeroSerie: numero,
      repeticiones: repeticiones,
      peso: double.tryParse(campos.peso.text.trim().replaceAll(',', '.')),
      rir: int.tryParse(campos.rir.text.trim()),
    );
    final pendientes = {..._confirmadas, numero: serie};

    final resultado = await ref
        .read(controladorRegistroSesionProvider.notifier)
        .registrarFuerza(
          ejercicioPlanificadoId: widget.ejercicio.id,
          series: pendientes.values.toList()
            ..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie)),
          planningId: widget.planningId,
        );
    if (!mounted || resultado.esFallo) return;

    setState(() {
      _confirmadas[numero] = serie;
      _guardadas.add(numero);
    });
  }

  /// Apaga el check de una serie ya confirmada en cuanto se toca uno de sus
  /// campos.
  ///
  /// POR QUE: confirmar guarda, pero despues el cliente corrige un peso y el
  /// check seguia verde, diciendo que lo que se ve es lo que esta guardado
  /// cuando ya no lo era. Apagarlo es la senal de "esto lo has cambiado y falta
  /// confirmarlo". Lo guardado antes **no se pierde**: sigue en la base de
  /// datos hasta que se vuelva a confirmar, o se guarde con el boton de
  /// "Guardar y siguiente", que recoge lo escrito aunque no tenga check.
  void _alEditarSerie(int numero) {
    if (!_confirmadas.containsKey(numero)) return;
    setState(() => _confirmadas.remove(numero));
  }

  /// Guarda de golpe lo que haya escrito y pasa al siguiente ejercicio.
  ///
  /// POR QUE: el check verde de cada serie confirma una y deja ver que quedo
  /// guardada, pero no puede ser la **unica** forma de guardar. El cliente
  /// rellena las series, pulsa "Guardar y siguiente ejercicio" y da por hecho
  /// que con eso vale; si no, pierde el entrenamiento sin enterarse.
  ///
  /// Solo entran las series con repeticiones puestas: una fila vacia es una
  /// serie que no se ha hecho, y dejar un ejercicio a medias es valido.
  Future<void> _guardarYSiguiente() async {
    final pendientes = <int, DatosSerieRealizada>{..._confirmadas};
    for (final entrada in _campos.entries) {
      final campos = entrada.value;
      final repeticiones = int.tryParse(campos.repeticiones.text.trim());
      if (repeticiones == null) continue;
      pendientes[entrada.key] = DatosSerieRealizada(
        numeroSerie: entrada.key,
        repeticiones: repeticiones,
        peso: double.tryParse(campos.peso.text.trim().replaceAll(',', '.')),
        rir: int.tryParse(campos.rir.text.trim()),
      );
    }

    // Sin nada que guardar se pasa de largo: el cliente puede saltarse un
    // ejercicio, y avisar de un error aqui seria mentir.
    if (pendientes.isEmpty) {
      _siguiente();
      return;
    }

    final resultado = await ref
        .read(controladorRegistroSesionProvider.notifier)
        .registrarFuerza(
          ejercicioPlanificadoId: widget.ejercicio.id,
          series: pendientes.values.toList()
            ..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie)),
          planningId: widget.planningId,
        );
    if (!mounted || resultado.esFallo) return;

    setState(() {
      _confirmadas
        ..clear()
        ..addAll(pendientes);
      _guardadas.addAll(pendientes.keys);
    });
    _siguiente();
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

    _siguiente();
  }

  /// Pasa al siguiente ejercicio de la sesion.
  ///
  /// Si era el ultimo, **vuelve al planning**, no a la pantalla de la sesion:
  /// el cliente ha terminado y lo que quiere ver es como queda su semana, no la
  /// lista de ejercicios que acaba de completar.
  void _siguiente() {
    final lista = _ejerciciosDeLaSesion;
    final indice = _indiceActual;
    if (lista == null || indice == null || indice + 1 >= lista.length) {
      // Al dia que se acaba de terminar, no al siguiente: ver
      // `Rutas.inicioClienteEnDia`.
      context.go(Rutas.inicioClienteEnDia(widget.sesion?.orden));
      return;
    }

    // Encadenar ejercicios no debe llenar el historial: el atras tiene que
    // llevar de vuelta a donde se empezo, no al ejercicio anterior. Por eso se
    // arrastra el origen de ruta en ruta.
    final sesion = widget.sesion;
    if (sesion == null) return;
    context.go(
      Rutas.conVuelta(
        Rutas.registroDeEjercicio(
          widget.planningId,
          sesion.id,
          lista[indice + 1].id,
        ),
        GoRouterState.of(context).uri.queryParameters[Rutas.paramVolver],
      ),
    );
  }

  List<EjercicioPlanificado>? get _ejerciciosDeLaSesion =>
      widget.sesion?.bloques.expand((b) => b.ejercicios).toList();

  /// El bloque al que salta el siguiente ejercicio, **solo si cambia de
  /// bloque**; `null` si sigue en el mismo o si ya no hay siguiente.
  ///
  /// POR QUE: el entrenamiento se piensa por bloques —calentar, luego fuerza—,
  /// y el cliente no tenia forma de saber que estaba cerrando uno. El boton lo
  /// dice antes de pulsarlo.
  BloqueEjercicio? get _bloqueQueEmpieza {
    final sesion = widget.sesion;
    final lista = _ejerciciosDeLaSesion;
    final indice = _indiceActual;
    if (sesion == null || lista == null || indice == null) return null;
    if (indice + 1 >= lista.length) return null;

    final siguiente = lista[indice + 1];
    if (siguiente.bloqueId == widget.ejercicio.bloqueId) return null;
    return sesion.bloques.where((b) => b.id == siguiente.bloqueId).firstOrNull;
  }

  int? get _indiceActual {
    final lista = _ejerciciosDeLaSesion;
    if (lista == null) return null;
    final indice = lista.indexWhere((e) => e.id == widget.ejercicio.id);
    return indice < 0 ? null : indice;
  }

  /// La nota que el entrenador dejo en el bloque de este ejercicio.
  ///
  /// El diseno la llama "Nota de Aimar". En el modelo no hay notas por
  /// ejercicio: las notas viven en el **bloque** (entidad 4), asi que es esa la
  /// que se muestra.
  String? get _notaDelBloque => widget.sesion?.bloques
      .where((b) => b.ejercicios.any((e) => e.id == widget.ejercicio.id))
      .map((b) => b.notas)
      .firstOrNull;

  void _avisar(String mensaje) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(duration: Avisos.duracion, content: Text(mensaje)));

  void _verVideo(String url) {
    final incrustada = VideoEjemplo.urlIncrustada(url);
    if (incrustada == null || !ReproductorVideo.estaSoportado) {
      _avisar('Ese vídeo no se puede reproducir aquí: $url');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Tokens.margenPantalla),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: ReproductorVideo(url: incrustada),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorRegistroSesionProvider);
    final lista = _ejerciciosDeLaSesion;
    final indice = _indiceActual;

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.inicio,
      appBar: AppBar(
        leading: const BotonAtras(alternativa: Rutas.inicioCliente),
        titleSpacing: 0,
        title: Text(
          lista == null || indice == null
              ? widget.ejercicio.ejercicio?.nombre ?? 'Ejercicio'
              : '${widget.sesion!.nombre} · Ejercicio ${indice + 1} de '
                    '${lista.length}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        actions: [
          if (lista != null && indice != null)
            Padding(
              padding: const EdgeInsets.only(right: Tokens.margenPantalla),
              child: _PuntosDeProgreso(total: lista.length, actual: indice),
            ),
        ],
      ),
      cuerpo: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Tokens.margenPantalla,
            8,
            Tokens.margenPantalla,
            24,
          ),
          children: [
            _Encabezado(ejercicio: widget.ejercicio, onVerVideo: _verVideo),
            const SizedBox(height: Tokens.separacionBloques),
            if (_vaPorMinutos)
              _Cardio(
                controlador: _minutos,
                planificados: widget.ejercicio.minutosPlanificados,
                error: estado.errorDelCampo('minutos'),
              )
            else
              for (var numero = 1; numero <= _totalSeries; numero++) ...[
                _TarjetaSerie(
                  numero: numero,
                  campos: _camposDe(numero),
                  planificada: _planificadaDe(numero),
                  porLado: widget.ejercicio.ejercicio?.pesoPorLado ?? false,
                  confirmada: _confirmadas.containsKey(numero),
                  habilitado: !estado.enCurso,
                  onEditar: () => _alEditarSerie(numero),
                  onConfirmar: () => _confirmarSerie(numero),
                  onQuitar: !estado.enCurso && _sePuedeQuitar(numero)
                      ? () => _quitarSerie(numero)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
            if (!_vaPorMinutos) ...[
              TextButton.icon(
                key: const Key('boton_serie_extra'),
                onPressed: estado.enCurso ? null : _anadirSerieExtra,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir una serie de más'),
              ),
              if (widget.ejercicio.descansoPlanificadoSeg case final descanso?)
                _Descanso(segundos: descanso),
            ],
            if (_notaDelBloque case final nota?) ...[
              const SizedBox(height: Tokens.separacionBloques),
              _NotaDelEntrenador(nota: nota),
            ],
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
      ),
      ctaInferior: SafeArea(
        top: false,
        child: BotonCta(
          key: Key(
            _vaPorMinutos
                ? 'boton_guardar_cardio'
                : 'boton_siguiente_ejercicio',
          ),
          etiqueta: _vaPorMinutos
              ? 'Guardar minutos'
              : switch ((
                  lista != null && indice != null && indice + 1 < lista.length,
                  _bloqueQueEmpieza,
                )) {
                  (true, final bloque?) =>
                    'Guardar y comenzar el bloque ${bloque.tipo.etiqueta}',
                  (true, _) => 'Guardar y siguiente ejercicio',
                  _ => 'Terminar ejercicio',
                },
          cargando: estado.enCurso,
          onPulsar: _vaPorMinutos ? _guardarCardio : _guardarYSiguiente,
        ),
      ),
    );
  }

  /// El cliente puede hacer una serie mas de las previstas: es un dato valido,
  /// no un error que haya que impedir.
  void _anadirSerieExtra() {
    final numero = _totalSeries + 1;
    final previa = _campos[numero - 1];
    setState(() {
      // Basta con crear sus campos: `_totalSeries` cuenta tambien las series
      // que solo existen en el mapa de campos.
      //
      // Se copia lo que hay escrito en la serie anterior, confirmado o no: una
      // serie de mas suele repetir el mismo peso, y lo contrario obliga a
      // teclearlo todo otra vez en mitad del entrenamiento.
      _campos[numero] = _CamposSerie(
        peso: TextEditingController(text: previa?.peso.text ?? ''),
        repeticiones: TextEditingController(
          text: previa?.repeticiones.text ?? '',
        ),
        rir: TextEditingController(text: previa?.rir.text ?? ''),
      );
    });
  }

  /// Si esa serie se puede quitar.
  ///
  /// Las **planificadas no**: las pone el entrenador y el cliente no decide que
  /// desaparezcan de su plan. Las de mas si, mientras no esten confirmadas: una
  /// vez registradas viven en `series_realizadas`, que a proposito no tiene
  /// `delete` (lo registrado es historico, se corrige y no se borra).
  ///
  /// Y solo la **ultima**: quitar una de en medio dejaria un hueco en la
  /// numeracion, y las series se recorren del 1 al total.
  bool _sePuedeQuitar(int numero) =>
      numero == _totalSeries &&
      numero > widget.ejercicio.series.length &&
      !_guardadas.contains(numero);

  void _quitarSerie(int numero) {
    setState(() => _campos.remove(numero)?.dispose());
  }
}

/// Campos de una serie. Se agrupan para poder crearlos y liberarlos juntos.
class _CamposSerie {
  _CamposSerie({
    required this.peso,
    required this.repeticiones,
    required this.rir,
  });

  /// Arranca con lo mejor que haya: lo ya registrado, si no lo planificado, y
  /// si no lo de la serie anterior. Teclear en el gimnasio cuesta.
  factory _CamposSerie.desde({
    required DatosSerieRealizada? confirmada,
    required SeriePlanificada? planificada,
    required DatosSerieRealizada? anterior,
  }) {
    if (confirmada != null) {
      return _CamposSerie(
        peso: TextEditingController(
          text: confirmada.peso == null ? '' : _numero(confirmada.peso!),
        ),
        repeticiones: TextEditingController(text: '${confirmada.repeticiones}'),
        rir: TextEditingController(
          text: confirmada.rir == null ? '' : '${confirmada.rir}',
        ),
      );
    }
    if (planificada != null) {
      return _CamposSerie(
        peso: TextEditingController(
          text: planificada.pesoPlanificado == null
              ? ''
              : _numero(planificada.pesoPlanificado!),
        ),
        repeticiones: TextEditingController(
          text: '${planificada.repeticionesPlanificadas}',
        ),
        rir: TextEditingController(
          text: planificada.rirPlanificado == null
              ? ''
              : '${planificada.rirPlanificado}',
        ),
      );
    }
    return _CamposSerie(
      peso: TextEditingController(
        text: anterior?.peso == null ? '' : _numero(anterior!.peso!),
      ),
      repeticiones: TextEditingController(
        text: anterior == null ? '' : '${anterior.repeticiones}',
      ),
      rir: TextEditingController(
        text: anterior?.rir == null ? '' : '${anterior!.rir}',
      ),
    );
  }

  final TextEditingController peso;
  final TextEditingController repeticiones;
  final TextEditingController rir;

  void dispose() {
    peso.dispose();
    repeticiones.dispose();
    rir.dispose();
  }
}

class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.ejercicio, required this.onVerVideo});

  final EjercicioPlanificado ejercicio;
  final ValueChanged<String> onVerVideo;

  static const double lado = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final ficha = ejercicio.ejercicio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MiniaturaEjercicio(
          ejercicio: ficha,
          lado: lado,
          radio: Tokens.radioTarjeta,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ficha?.resumenMuscular case final musculatura?) ...[
                Pastilla(texto: musculatura, color: Tokens.secundario),
                const SizedBox(height: 8),
              ],
              Text(ficha?.nombre ?? 'Ejercicio', style: textos.titleLarge),
              if (ficha?.videoEjemploUrl case final url?) ...[
                const SizedBox(height: 6),
                InkWell(
                  key: const Key('boton_ver_video'),
                  onTap: () => onVerVideo(url),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 18,
                        color: Tokens.acento,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ver vídeo de ejemplo',
                        style: textos.bodyMedium?.copyWith(
                          color: Tokens.acento,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaSerie extends StatelessWidget {
  const _TarjetaSerie({
    required this.numero,
    required this.campos,
    required this.planificada,
    required this.porLado,
    required this.confirmada,
    required this.habilitado,
    required this.onEditar,
    required this.onConfirmar,
    this.onQuitar,
  });

  final int numero;
  final _CamposSerie campos;
  final SeriePlanificada? planificada;

  /// Si el peso de este ejercicio se cuenta por lado. Solo cambia el texto del
  /// plan: lo que el cliente escribe es el peso de un lado, igual que el plan.
  final bool porLado;
  final bool confirmada;
  final bool habilitado;

  /// Se avisa en cuanto se toca cualquiera de los tres campos, para que la
  /// pantalla apague el check si estaba encendido.
  final VoidCallback onEditar;
  final VoidCallback onConfirmar;

  /// Solo llega en la serie de mas que todavia se puede deshacer; ver
  /// `_sePuedeQuitar`.
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Serie $numero', style: textos.titleMedium),
              const Spacer(),
              // Lo planificado, en ambar y sin posibilidad de editarlo aqui.
              if (planificada case final plan?)
                Text(
                  _resumenPlan(plan, porLado: porLado),
                  style: textos.bodySmall?.copyWith(color: Tokens.secundario),
                ),
              if (onQuitar case final quitar?) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: Key('quitar_serie_$numero'),
                  tooltip: 'Quitar esta serie',
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: quitar,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _CampoSerie(
                  etiqueta: 'Kg',
                  controlador: campos.peso,
                  clave: Key('peso_serie_$numero'),
                  habilitado: habilitado,
                  onCambio: onEditar,
                  decimal: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CampoSerie(
                  etiqueta: 'Reps',
                  controlador: campos.repeticiones,
                  clave: Key('reps_serie_$numero'),
                  habilitado: habilitado,
                  onCambio: onEditar,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CampoSerie(
                  etiqueta: 'RIR',
                  controlador: campos.rir,
                  clave: Key('rir_serie_$numero'),
                  habilitado: habilitado,
                  onCambio: onEditar,
                ),
              ),
              const SizedBox(width: 10),
              _BotonCheck(
                clave: Key('confirmar_serie_$numero'),
                confirmada: confirmada,
                onPulsar: habilitado ? onConfirmar : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _resumenPlan(SeriePlanificada plan, {required bool porLado}) =>
      [
        'Plan: ',
        if (plan.pesoPlanificado case final peso?)
          '${_numero(peso)} kg${porLado ? ' por lado' : ''} × ',
        '${plan.repeticionesPlanificadas}',
        if (plan.rirPlanificado case final rir?) ' · RIR $rir',
      ].join();
}

class _CampoSerie extends StatelessWidget {
  const _CampoSerie({
    required this.etiqueta,
    required this.controlador,
    required this.clave,
    required this.habilitado,
    required this.onCambio,
    this.decimal = false,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final Key clave;
  final bool habilitado;

  /// Se avisa en cada tecla: es lo que apaga el check de una serie ya
  /// confirmada.
  final VoidCallback onCambio;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: textos.labelSmall),
        const SizedBox(height: 4),
        TextField(
          key: clave,
          controller: controlador,
          enabled: habilitado,
          onChanged: (_) => onCambio(),
          textAlign: TextAlign.center,
          style: textos.titleMedium,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
            ),
          ],
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
        ),
      ],
    );
  }
}

class _BotonCheck extends StatelessWidget {
  const _BotonCheck({
    required this.clave,
    required this.confirmada,
    required this.onPulsar,
  });

  final Key clave;
  final bool confirmada;
  final VoidCallback? onPulsar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: Material(
      color: confirmada ? Tokens.exito : Tokens.superficie2,
      borderRadius: BorderRadius.circular(Tokens.radioBoton),
      child: InkWell(
        key: clave,
        onTap: onPulsar,
        borderRadius: BorderRadius.circular(Tokens.radioBoton),
        child: Icon(
          Icons.check,
          color: confirmada ? const Color(0xFF05240F) : Tokens.textoTenue,
        ),
      ),
    ),
  );
}

class _Descanso extends StatelessWidget {
  const _Descanso({required this.segundos});

  final int segundos;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule, size: 16, color: Tokens.textoTenue),
        const SizedBox(width: 6),
        Text(
          'Descanso recomendado: $segundos s entre series',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _NotaDelEntrenador extends StatelessWidget {
  const _NotaDelEntrenador({required this.nota});

  final String nota;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Tokens.acentoSuave,
            child: const Text(
              'A',
              style: TextStyle(color: Tokens.acento, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: textos.bodyMedium,
                children: [
                  const TextSpan(
                    text: 'Nota del entrenador: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: nota,
                    style: const TextStyle(color: Tokens.textoSuave),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cardio extends StatelessWidget {
  const _Cardio({
    required this.controlador,
    required this.planificados,
    required this.error,
  });

  final TextEditingController controlador;
  final double? planificados;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Minutos', style: textos.titleMedium),
              const Spacer(),
              if (planificados case final previstos?)
                Text(
                  'Plan: ${_numero(previstos)} min',
                  style: textos.bodySmall?.copyWith(color: Tokens.secundario),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_minutos'),
            controller: controlador,
            textAlign: TextAlign.center,
            style: textos.headlineSmall,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(suffixText: 'min', errorText: error),
          ),
        ],
      ),
    );
  }
}

/// Puntos de progreso de la cabecera: uno por ejercicio de la sesion.
class _PuntosDeProgreso extends StatelessWidget {
  const _PuntosDeProgreso({required this.total, required this.actual});

  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < total; i++)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            width: i <= actual ? 16 : 10,
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
