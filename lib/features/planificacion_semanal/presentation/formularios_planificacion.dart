import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';

/// Formularios cortos de la planificacion, en dialogo: crear/editar planning,
/// sesion y bloque. El de ejercicio planificado va en pantalla propia porque su
/// formulario de series no cabe en un dialogo.

/// CU-05 / CU-09: crear o editar un planning.
///
/// [semana] es la que se propone al crear. Quien abre el dialogo desde una
/// semana concreta debe pasarla: si el entrenador ha navegado al 19-25 para
/// adelantar trabajo, proponerle la semana de hoy le obliga a corregir la fecha
/// cada vez.
///
/// Devuelve el planning guardado, o `null` si se cancelo o fallo.
Future<PlanningSemanal?> pedirDatosPlanning({
  required BuildContext context,
  required WidgetRef ref,
  required String clienteId,
  PlanningSemanal? planning,
  Semana? semana,
}) async {
  ref.read(controladorPlanificacionProvider.notifier).reiniciar();
  return showDialog<PlanningSemanal>(
    context: context,
    builder: (_) => _DialogoPlanning(
      clienteId: clienteId,
      planning: planning,
      semana: semana,
    ),
  );
}

class _DialogoPlanning extends ConsumerStatefulWidget {
  const _DialogoPlanning({required this.clienteId, this.planning, this.semana});

  final String clienteId;
  final PlanningSemanal? planning;
  final Semana? semana;

  @override
  ConsumerState<_DialogoPlanning> createState() => _EstadoDialogoPlanning();
}

class _EstadoDialogoPlanning extends ConsumerState<_DialogoPlanning> {
  late final TextEditingController _objetivo;
  late Semana _semana;

  @override
  void initState() {
    super.initState();
    _objetivo = TextEditingController(
      text: widget.planning?.nombreObjetivo ?? '',
    );
    // Al editar manda la del planning; al crear, la que venga de la pantalla y,
    // si no viene ninguna, la de hoy.
    _semana = switch (widget.planning) {
      final previo? => Semana.de(previo.fechaInicio),
      null => widget.semana ?? Semana.deHoy(),
    };
  }

  @override
  void dispose() {
    _objetivo.dispose();
    super.dispose();
  }

  /// El calendario elige dias, pero el planning es de una semana: se guarda la
  /// semana del dia elegido. Tocar el jueves 22 deja "del 19 al 25", que es lo
  /// que el entrenador queria decir.
  Future<void> _elegirSemana() async {
    final elegido = await showDatePicker(
      context: context,
      initialDate: _semana.lunes,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
      helpText: 'Un día de la semana',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegido != null) setState(() => _semana = Semana.de(elegido));
  }

  Future<void> _guardar() async {
    final datos = DatosPlanning(
      clienteId: widget.clienteId,
      fechaInicio: _semana.lunes,
      nombreObjetivo: _objetivo.text,
    );
    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final previo = widget.planning;

    final resultado = previo == null
        ? await controlador.crearPlanning(datos)
        : await controlador.editarPlanning(id: previo.id, datos: datos);

    if (!mounted || resultado.esFallo) return;
    Navigator.of(context).pop(resultado.valorONulo);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorPlanificacionProvider);

    return AlertDialog(
      title: Text(
        widget.planning == null ? 'Nuevo planning' : 'Editar planning',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (estado.errorGeneral case final mensaje?) ...[
            Text(
              mensaje,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            key: const Key('boton_fecha_inicio'),
            onPressed: estado.enCurso ? null : _elegirSemana,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              'Del ${_comoFecha(_semana.lunes)} '
              'al ${_comoFecha(_semana.domingo)}',
            ),
          ),
          if (estado.errorDelCampo('fechaInicio') case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('campo_objetivo'),
            controller: _objetivo,
            enabled: !estado.enCurso,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Objetivo de la semana',
              helperText: 'Opcional. Por ejemplo, "Volumen" o "Descarga".',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_guardar_planning'),
          onPressed: estado.enCurso ? null : _guardar,
          child: Text(widget.planning == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}

/// CU-06 / CU-10: crear o editar una sesion en una fecha de la semana.
/// CU-06 / CU-10: crear o editar una sesion.
///
/// Ya no pide dia: la sesion se numera sola dentro del planning. Lo unico que
/// escribe el entrenador es el nombre.
Future<bool> pedirDatosSesion({
  required BuildContext context,
  required WidgetRef ref,
  required PlanningSemanal planning,
  SesionEntrenamiento? sesion,
}) async {
  ref.read(controladorPlanificacionProvider.notifier).reiniciar();
  final guardado = await showDialog<bool>(
    context: context,
    builder: (_) => _DialogoSesion(planning: planning, sesion: sesion),
  );
  return guardado ?? false;
}

class _DialogoSesion extends ConsumerStatefulWidget {
  const _DialogoSesion({required this.planning, this.sesion});

  final PlanningSemanal planning;
  final SesionEntrenamiento? sesion;

  @override
  ConsumerState<_DialogoSesion> createState() => _EstadoDialogoSesion();
}

class _EstadoDialogoSesion extends ConsumerState<_DialogoSesion> {
  late final TextEditingController _nombre;

  /// Al crear, el numero que toca; al editar, el que ya tenia.
  late final int _orden =
      widget.sesion?.orden ?? widget.planning.siguienteOrden;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.sesion?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final datos = DatosSesion(
      planningId: widget.planning.id,
      orden: _orden,
      nombre: _nombre.text,
    );
    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final previa = widget.sesion;

    final resultado = previa == null
        ? await controlador.crearSesion(datos: datos, planning: widget.planning)
        : await controlador.editarSesion(
            id: previa.id,
            datos: datos,
            planning: widget.planning,
          );

    if (!mounted || resultado.esFallo) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorPlanificacionProvider);
    final controlador = ref.read(controladorPlanificacionProvider.notifier);

    return AlertDialog(
      title: Text(widget.sesion == null ? 'Nueva sesión' : 'Editar sesión'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (estado.errorGeneral case final mensaje?) ...[
            Text(
              mensaje,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          // El dia no se elige: es el numero que le toca dentro del planning.
          // Se muestra para que el entrenador sepa que esta creando.
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Día $_orden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Las sesiones van numeradas, no atadas a un día de la semana: el '
            'cliente la hace cuando puede.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('campo_nombre_sesion'),
            controller: _nombre,
            enabled: !estado.enCurso,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => controlador.limpiarError(),
            decoration: InputDecoration(
              labelText: 'Nombre *',
              helperText: 'Por ejemplo, "Empuje" o "Pierna".',
              errorText: estado.errorDelCampo('nombre'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_guardar_sesion'),
          onPressed: estado.enCurso ? null : _guardar,
          child: Text(widget.sesion == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}

/// CU-07 / CU-11: crear o editar un bloque.
Future<bool> pedirDatosBloque({
  required BuildContext context,
  required WidgetRef ref,
  required SesionEntrenamiento sesion,
  required String planningId,
  BloqueEjercicio? bloque,
}) async {
  ref.read(controladorPlanificacionProvider.notifier).reiniciar();
  final guardado = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _DialogoBloque(sesion: sesion, planningId: planningId, bloque: bloque),
  );
  return guardado ?? false;
}

class _DialogoBloque extends ConsumerStatefulWidget {
  const _DialogoBloque({
    required this.sesion,
    required this.planningId,
    this.bloque,
  });

  final SesionEntrenamiento sesion;
  final String planningId;
  final BloqueEjercicio? bloque;

  @override
  ConsumerState<_DialogoBloque> createState() => _EstadoDialogoBloque();
}

class _EstadoDialogoBloque extends ConsumerState<_DialogoBloque> {
  late final TextEditingController _notas;
  late TipoBloque _tipo;
  late int _orden;

  @override
  void initState() {
    super.initState();
    _notas = TextEditingController(text: widget.bloque?.notas ?? '');
    _tipo = widget.bloque?.tipo ?? TipoBloque.fuerza;
    _orden = widget.bloque?.orden ?? widget.sesion.bloques.length + 1;
  }

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final datos = DatosBloque(
      sesionId: widget.sesion.id,
      tipo: _tipo,
      orden: _orden,
      notas: _notas.text,
    );
    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final previo = widget.bloque;

    final resultado = previo == null
        ? await controlador.crearBloque(
            datos: datos,
            sesion: widget.sesion,
            planningId: widget.planningId,
          )
        : await controlador.editarBloque(
            id: previo.id,
            datos: datos,
            sesion: widget.sesion,
            planningId: widget.planningId,
          );

    if (!mounted || resultado.esFallo) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorPlanificacionProvider);
    final controlador = ref.read(controladorPlanificacionProvider.notifier);
    final posiciones = widget.sesion.bloques.length + 1;

    return AlertDialog(
      title: Text(widget.bloque == null ? 'Nuevo bloque' : 'Editar bloque'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (estado.errorGeneral case final mensaje?) ...[
            Text(
              mensaje,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<TipoBloque>(
            key: const Key('selector_tipo_bloque'),
            initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo *'),
            items: [
              for (final tipo in TipoBloque.values)
                DropdownMenuItem(value: tipo, child: Text(tipo.etiqueta)),
            ],
            onChanged: estado.enCurso
                ? null
                : (tipo) => setState(() => _tipo = tipo ?? _tipo),
          ),
          const SizedBox(height: 16),
          // Solo las posiciones realmente disponibles: no se puede elegir una
          // ocupada, que el indice unico rechazaria.
          DropdownButtonFormField<int>(
            key: const Key('selector_orden_bloque'),
            initialValue: _orden <= posiciones ? _orden : posiciones,
            decoration: InputDecoration(
              labelText: 'Posición en la sesión',
              errorText: estado.errorDelCampo('orden'),
            ),
            items: [
              for (var i = 1; i <= posiciones; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: estado.enCurso
                ? null
                : (orden) {
                    controlador.limpiarError();
                    setState(() => _orden = orden ?? _orden);
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('campo_notas_bloque'),
            controller: _notas,
            enabled: !estado.enCurso,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas',
              helperText: 'Opcional. Indicaciones para el cliente.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_guardar_bloque'),
          onPressed: estado.enCurso ? null : _guardar,
          child: Text(widget.bloque == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
