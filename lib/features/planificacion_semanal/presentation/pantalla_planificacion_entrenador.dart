import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/filtro_de_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/dialogos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/formularios_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/lista_arrastrable.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/navegador_de_semana.dart';

/// Planificacion semanal del entrenador (`docs/ui-design.md`, 6.6 y 6.7).
///
/// Una sola pantalla para escritorio y movil: cambia el armazon (barra lateral y
/// panel de biblioteca fijo frente a barra inferior y modal), no el contenido.
///
/// SOBRE "GUARDAR CAMBIOS": lo que se acumula en local son **solo los valores de
/// las series** (kg, reps, RIR), que se guardan juntos al pulsar el boton. Todo
/// lo demas —crear la semana, anadir o quitar una sesion, un bloque o un
/// ejercicio— se guarda al momento, porque cada una de esas operaciones es
/// atomica por si misma en la base de datos y no tendria sentido dejarla a medias
/// esperando a un boton.
class PantallaPlanificacionEntrenador extends ConsumerStatefulWidget {
  const PantallaPlanificacionEntrenador({super.key});

  @override
  ConsumerState<PantallaPlanificacionEntrenador> createState() =>
      _PantallaPlanificacionEntrenadorState();
}

class _PantallaPlanificacionEntrenadorState
    extends ConsumerState<PantallaPlanificacionEntrenador> {
  String? _clienteId;
  Semana? _semana;
  int? _sesionElegida;

  /// Series editadas y aun sin guardar, por ejercicio planificado.
  final Map<String, List<DatosSerie>> _pendientes = {};

  bool get _haySinGuardar => _pendientes.isNotEmpty;

  /// Trae a [destino] el contenido de otra semana del mismo cliente.
  ///
  /// La copia es solo de lo planificado y deja fuera los ejercicios dados de
  /// baja; el aviso dice cuantos, porque si no quedarian bloques con menos
  /// ejercicios sin ninguna explicacion.
  Future<void> _duplicarAqui({
    required String clienteId,
    required Semana destino,
  }) async {
    final origen = await elegirPlanningParaDuplicar(
      context: context,
      clienteId: clienteId,
      destino: destino,
    );
    if (origen == null || !mounted) return;

    final resultado = await ref
        .read(controladorPlanificacionProvider.notifier)
        .duplicarPlanning(origenId: origen.id, fechaInicio: destino.lunes);
    if (!mounted) return;

    final mensaje = switch (resultado) {
      Failure(:final error) => error.mensaje,
      Success(:final valor) when valor.hayOmitidos =>
        'Semana duplicada. Se han dejado fuera '
            '${valor.ejerciciosOmitidos} '
            '${valor.ejerciciosOmitidos == 1 ? 'ejercicio' : 'ejercicios'} '
            'dados de baja.',
      Success() => 'Semana duplicada.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(duration: Avisos.duracion, content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(listaClientesProvider);
    ref.watch(controladorPlanificacionProvider);

    return clientes.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _Armazon(
        titulo: const Text('Planificación'),
        cuerpo: Center(child: Text(mensajeDeErrorPlanificacion(error))),
      ),
      data: (lista) {
        final activos = lista.where((c) => c.estado.esActivo).toList();
        if (activos.isEmpty) {
          return _Armazon(
            titulo: const Text('Planificación'),
            cuerpo: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Todavía no hay clientes activos a los que planificar.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final cliente =
            activos.where((c) => c.id == _clienteId).firstOrNull ??
            activos.first;
        final semana = _semana ?? Semana.deHoy();

        final planning = _planningDeLaSemana(ref, cliente.id, semana);

        return _Armazon(
          titulo: _SelectorCliente(
            clientes: activos,
            elegido: cliente,
            onElegir: (nuevo) => setState(() {
              _clienteId = nuevo.id;
              _pendientes.clear();
              _sesionElegida = null;
            }),
          ),
          acciones: [
            NavegadorDeSemana(
              semana: semana,
              onCambio: (nueva) => setState(() {
                _semana = nueva;
                _sesionElegida = null;
                _pendientes.clear();
              }),
              // Se duplica **hacia aqui**: el entrenador se pone en la semana
              // que quiere montar y elige de donde traerla. Solo si esta
              // vacia: un planning activo por cliente y semana lo impone el
              // indice unico, y el boton no puede prometer lo contrario.
              tooltipDuplicar: switch ((semana.esPasada, planning)) {
                (true, _) => 'Las semanas que ya han pasado no se tocan',
                (false, null) => 'Traer aquí otra semana',
                (false, _) =>
                  'Esta semana ya tiene planning: duplicar solo cabe en una '
                      'semana vacía',
              },
              onDuplicar: planning == null && !semana.esPasada
                  ? () => _duplicarAqui(clienteId: cliente.id, destino: semana)
                  : null,
            ),
            // Borrar vive aqui y no solo en la ficha del cliente porque es
            // aqui donde se cometen los errores que hay que deshacer: crear
            // la semana sin querer, o duplicar del origen equivocado. Borrar
            // el planning se lleva en cascada sesiones, bloques, ejercicios y
            // series, asi que no hay que deshacer nada a mano.
            if (planning case final actual? when actual.esEditable)
              IconButton(
                key: const Key('boton_eliminar_planning_semana'),
                tooltip: 'Eliminar el planning de esta semana',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => confirmarEliminarPlanning(
                  context: context,
                  ref: ref,
                  planning: actual,
                ),
              ),
          ],
          botonGuardar: _BotonGuardar(
            compacto: !esEscritorio(context),
            habilitado: _haySinGuardar && (planning?.esEditable ?? false),
            onGuardar: () {
              if (planning != null) _guardarSeries(planning);
            },
          ),
          cuerpo: _Semana(
            cliente: cliente,
            semana: semana,
            sesionElegida: _sesionElegida,
            pendientes: _pendientes,
            onElegirSesion: (orden) => setState(() => _sesionElegida = orden),
            onCambiarSeries: (ejercicioId, series) => setState(() {
              // `null` es olvidar lo tecleado: el ejercicio acaba de guardarse
              // desde su formulario, asi que lo pendiente ya no corresponde con
              // lo que hay y se escribiria encima de lo recien guardado.
              if (series == null) {
                _pendientes.remove(ejercicioId);
              } else {
                _pendientes[ejercicioId] = series;
              }
            }),
          ),
        );
      },
    );
  }

  /// El planning de la semana que se esta viendo, ya cargado con su jerarquia.
  /// `null` mientras no exista o aun este cargando.
  PlanningSemanal? _planningDeLaSemana(
    WidgetRef ref,
    String clienteId,
    Semana semana,
  ) {
    final lista = ref.watch(planningsDeClienteProvider(clienteId)).value;
    final deLaSemana = lista
        ?.where((p) => Semana.de(p.fechaInicio) == semana)
        .firstOrNull;
    if (deLaSemana == null) return null;
    return ref.watch(planningCompletoProvider(deLaSemana.id)).value;
  }

  /// Guarda de golpe las series editadas. Cada ejercicio va en su propia llamada
  /// a `guardar_ejercicio_planificado`, que ya es atomica; lo que agrupa el boton
  /// es la edicion, no la transaccion.
  Future<void> _guardarSeries(PlanningSemanal planning) async {
    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final ejercicios = {
      for (final sesion in planning.sesiones)
        for (final bloque in sesion.bloques)
          for (final ejercicio in bloque.ejercicios) ejercicio.id: ejercicio,
    };

    var fallos = 0;
    for (final entrada in Map.of(_pendientes).entries) {
      final ejercicio = ejercicios[entrada.key];
      if (ejercicio == null) continue;

      final bloque = planning.sesiones
          .expand((s) => s.bloques)
          .where((b) => b.id == ejercicio.bloqueId)
          .firstOrNull;
      if (bloque == null) continue;

      final resultado = await controlador.editarEjercicio(
        id: ejercicio.id,
        bloque: bloque,
        datos: DatosEjercicioPlanificado(
          bloqueId: ejercicio.bloqueId,
          ejercicioId: ejercicio.ejercicioId,
          tipoEjercicio: ejercicio.ejercicio?.tipo ?? TipoEjercicio.fuerza,
          orden: ejercicio.orden,
          descansoSeg: ejercicio.descansoPlanificadoSeg,
          minutos: ejercicio.minutosPlanificados,
          series: entrada.value,
        ),
        planningId: planning.id,
      );
      if (resultado.esExito) {
        _pendientes.remove(entrada.key);
      } else {
        fallos++;
      }
    }

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Avisos.duracion,
        content: Text(
          fallos == 0
              ? 'Cambios guardados.'
              : 'No se han podido guardar $fallos ejercicios.',
        ),
      ),
    );
  }
}

/// Barra lateral en escritorio, barra inferior en movil. El contenido es el
/// mismo en los dos casos.
class _Armazon extends StatelessWidget {
  const _Armazon({
    required this.titulo,
    required this.cuerpo,
    this.acciones = const [],
    this.botonGuardar,
  });

  final Widget titulo;
  final Widget cuerpo;
  final List<Widget> acciones;
  final Widget? botonGuardar;

  @override
  Widget build(BuildContext context) {
    final escritorio = esEscritorio(context);

    final barraSuperior = Container(
      decoration: const BoxDecoration(
        color: Tokens.superficie,
        border: Border(bottom: BorderSide(color: Tokens.borde)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.margenPantalla,
        vertical: 10,
      ),
      // En movil no caben las tres cosas en una fila: el selector y el boton
      // arriba, la navegacion de semana debajo.
      child: escritorio
          ? SizedBox(
              height: 52,
              child: Row(
                children: [
                  Text(
                    'AIMAR',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: Tokens.acento, letterSpacing: 2),
                  ),
                  const SizedBox(width: 20),
                  Flexible(child: titulo),
                  const Spacer(),
                  ...acciones,
                  if (botonGuardar case final boton?) ...[
                    const SizedBox(width: 12),
                    boton,
                  ],
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: titulo),
                    const Spacer(),
                    ?botonGuardar,
                  ],
                ),
                if (acciones.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: acciones,
                  ),
              ],
            ),
    );

    final contenido = Column(
      children: [
        barraSuperior,
        Expanded(child: cuerpo),
      ],
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: escritorio
            ? Row(
                children: [
                  const BarraLateral(rutaActual: Rutas.inicioEntrenador),
                  Expanded(child: contenido),
                ],
              )
            : contenido,
      ),
      bottomNavigationBar: escritorio
          ? null
          : const BarraInferior(
              destinos: destinosEntrenador,
              rutaActual: Rutas.inicioEntrenador,
            ),
    );
  }
}

class _SelectorCliente extends StatelessWidget {
  const _SelectorCliente({
    required this.clientes,
    required this.elegido,
    required this.onElegir,
  });

  final List<Cliente> clientes;
  final Cliente elegido;
  final ValueChanged<Cliente> onElegir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return PopupMenuButton<Cliente>(
      key: const Key('selector_cliente'),
      onSelected: onElegir,
      itemBuilder: (context) => [
        for (final cliente in clientes)
          PopupMenuItem(value: cliente, child: Text(cliente.nombre)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Tokens.superficie2,
          borderRadius: BorderRadius.circular(Tokens.radioPastilla),
          border: Border.all(color: Tokens.borde),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Tokens.superficie3,
              child: Text(
                _iniciales(elegido.nombre),
                style: textos.labelSmall?.copyWith(color: Tokens.texto),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                elegido.nombre,
                overflow: TextOverflow.ellipsis,
                style: textos.titleSmall,
              ),
            ),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _BotonGuardar extends ConsumerWidget {
  const _BotonGuardar({
    required this.habilitado,
    required this.onGuardar,
    this.compacto = false,
  });

  final bool habilitado;
  final VoidCallback onGuardar;

  /// En movil, sin nada pendiente, el boton se queda en un icono: el nombre del
  /// cliente es mas importante que repetir "Todo guardado".
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorPlanificacionProvider);

    return FilledButton.icon(
      key: const Key('boton_guardar_cambios'),
      // Deshabilitado cuando no hay nada pendiente: asi el boton dice la verdad
      // sobre si queda algo por guardar.
      onPressed: !habilitado || estado.enCurso ? null : onGuardar,
      icon: Icon(habilitado ? Icons.save_outlined : Icons.check, size: 18),
      label: Text(
        compacto
            ? (habilitado ? 'Guardar' : '')
            : (habilitado ? 'Guardar cambios' : 'Todo guardado'),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: EdgeInsets.symmetric(
          horizontal: compacto && !habilitado ? 10 : 18,
        ),
      ),
    );
  }
}

class _Semana extends ConsumerWidget {
  const _Semana({
    required this.cliente,
    required this.semana,
    required this.sesionElegida,
    required this.pendientes,
    required this.onElegirSesion,
    required this.onCambiarSeries,
  });

  final Cliente cliente;
  final Semana semana;
  final int? sesionElegida;
  final Map<String, List<DatosSerie>> pendientes;
  final ValueChanged<int> onElegirSesion;
  final void Function(String, List<DatosSerie>?) onCambiarSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannings = ref.watch(planningsDeClienteProvider(cliente.id));

    return plannings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(mensajeDeErrorPlanificacion(error))),
      data: (lista) {
        final deLaSemana = lista
            .where((p) => Semana.de(p.fechaInicio) == semana)
            .firstOrNull;

        if (deLaSemana == null) {
          return _SemanaSinPlanning(cliente: cliente, semana: semana);
        }
        return _Planning(
          planningId: deLaSemana.id,
          sesionElegida: sesionElegida,
          pendientes: pendientes,
          onElegirSesion: onElegirSesion,
          onCambiarSeries: onCambiarSeries,
        );
      },
    );
  }
}

class _SemanaSinPlanning extends ConsumerWidget {
  const _SemanaSinPlanning({required this.cliente, required this.semana});

  /// Lo pasado no se crea: ver `PlanningSemanal.esEditable`.

  final Cliente cliente;
  final Semana semana;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 44,
              color: Tokens.textoTenue,
            ),
            const SizedBox(height: 14),
            Text(
              '${cliente.nombre} no tiene planning en la semana '
              'del ${semana.etiqueta}.',
              style: textos.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            if (semana.esPasada)
              Text(
                'Esa semana ya ha pasado y no se puede planificar.',
                style: textos.bodySmall,
                textAlign: TextAlign.center,
              )
            else
              SizedBox(
                width: 240,
                child: BotonCta(
                  key: const Key('boton_crear_planning_semana'),
                  etiqueta: 'Crear la semana',
                  icono: Icons.add,
                  onPulsar: () async {
                    // El dialogo llega con **la semana que se esta viendo**, no
                    // con la de hoy: si el entrenador ha navegado al 19-25 para
                    // adelantar trabajo, es esa la que quiere crear.
                    await pedirDatosPlanning(
                      context: context,
                      ref: ref,
                      clienteId: cliente.id,
                      semana: semana,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Planning extends ConsumerWidget {
  const _Planning({
    required this.planningId,
    required this.sesionElegida,
    required this.pendientes,
    required this.onElegirSesion,
    required this.onCambiarSeries,
  });

  final String planningId;
  final int? sesionElegida;
  final Map<String, List<DatosSerie>> pendientes;
  final ValueChanged<int> onElegirSesion;
  final void Function(String, List<DatosSerie>?) onCambiarSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completo = ref.watch(planningCompletoProvider(planningId));

    return completo.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(mensajeDeErrorPlanificacion(error))),
      data: (planning) {
        // Por defecto, la primera sesion de la semana.
        final sesion =
            planning.sesionNumero(sesionElegida ?? -1) ??
            planning.sesionesOrdenadas.firstOrNull;
        final escritorio = esEscritorio(context);

        // La tira de dias **no se va con el scroll**: es el mando para cambiar
        // de dia, y un dia con tres bloques es mas largo que la pantalla, asi
        // que irse abajo obligaba a subir del todo solo para pasar al Dia 2.
        //
        // Va en un `Column` con la lista dentro de un `Expanded`, y la tira ya
        // trae altura acotada (`SizedBox(height: 44)`): sin eso, un hijo sin
        // acotar dentro de un `Column` revienta (trampa 27).
        final principal = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              // Opaca y con una linea debajo: transparente, el contenido se
              // veria pasar por detras de los chips al desplazar.
              decoration: const BoxDecoration(
                color: Tokens.fondo,
                border: Border(bottom: BorderSide(color: Tokens.borde)),
              ),
              padding: const EdgeInsets.fromLTRB(
                Tokens.margenPantalla,
                Tokens.margenPantalla,
                Tokens.margenPantalla,
                10,
              ),
              child: _PestanasDeSesion(
                planning: planning,
                elegida: sesion?.orden,
                onElegir: onElegirSesion,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.margenPantalla,
                  18,
                  Tokens.margenPantalla,
                  Tokens.margenPantalla,
                ),
                children: [
                  if (sesion == null)
                    _SemanaVacia(
                      planning: planning,
                      onSesionCreada: onElegirSesion,
                    )
                  else
                    _Sesion(
                      sesion: sesion,
                      planning: planning,
                      pendientes: pendientes,
                      onCambiarSeries: onCambiarSeries,
                    ),
                ],
              ),
            ),
          ],
        );

        if (!escritorio) {
          return Stack(
            children: [
              principal,
              // En una semana pasada no se ofrece ni abrir la biblioteca:
              // no habria nada que hacer dentro.
              if (sesion != null && planning.esEditable)
                Positioned(
                  right: Tokens.margenPantalla,
                  bottom: Tokens.margenPantalla,
                  child: FloatingActionButton(
                    key: const Key('boton_abrir_biblioteca'),
                    onPressed: () => _abrirBibliotecaEnModal(
                      context,
                      ref,
                      sesion: sesion,
                      planningId: planning.id,
                      puedeEditar: planning.esEditable,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: principal),
            // Panel fijo de biblioteca: solo en escritorio (ui-design 6.6).
            Container(
              width: 340,
              decoration: const BoxDecoration(
                color: Tokens.superficie,
                border: Border(left: BorderSide(color: Tokens.borde)),
              ),
              child: _PanelBiblioteca(
                sesion: sesion,
                planningId: planning.id,
                puedeEditar: planning.esEditable,
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _abrirBibliotecaEnModal(
  BuildContext context,
  WidgetRef ref, {
  required SesionEntrenamiento sesion,
  required String planningId,
  required bool puedeEditar,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _PanelBiblioteca(
      sesion: sesion,
      planningId: planningId,
      puedeEditar: puedeEditar,
      enModal: true,
    ),
  ),
);

/// Pestanas de las sesiones del planning, con el boton de anadir otra al final.
///
/// Sustituye a las pestanas de dia: una sesion es "Día 1", "Día 2"..., no
/// "miercoles". El entrenador decide **cuantas** sesiones tiene la semana.
class _PestanasDeSesion extends ConsumerWidget {
  const _PestanasDeSesion({
    required this.planning,
    required this.elegida,
    required this.onElegir,
  });

  final PlanningSemanal planning;
  final int? elegida;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesiones = planning.sesionesOrdenadas;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sesiones.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, indice) {
          // El ultimo hueco es el boton de anadir.
          if (indice == sesiones.length) {
            return OutlinedButton.icon(
              key: const Key('boton_anadir_sesion'),
              // Se abre el dia recien creado: el entrenador anade el Dia 3
              // porque va a montarlo, no para seguir mirando el Dia 1.
              onPressed: planning.esEditable
                  ? () async {
                      final creada = await pedirDatosSesion(
                        context: context,
                        ref: ref,
                        planning: planning,
                      );
                      if (creada != null) onElegir(creada.orden);
                    }
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Día ${planning.siguienteOrden}'),
            );
          }

          final sesion = sesiones[indice];
          return ChipFiltro(
            etiqueta: 'Día ${sesion.orden}',
            activo: sesion.orden == elegida,
            onPulsar: () => onElegir(sesion.orden),
          );
        },
      ),
    );
  }
}

class _SemanaVacia extends ConsumerWidget {
  const _SemanaVacia({required this.planning, required this.onSesionCreada});

  final PlanningSemanal planning;

  /// Para abrir el dia recien creado en vez de quedarse en la semana vacia.
  final ValueChanged<int> onSesionCreada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Semana sin sesiones', style: textos.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Añade la primera sesión para empezar a planificar.',
            style: textos.bodySmall,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('boton_primera_sesion'),
            onPressed: planning.esEditable
                ? () async {
                    final creada = await pedirDatosSesion(
                      context: context,
                      ref: ref,
                      planning: planning,
                    );
                    if (creada != null) onSesionCreada(creada.orden);
                  }
                : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir sesión'),
          ),
        ],
      ),
    );
  }
}

class _Sesion extends ConsumerWidget {
  const _Sesion({
    required this.sesion,
    required this.planning,
    required this.pendientes,
    required this.onCambiarSeries,
  });

  final SesionEntrenamiento sesion;
  final PlanningSemanal planning;
  final Map<String, List<DatosSerie>> pendientes;
  final void Function(String, List<DatosSerie>?) onCambiarSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = sesion.bloques.expand((b) => b.ejercicios).length;
    // Lo que hizo el cliente la ultima vez, para planificar mirandolo. Es una
    // ayuda: mientras carga, o si falla, la pantalla funciona igual sin ella.
    final referencias =
        ref
            .watch(referenciasDeSesionProvider(planning.id, sesion.orden))
            .value ??
        const <String, ReferenciaAnterior>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Día ${sesion.orden} · ${sesion.nombre}',
                    style: textos.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$ejercicios ${ejercicios == 1 ? "ejercicio" : "ejercicios"}',
                    style: textos.bodySmall,
                  ),
                ],
              ),
            ),
            // A la derecha del nombre del dia: lo que el cliente hizo se
            // consulta en su propia pantalla, no aqui. Aqui se planifica.
            IconButton(
              key: Key('ver_resultados_${sesion.id}'),
              tooltip: 'Visualizar resultados de la sesión',
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              onPressed: () => context.go(
                Rutas.resultadosDeLaSesion(
                  idCliente: planning.clienteId,
                  planningId: planning.id,
                  orden: sesion.orden,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Editar sesión',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: !planning.esEditable
                  ? null
                  : () => pedirDatosSesion(
                      context: context,
                      ref: ref,
                      planning: planning,
                      sesion: sesion,
                    ),
            ),
            IconButton(
              key: Key('eliminar_sesion_${sesion.id}'),
              tooltip: 'Eliminar sesión',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: !planning.esEditable
                  ? null
                  : () => confirmarEliminarSesion(
                      context: context,
                      ref: ref,
                      sesion: sesion,
                      planningId: planning.id,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListaArrastrable(
          onMover: !planning.esEditable
              ? null
              : (desde, hasta) => moverBloque(
                  context: context,
                  ref: ref,
                  sesion: sesion,
                  planningId: planning.id,
                  desde: desde,
                  hasta: hasta,
                ),
          hijos: [
            for (final (indice, bloque) in sesion.bloques.indexed)
              Padding(
                key: Key('bloque_arrastrable_${bloque.id}'),
                padding: const EdgeInsets.only(bottom: 14),
                child: _Bloque(
                  bloque: bloque,
                  indice: indice,
                  sePuedeMover: sesion.bloques.length > 1,
                  sesion: sesion,
                  planning: planning,
                  pendientes: pendientes,
                  referencias: referencias,
                  onCambiarSeries: onCambiarSeries,
                ),
              ),
          ],
        ),
        OutlinedButton.icon(
          key: Key('anadir_bloque_${sesion.id}'),
          onPressed: !planning.esEditable
              ? null
              : () => pedirDatosBloque(
                  context: context,
                  ref: ref,
                  sesion: sesion,
                  planningId: planning.id,
                ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Añadir bloque'),
        ),
      ],
    );
  }
}

class _Bloque extends ConsumerWidget {
  const _Bloque({
    required this.bloque,
    required this.indice,
    required this.sePuedeMover,
    required this.sesion,
    required this.planning,
    required this.pendientes,
    required this.referencias,
    required this.onCambiarSeries,
  });

  final BloqueEjercicio bloque;
  final int indice;
  final bool sePuedeMover;
  final Map<String, ReferenciaAnterior> referencias;
  final SesionEntrenamiento sesion;
  final PlanningSemanal planning;
  final Map<String, List<DatosSerie>> pendientes;
  final void Function(String, List<DatosSerie>?) onCambiarSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      key: Key('bloque_${bloque.id}'),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AsaDeArrastre(indice: indice, activa: sePuedeMover, tamano: 16),
              const SizedBox(width: 6),
              Text(
                'BLOQUE ${bloque.orden} · ${bloque.tipo.etiqueta.toUpperCase()}',
                style: textos.labelMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Editar bloque',
                icon: const Icon(Icons.edit_outlined, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: !planning.esEditable
                    ? null
                    : () => pedirDatosBloque(
                        context: context,
                        ref: ref,
                        sesion: sesion,
                        planningId: planning.id,
                        bloque: bloque,
                      ),
              ),
              IconButton(
                key: Key('eliminar_bloque_${bloque.id}'),
                tooltip: 'Eliminar bloque',
                icon: const Icon(Icons.delete_outline, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: !planning.esEditable
                    ? null
                    : () => confirmarEliminarBloque(
                        context: context,
                        ref: ref,
                        bloque: bloque,
                        planningId: planning.id,
                      ),
              ),
            ],
          ),
          if (bloque.notas case final notas?) ...[
            const SizedBox(height: 4),
            Text(notas, style: textos.bodySmall),
          ],
          const Divider(height: 20),
          ListaArrastrable(
            onMover: !planning.esEditable
                ? null
                : (desde, hasta) => moverEjercicio(
                    context: context,
                    ref: ref,
                    bloque: bloque,
                    planningId: planning.id,
                    desde: desde,
                    hasta: hasta,
                  ),
            hijos: [
              for (final (indice, ejercicio) in bloque.ejercicios.indexed)
                _EjercicioEditable(
                  key: Key('ejercicio_arrastrable_${ejercicio.id}'),
                  ejercicio: ejercicio,
                  indice: indice,
                  sePuedeMover: bloque.ejercicios.length > 1,
                  bloque: bloque,
                  planning: planning,
                  referencia: referencias[ejercicio.ejercicioId],
                  series: pendientes[ejercicio.id],
                  onCambiarSeries: (series) =>
                      onCambiarSeries(ejercicio.id, series),
                ),
            ],
          ),
          if (bloque.ejercicios.isEmpty)
            Text('Sin ejercicios todavía.', style: textos.bodySmall),
          const SizedBox(height: 8),
          TextButton.icon(
            key: Key('anadir_ejercicio_${bloque.id}'),
            // Mismo caso que el boton de copiar: en una semana pasada abria el
            // formulario para nada, porque guardarlo lo rechazan los triggers.
            onPressed: !planning.esEditable
                ? null
                : () => context.go(
                    Rutas.nuevoEjercicioEnBloque(
                      Rutas.planningEnEdicion(planning.id),
                      bloque.id,
                    ),
                  ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Añadir ejercicio'),
          ),
        ],
      ),
    );
  }
}

/// Un ejercicio con su cuadricula de series editable.
class _EjercicioEditable extends ConsumerStatefulWidget {
  const _EjercicioEditable({
    required this.ejercicio,
    required this.indice,
    required this.sePuedeMover,
    required this.bloque,
    required this.planning,
    required this.referencia,
    required this.series,
    required this.onCambiarSeries,
    super.key,
  });

  final EjercicioPlanificado ejercicio;
  final int indice;
  final bool sePuedeMover;
  final BloqueEjercicio bloque;
  final PlanningSemanal planning;

  /// Lo que el cliente hizo la ultima vez en este ejercicio. `null` si no hay
  /// nada registrado todavia.
  final ReferenciaAnterior? referencia;

  /// Series pendientes de guardar, si ya se han tocado.
  final List<DatosSerie>? series;
  final ValueChanged<List<DatosSerie>?> onCambiarSeries;

  @override
  ConsumerState<_EjercicioEditable> createState() => _EjercicioEditableState();
}

class _EjercicioEditableState extends ConsumerState<_EjercicioEditable> {
  late List<_FilaSerie> _filas;

  @override
  void initState() {
    super.initState();
    _filas = _filasDe(widget.ejercicio.series);
  }

  /// Rehace la cuadricula cuando las series cambian por detras.
  ///
  /// POR QUE HACE FALTA: anadir o quitar una serie se hace en el formulario del
  /// ejercicio, no aqui. Al volver de el, esta pantalla sigue viva y seguiria
  /// ensenando las filas de antes; peor aun, lo que quedara sin guardar aqui se
  /// escribiria encima de lo que se acaba de guardar alli.
  @override
  void didUpdateWidget(_EjercicioEditable anterior) {
    super.didUpdateWidget(anterior);
    if (listEquals(anterior.ejercicio.series, widget.ejercicio.series)) return;

    for (final fila in _filas) {
      fila.dispose();
    }
    setState(() => _filas = _filasDe(widget.ejercicio.series));
    // El aviso al padre cambia su estado, asi que va despues del fotograma.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCambiarSeries(null);
    });
  }

  static List<_FilaSerie> _filasDe(List<SeriePlanificada> series) => [
    for (final serie in series)
      _FilaSerie(
        numero: serie.numeroSerie,
        peso: TextEditingController(
          text: serie.pesoPlanificado == null
              ? ''
              : _numero(serie.pesoPlanificado!),
        ),
        reps: TextEditingController(text: '${serie.repeticionesPlanificadas}'),
        rir: TextEditingController(
          text: serie.rirPlanificado == null ? '' : '${serie.rirPlanificado}',
        ),
      ),
  ];

  /// `null` en una semana que ya no se edita, para que el boton salga
  /// deshabilitado como los de editar y eliminar.
  ///
  /// POR QUE: en una semana pasada se seguia pudiendo pulsar. Rellenaba los
  /// campos con lo que el cliente hizo y despues no habia forma de guardar
  /// —el boton de guardar si estaba deshabilitado—, asi que parecia que el
  /// cambio se habia perdido.
  VoidCallback? get _copiarSiSePuede =>
      widget.planning.esEditable ? _copiarDeLaReferencia : null;

  /// Vuelca lo que el cliente hizo la ultima vez sobre lo planificado.
  ///
  /// Es el punto de partida del entrenador, no el resultado: deja los campos
  /// rellenos para retocarlos, y **no guarda**. Se guarda con el boton de
  /// siempre, igual que si lo hubiera tecleado.
  ///
  /// El numero de series pasa a ser el de lo realizado: si el cliente hizo
  /// cuatro donde habia tres planificadas, se copian las cuatro. Lo planificado
  /// y lo realizado son independientes, pero aqui el entrenador esta pidiendo
  /// explicitamente partir de lo segundo.
  void _copiarDeLaReferencia() {
    final referencia = widget.referencia;
    if (referencia == null || referencia.series.isEmpty) return;

    final nuevas = [
      for (final serie in comoPlanificadas(referencia))
        _FilaSerie(
          numero: serie.numeroSerie,
          peso: TextEditingController(
            text: serie.peso == null ? '' : _numero(serie.peso!),
          ),
          reps: TextEditingController(text: '${serie.repeticiones}'),
          rir: TextEditingController(
            text: serie.rir == null ? '' : '${serie.rir}',
          ),
        ),
    ];

    setState(() {
      for (final fila in _filas) {
        fila.dispose();
      }
      _filas = nuevas;
    });
    _avisarCambio();
  }

  @override
  void dispose() {
    for (final fila in _filas) {
      fila.dispose();
    }
    super.dispose();
  }

  /// Anade una serie a la cuadricula, heredando lo de la anterior.
  ///
  /// POR QUE AQUI: anadir una serie obligaba a abrir el formulario del
  /// ejercicio, y es lo que mas se toca al planificar la semana; el resto de la
  /// cuadricula ya se edita en linea. No guarda: queda como cambio pendiente y
  /// se guarda con el boton de siempre, igual que si se hubiera teclado un peso.
  ///
  /// La serie nueva copia peso, repeticiones y RIR de la ultima, por el mismo
  /// motivo que en el formulario: las series de un ejercicio casi siempre
  /// repiten, y corregir encima es menos trabajo que rellenar de cero.
  void _anadirSerie() {
    final ultima = _filas.lastOrNull;
    setState(() {
      _filas = [
        ..._filas,
        _FilaSerie(
          numero: (ultima?.numero ?? 0) + 1,
          peso: TextEditingController(text: ultima?.peso.text ?? ''),
          reps: TextEditingController(
            text: ultima?.reps.text ?? '$repeticionesPorDefecto',
          ),
          rir: TextEditingController(text: ultima?.rir.text ?? ''),
        ),
      ];
    });
    _avisarCambio();
  }

  /// Quita una fila de la cuadricula, preguntando antes.
  ///
  /// Como al anadir, no guarda: queda pendiente. Y **siempre debe quedar una
  /// serie**, que es lo que exige `DatosEjercicioPlanificado.validar` para un
  /// ejercicio que va por series; por eso el boton de la ultima que queda sale
  /// deshabilitado en lugar de dar un error al guardar.
  Future<void> _quitarSerie(_FilaSerie fila) async {
    final confirmado = await confirmarQuitarSerie(
      context: context,
      numeroSerie: fila.numero,
      conRegistroDelCliente: widget.ejercicio.seriesRealizadas.any(
        (s) => s.numeroSerie == fila.numero,
      ),
    );
    if (!confirmado || !mounted) return;

    setState(() {
      _filas = [..._filas]..remove(fila);
    });
    fila.dispose();
    _avisarCambio();
  }

  void _avisarCambio() => widget.onCambiarSeries([
    for (final fila in _filas)
      DatosSerie(
        numeroSerie: fila.numero,
        repeticiones: int.tryParse(fila.reps.text.trim()) ?? 0,
        peso: double.tryParse(fila.peso.text.trim().replaceAll(',', '.')),
        rir: int.tryParse(fila.rir.text.trim()),
      ),
  ]);

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ficha = widget.ejercicio.ejercicio;
    final vaPorMinutos = ficha?.tipo.vaPorMinutos ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AsaDeArrastre(
                indice: widget.indice,
                activa: widget.sePuedeMover,
                tamano: 14,
              ),
              const SizedBox(width: 4),
              MiniaturaEjercicio(ejercicio: ficha, lado: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ficha?.nombre ?? 'Ejercicio',
                      style: textos.titleSmall,
                    ),
                    Text(
                      [
                        ?ficha?.resumenMuscular,
                        ficha?.tipo.etiqueta ?? '',
                      ].where((t) => t.isNotEmpty).join(' · '),
                      style: textos.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('editar_ejercicio_${widget.ejercicio.id}'),
                tooltip: 'Editar ejercicio',
                icon: const Icon(Icons.edit_outlined, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: !widget.planning.esEditable
                    ? null
                    : () => context.go(
                        Rutas.editarEjercicioDelBloque(
                          Rutas.planningEnEdicion(widget.planning.id),
                          widget.bloque.id,
                          widget.ejercicio.id,
                        ),
                      ),
              ),
              IconButton(
                key: Key('eliminar_ejercicio_${widget.ejercicio.id}'),
                tooltip: 'Quitar del bloque',
                icon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: !widget.planning.esEditable
                    ? null
                    : () => confirmarEliminarEjercicio(
                        context: context,
                        ref: ref,
                        ejercicio: widget.ejercicio,
                        planningId: widget.planning.id,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (vaPorMinutos)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                children: [
                  Text(
                    widget.ejercicio.minutosPlanificados == null
                        ? 'Sin minutos planificados'
                        : '${_numero(widget.ejercicio.minutosPlanificados!)} min',
                    style: textos.bodyMedium?.copyWith(
                      color: Tokens.secundario,
                    ),
                  ),
                  // En Cardio no hay boton de copiar: los minutos no se
                  // editan aqui, se cambian con el boton de editar.
                  if (widget.referencia?.minutos case final minutos?) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_tituloReferencia(widget.referencia!)}: '
                        '${_numero(minutos)} min',
                        style: textos.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, limites) {
                // Con poco ancho, las dos mitades se quedan en nada: lo
                // realizado pasa debajo, en una linea por serie.
                final cabe = limites.maxWidth >= _anchoParaDosMitades;
                final referencia = widget.referencia;
                final hayQueEnsenar = referencia?.series.isNotEmpty ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 44),
                        SizedBox(
                          width: 44,
                          child: Text('Serie', style: textos.labelSmall),
                        ),
                        Expanded(child: Text('Kg', style: textos.labelSmall)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Reps', style: textos.labelSmall)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('RIR', style: textos.labelSmall)),
                        if (hayQueEnsenar && cabe) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _CabeceraReferencia(
                              referencia: referencia!,
                              ejercicioId: widget.ejercicio.id,
                              onCopiar: _copiarSiSePuede,
                            ),
                          ),
                        ],
                      ],
                    ),
                    for (final fila in _filas)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const SizedBox(width: 44),
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${fila.numero}',
                                style: textos.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: _Celda(
                                clave: Key(
                                  'plan_peso_${widget.ejercicio.id}_${fila.numero}',
                                ),
                                controlador: fila.peso,
                                decimal: true,
                                habilitado: widget.planning.esEditable,
                                onCambio: _avisarCambio,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _Celda(
                                clave: Key(
                                  'plan_reps_${widget.ejercicio.id}_${fila.numero}',
                                ),
                                controlador: fila.reps,
                                habilitado: widget.planning.esEditable,
                                onCambio: _avisarCambio,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _Celda(
                                clave: Key(
                                  'plan_rir_${widget.ejercicio.id}_${fila.numero}',
                                ),
                                controlador: fila.rir,
                                habilitado: widget.planning.esEditable,
                                onCambio: _avisarCambio,
                              ),
                            ),
                            if (hayQueEnsenar && cabe) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _serieAnterior(
                                    referencia!.serieNumero(fila.numero),
                                  ),
                                  key: Key(
                                    'anterior_${widget.ejercicio.id}_${fila.numero}',
                                  ),
                                  style: textos.bodyMedium?.copyWith(
                                    color: Tokens.textoSuave,
                                  ),
                                ),
                              ),
                            ],
                            IconButton(
                              key: Key(
                                'quitar_plan_${widget.ejercicio.id}_${fila.numero}',
                              ),
                              tooltip: _filas.length > 1
                                  ? 'Quitar esta serie'
                                  : 'Un ejercicio de series necesita al menos '
                                        'una',
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 16,
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed:
                                  widget.planning.esEditable &&
                                      _filas.length > 1
                                  ? () => _quitarSerie(fila)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    // Series que hizo de mas: se ensenan igual, porque son
                    // informacion para planificar, aunque no haya fila que
                    // rellenar enfrente.
                    if (hayQueEnsenar && cabe)
                      for (final serie in referencia!.series.where(
                        (s) => _filas.every((f) => f.numero != s.numeroSerie),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const SizedBox(width: 44),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '${serie.numeroSerie}',
                                  style: textos.bodyMedium?.copyWith(
                                    color: Tokens.textoTenue,
                                  ),
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                              const SizedBox(width: 8),
                              const Expanded(child: SizedBox()),
                              const SizedBox(width: 8),
                              const Expanded(child: SizedBox()),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _serieAnterior(serie),
                                  style: textos.bodyMedium?.copyWith(
                                    color: Tokens.textoSuave,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    if (hayQueEnsenar && !cabe)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 44),
                        child: _ReferenciaCompacta(
                          referencia: referencia!,
                          ejercicioId: widget.ejercicio.id,
                          onCopiar: _copiarSiSePuede,
                        ),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('anadir_serie_${widget.ejercicio.id}'),
                  onPressed: widget.planning.esEditable ? _anadirSerie : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir serie'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            if (widget.series != null)
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  'Sin guardar',
                  style: textos.labelSmall?.copyWith(color: Tokens.secundario),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Desde este ancho caben las dos mitades, planificado y realizado, una al lado
/// de la otra. Por debajo, lo realizado va en una linea aparte.
const double _anchoParaDosMitades = 560;

/// "Semana pasada" o "Última vez", segun de donde salga el dato. La diferencia
/// importa: no es lo mismo planificar sobre lo de hace siete dias que sobre algo
/// de hace un mes.
String _tituloReferencia(ReferenciaAnterior referencia) =>
    referencia.esSemanaAnterior ? 'Semana pasada' : 'Última vez';

String _conFecha(ReferenciaAnterior referencia) {
  final titulo = _tituloReferencia(referencia);
  final fecha = referencia.fecha;
  return fecha == null ? titulo : '$titulo · ${_comoDiaYMes(fecha)}';
}

String _comoDiaYMes(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';

/// Una serie realizada, en una linea: "60 kg · 10 reps · RIR 2".
String _serieAnterior(SerieRealizada? serie) {
  if (serie == null) return '—';
  return [
    if (serie.pesoReal case final peso?) '${_numero(peso)} kg',
    '${serie.repeticionesRealizadas} reps',
    if (serie.rirReal case final rir?) 'RIR $rir',
  ].join(' · ');
}

/// Cabecera de la mitad derecha: de cuando es lo que se ensena, y el boton que
/// lo copia a lo planificado.
class _CabeceraReferencia extends StatelessWidget {
  const _CabeceraReferencia({
    required this.referencia,
    required this.ejercicioId,
    required this.onCopiar,
  });

  final ReferenciaAnterior referencia;
  final String ejercicioId;

  /// `null` deja el boton deshabilitado y con el motivo en el tooltip.
  final VoidCallback? onCopiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Row(
      children: [
        Flexible(
          child: Text(
            _conFecha(referencia).toUpperCase(),
            style: textos.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          key: Key('copiar_anterior_$ejercicioId'),
          tooltip: onCopiar == null
              ? 'Esta semana ya no se puede editar'
              : 'Copiar a lo planificado',
          icon: const Icon(Icons.west, size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: onCopiar,
        ),
      ],
    );
  }
}

/// Lo mismo cuando no hay ancho para dos mitades: una linea por serie, debajo.
class _ReferenciaCompacta extends StatelessWidget {
  const _ReferenciaCompacta({
    required this.referencia,
    required this.ejercicioId,
    required this.onCopiar,
  });

  final ReferenciaAnterior referencia;
  final String ejercicioId;
  final VoidCallback? onCopiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_conFecha(referencia).toUpperCase(), style: textos.labelSmall),
            const Spacer(),
            TextButton.icon(
              key: Key('copiar_anterior_compacto_$ejercicioId'),
              onPressed: onCopiar,
              icon: const Icon(Icons.west, size: 14),
              label: const Text('Copiar'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        for (final serie in referencia.series)
          Text(
            '${serie.numeroSerie}. ${_serieAnterior(serie)}',
            style: textos.bodySmall,
          ),
      ],
    );
  }
}

class _FilaSerie {
  _FilaSerie({
    required this.numero,
    required this.peso,
    required this.reps,
    required this.rir,
  });

  final int numero;
  final TextEditingController peso;
  final TextEditingController reps;
  final TextEditingController rir;

  void dispose() {
    peso.dispose();
    reps.dispose();
    rir.dispose();
  }
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.clave,
    required this.controlador,
    required this.onCambio,
    this.habilitado = true,
    this.decimal = false,
  });

  final Key clave;
  final TextEditingController controlador;
  final VoidCallback onCambio;

  /// En una semana pasada la cuadricula se lee pero no se escribe: si se
  /// dejara escribir, el boton de guardar estaria apagado y lo tecleado se
  /// perderia sin decir nada.
  final bool habilitado;

  final bool decimal;

  @override
  Widget build(BuildContext context) => TextField(
    key: clave,
    controller: controlador,
    enabled: habilitado,
    textAlign: TextAlign.center,
    onChanged: (_) => onCambio(),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
      ),
    ],
    decoration: const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    ),
  );
}

/// Panel de biblioteca: fijo a la derecha en escritorio, modal en movil.
class _PanelBiblioteca extends ConsumerStatefulWidget {
  const _PanelBiblioteca({
    required this.sesion,
    required this.planningId,
    required this.puedeEditar,
    this.enModal = false,
  });

  final SesionEntrenamiento? sesion;
  final String planningId;

  /// Con la semana pasada se puede mirar la biblioteca, pero no anadir nada:
  /// ver `PlanningSemanal.esEditable`.
  final bool puedeEditar;

  final bool enModal;

  @override
  ConsumerState<_PanelBiblioteca> createState() => _PanelBibliotecaState();
}

class _PanelBibliotecaState extends ConsumerState<_PanelBiblioteca> {
  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = ref.watch(
      ejerciciosFiltradosProvider(AmbitoDeFiltro.panelPlanning),
    );
    final filtro = ref.watch(
      filtroBibliotecaProvider(AmbitoDeFiltro.panelPlanning),
    );

    // `Material` transparente: el panel vive dentro de un contenedor con color
    // de fondo, y los `ExpansionTile` del filtro pintan su tinta sobre el
    // `Material` mas cercano. Sin esto, Flutter avisa de que el fondo tapa esa
    // tinta ("ListTile background color or ink splashes may be invisible") y
    // las pulsaciones no se ven.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.margenPantalla),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.enModal
                        ? 'Añadir ejercicio'
                        : 'Biblioteca de ejercicios',
                    style: textos.titleMedium,
                  ),
                ),
                if (widget.enModal)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Un unico scroll para el filtro y los resultados.
            //
            // POR QUE: el filtro crece al abrir grupos, y como no es flexible,
            // en un `Column` se queda con el alto que pida y deja al
            // `Expanded` de debajo sin sitio. Con dos grupos abiertos el panel
            // desbordaba por abajo ("BOTTOM OVERFLOWED BY 14 PIXELS"). Asi el
            // filtro se desplaza con la lista y no hay alto que repartir.
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Mismo buscador y mismo filtro que el formulario de CU-08,
                  // cada uno con su propio ambito: este panel es donde el
                  // entrenador busca de verdad, una vez por ejercicio de cada
                  // bloque.
                  const FiltroDeEjercicios(
                    ambito: AmbitoDeFiltro.panelPlanning,
                  ),
                  const SizedBox(height: 14),
                  ejercicios.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text(mensajeDeError(error)),
                    data: (lista) {
                      final activos = lista
                          .where((e) => e.estado.esActivo)
                          .toList();
                      if (activos.isEmpty) {
                        return Text(
                          'Ningún ejercicio coincide.',
                          style: textos.bodySmall,
                        );
                      }
                      return ListView.separated(
                        // Dentro del scroll de fuera: se pinta entera y no
                        // desplaza por su cuenta.
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: activos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, indice) => _FilaBiblioteca(
                          ejercicio: activos[indice],
                          resaltar: filtro.musculo,
                          onAnadir: widget.sesion == null || !widget.puedeEditar
                              ? null
                              : () => _anadir(activos[indice]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Anade el ejercicio a un bloque de la sesion.
  ///
  /// Con mas de un bloque se **pregunta a cual**: antes caia siempre en el
  /// primero, y una sesion con calentamiento y fuerza es justo el caso en el
  /// que eso nunca es lo que se quiere. Con uno solo no se pregunta, que seria
  /// un clic de mas sin ninguna decision detras.
  ///
  /// Si la sesion no tiene bloques todavia, no hay donde ponerlo: un ejercicio
  /// planificado cuelga de un bloque (entidad 6), asi que se avisa en lugar de
  /// inventarse uno.
  Future<void> _anadir(Ejercicio ejercicio) async {
    final sesion = widget.sesion!;
    if (sesion.bloques.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Avisos.duracion,
          content: Text(
            'Añade antes un bloque: el ejercicio va dentro de uno.',
          ),
        ),
      );
      return;
    }

    final bloque = sesion.bloques.length == 1
        ? sesion.bloques.first
        : await elegirBloque(
            context: context,
            sesion: sesion,
            ejercicio: ejercicio,
          );
    if (bloque == null || !mounted) return;

    final orden = bloque.ejercicios.length + 1;
    // Valores de partida razonables, que el entrenador ajusta en la cuadricula.
    // Cardio necesita minutos si o si (lo exige un trigger); lo que va por
    // series (Fuerza y Fortalecimiento), las mismas que propone el formulario
    // de CU-08: anadir desde aqui y anadir desde alli tienen que dar lo mismo,
    // o el atajo sale mas caro que el camino largo.
    final vaPorMinutos = ejercicio.tipo.vaPorMinutos;

    final resultado = await ref
        .read(controladorPlanificacionProvider.notifier)
        .crearEjercicio(
          bloque: bloque,
          datos: DatosEjercicioPlanificado(
            bloqueId: bloque.id,
            ejercicioId: ejercicio.id,
            tipoEjercicio: ejercicio.tipo,
            orden: orden,
            minutos: vaPorMinutos ? 20 : null,
            series: vaPorMinutos
                ? const []
                : [
                    for (var i = 1; i <= seriesPorDefecto; i++)
                      DatosSerie(
                        numeroSerie: i,
                        repeticiones: repeticionesPorDefecto,
                      ),
                  ],
          ),
          planningId: widget.planningId,
        );

    if (!mounted) return;
    if (resultado.errorONulo case final error?) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: Avisos.duracion, content: Text(error.mensaje)),
      );
    } else if (widget.enModal) {
      Navigator.of(context).pop();
    }
  }
}

class _FilaBiblioteca extends StatelessWidget {
  const _FilaBiblioteca({
    required this.ejercicio,
    required this.onAnadir,
    this.resaltar,
  });

  final Ejercicio ejercicio;
  final VoidCallback? onAnadir;

  /// Musculo por el que se esta filtrando, para avisar de que este ejercicio
  /// solo lo trabaja de secundario.
  final Musculo? resaltar;

  bool get _esSoloSecundario =>
      resaltar != null &&
      ejercicio.musculoPrincipal != resaltar &&
      ejercicio.musculosSecundarios.contains(resaltar);

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      key: Key('biblioteca_${ejercicio.id}'),
      padding: const EdgeInsets.all(10),
      hijo: Row(
        children: [
          MiniaturaEjercicio(ejercicio: ejercicio, lado: 34),
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
                    if (_esSoloSecundario) 'secundario',
                  ].join(' · '),
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            key: Key('anadir_biblioteca_${ejercicio.id}'),
            tooltip: 'Añadir a la sesión',
            icon: const Icon(Icons.add, size: 18),
            onPressed: onAnadir,
            // En acento, no en el ambar que trae por defecto: aqui el ambar
            // significa "planificado por el entrenador" y usarlo para un boton
            // de accion rompe esa lectura.
            style: IconButton.styleFrom(
              backgroundColor: Tokens.acentoSuave,
              foregroundColor: Tokens.acento,
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
