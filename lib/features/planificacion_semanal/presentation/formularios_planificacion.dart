import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Formularios cortos de la planificacion, en dialogo: crear/editar planning,
/// sesion y bloque. El de ejercicio planificado va en pantalla propia porque su
/// formulario de series no cabe en un dialogo.

/// CU-05 / CU-09: crear o editar un planning.
///
/// Devuelve el planning guardado, o `null` si se cancelo o fallo.
Future<PlanningSemanal?> pedirDatosPlanning({
  required BuildContext context,
  required WidgetRef ref,
  required String clienteId,
  PlanningSemanal? planning,
}) async {
  ref.read(controladorPlanificacionProvider.notifier).reiniciar();
  return showDialog<PlanningSemanal>(
    context: context,
    builder: (_) => _DialogoPlanning(clienteId: clienteId, planning: planning),
  );
}

class _DialogoPlanning extends ConsumerStatefulWidget {
  const _DialogoPlanning({required this.clienteId, this.planning});

  final String clienteId;
  final PlanningSemanal? planning;

  @override
  ConsumerState<_DialogoPlanning> createState() => _EstadoDialogoPlanning();
}

class _EstadoDialogoPlanning extends ConsumerState<_DialogoPlanning> {
  late final TextEditingController _objetivo;
  late DateTime _fechaInicio;

  @override
  void initState() {
    super.initState();
    _objetivo = TextEditingController(
      text: widget.planning?.nombreObjetivo ?? '',
    );
    _fechaInicio = widget.planning?.fechaInicio ?? _lunesDeEstaSemana();
  }

  /// Por defecto, el lunes de la semana en curso: es lo que un entrenador espera
  /// al crear "el planning de esta semana", aunque el dominio no exija lunes.
  static DateTime _lunesDeEstaSemana() {
    final hoy = DateTime.now();
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    return dia.subtract(Duration(days: dia.weekday - 1));
  }

  @override
  void dispose() {
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
      helpText: 'Primer dia de la semana',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegida != null) setState(() => _fechaInicio = elegida);
  }

  Future<void> _guardar() async {
    final datos = DatosPlanning(
      clienteId: widget.clienteId,
      fechaInicio: _fechaInicio,
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
    final fin = _fechaInicio.add(const Duration(days: 6));

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
            onPressed: estado.enCurso ? null : _elegirFecha,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              'Del ${_comoFecha(_fechaInicio)} al ${_comoFecha(fin)}',
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
Future<bool> pedirDatosSesion({
  required BuildContext context,
  required WidgetRef ref,
  required PlanningSemanal planning,
  DateTime? fechaSugerida,
  SesionEntrenamiento? sesion,
}) async {
  ref.read(controladorPlanificacionProvider.notifier).reiniciar();
  final guardado = await showDialog<bool>(
    context: context,
    builder: (_) => _DialogoSesion(
      planning: planning,
      fechaSugerida: fechaSugerida,
      sesion: sesion,
    ),
  );
  return guardado ?? false;
}

class _DialogoSesion extends ConsumerStatefulWidget {
  const _DialogoSesion({
    required this.planning,
    this.fechaSugerida,
    this.sesion,
  });

  final PlanningSemanal planning;
  final DateTime? fechaSugerida;
  final SesionEntrenamiento? sesion;

  @override
  ConsumerState<_DialogoSesion> createState() => _EstadoDialogoSesion();
}

class _EstadoDialogoSesion extends ConsumerState<_DialogoSesion> {
  late final TextEditingController _nombre;
  late DateTime _fecha;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.sesion?.nombre ?? '');
    _fecha =
        widget.sesion?.fecha ??
        widget.fechaSugerida ??
        widget.planning.fechaInicio;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final datos = DatosSesion(
      planningId: widget.planning.id,
      fecha: _fecha,
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
      title: Text(widget.sesion == null ? 'Nueva sesion' : 'Editar sesion'),
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
          // Solo los dias de la semana del planning: asi no se puede elegir una
          // fecha que el trigger rechazaria (CU-06, excepcion).
          DropdownButtonFormField<DateTime>(
            key: const Key('selector_dia_sesion'),
            initialValue: _fecha,
            decoration: InputDecoration(
              labelText: 'Dia *',
              errorText: estado.errorDelCampo('fecha'),
            ),
            items: [
              for (final dia in widget.planning.dias)
                DropdownMenuItem(
                  value: dia,
                  child: Text(
                    '${_nombreDia(dia)} ${_comoFecha(dia)}'
                    '${_ocupadoPor(dia)}',
                  ),
                ),
            ],
            onChanged: estado.enCurso
                ? null
                : (dia) {
                    controlador.limpiarError();
                    if (dia != null) setState(() => _fecha = dia);
                  },
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

  /// Marca en el desplegable los dias que ya tienen sesion.
  String _ocupadoPor(DateTime dia) {
    final ocupada = widget.planning.sesionDe(dia);
    if (ocupada == null || ocupada.id == widget.sesion?.id) return '';
    return '  (ocupado)';
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
              labelText: 'Posicion en la sesion',
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

String _nombreDia(DateTime fecha) => switch (fecha.weekday) {
  DateTime.monday => 'Lun',
  DateTime.tuesday => 'Mar',
  DateTime.wednesday => 'Mie',
  DateTime.thursday => 'Jue',
  DateTime.friday => 'Vie',
  DateTime.saturday => 'Sab',
  _ => 'Dom',
};
