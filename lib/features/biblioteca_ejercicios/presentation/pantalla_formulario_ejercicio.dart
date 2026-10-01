import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

/// CU-02 (anadir) y CU-03 (editar) ejercicio.
///
/// Con `ejercicio` a `null` crea uno nuevo; con un ejercicio, precarga sus datos.
class PantallaFormularioEjercicio extends ConsumerStatefulWidget {
  const PantallaFormularioEjercicio({this.ejercicio, super.key});

  final Ejercicio? ejercicio;

  bool get esEdicion => ejercicio != null;

  @override
  ConsumerState<PantallaFormularioEjercicio> createState() =>
      _EstadoPantallaFormularioEjercicio();
}

class _EstadoPantallaFormularioEjercicio
    extends ConsumerState<PantallaFormularioEjercicio> {
  late final TextEditingController _nombre;
  late final TextEditingController _grupoMuscular;
  late final TextEditingController _equipamiento;
  late final TextEditingController _descripcion;
  late final TextEditingController _video;
  late TipoEjercicio _tipo;

  @override
  void initState() {
    super.initState();
    final e = widget.ejercicio;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _grupoMuscular = TextEditingController(text: e?.grupoMuscular ?? '');
    _equipamiento = TextEditingController(text: e?.equipamiento ?? '');
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    _video = TextEditingController(text: e?.videoEjemploUrl ?? '');
    _tipo = e?.tipo ?? TipoEjercicio.fuerza;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _grupoMuscular.dispose();
    _equipamiento.dispose();
    _descripcion.dispose();
    _video.dispose();
    super.dispose();
  }

  DatosEjercicio get _datos => DatosEjercicio(
    nombre: _nombre.text,
    descripcion: _descripcion.text,
    tipo: _tipo,
    grupoMuscular: _grupoMuscular.text,
    equipamiento: _equipamiento.text,
    videoEjemploUrl: _video.text,
  );

  Future<void> _guardar() async {
    final guardado = await ref
        .read(controladorFormularioEjercicioProvider.notifier)
        .guardar(datos: _datos, id: widget.ejercicio?.id);

    if (!mounted || guardado == null) return;
    Navigator.of(context).pop(guardado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.esEdicion
              ? 'Ejercicio actualizado.'
              : 'Ejercicio anadido a la biblioteca.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorFormularioEjercicioProvider);
    final controlador = ref.read(
      controladorFormularioEjercicioProvider.notifier,
    );

    return FormularioCentrado(
      titulo: widget.esEdicion ? 'Editar ejercicio' : 'Nuevo ejercicio',
      hijos: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('campo_nombre'),
          controller: _nombre,
          enabled: !estado.enCurso,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Nombre *',
            errorText: estado.errorDelCampo('nombre'),
          ),
        ),
        const SizedBox(height: 16),
        _SelectorTipo(
          key: const Key('selector_tipo'),
          valor: _tipo,
          habilitado: !estado.enCurso,
          onCambio: (tipo) => setState(() => _tipo = tipo),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_grupo_muscular'),
          controller: _grupoMuscular,
          enabled: !estado.enCurso,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Grupo muscular',
            helperText: 'Opcional. Sirve para filtrar el listado.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_equipamiento'),
          controller: _equipamiento,
          enabled: !estado.enCurso,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Equipamiento',
            helperText: 'Opcional.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_descripcion'),
          controller: _descripcion,
          enabled: !estado.enCurso,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Descripcion *',
            helperText: 'Tecnica de ejecucion. La ve el cliente.',
            errorText: estado.errorDelCampo('descripcion'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_video'),
          controller: _video,
          enabled: !estado.enCurso,
          keyboardType: TextInputType.url,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Video de ejemplo',
            helperText: 'Opcional. Enlace http(s).',
            errorText: estado.errorDelCampo('videoEjemploUrl'),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_guardar_ejercicio'),
          onPressed: estado.enCurso ? null : _guardar,
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.esEdicion ? 'Guardar cambios' : 'Anadir ejercicio'),
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

/// Selector de Fuerza/Cardio. Obligatorio y sin valor vacio: el tipo determina
/// como se planificara el ejercicio en la fase 4.
class _SelectorTipo extends StatelessWidget {
  const _SelectorTipo({
    required this.valor,
    required this.onCambio,
    required this.habilitado,
    super.key,
  });

  final TipoEjercicio valor;
  final ValueChanged<TipoEjercicio> onCambio;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Tipo *', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      SegmentedButton<TipoEjercicio>(
        segments: [
          for (final tipo in TipoEjercicio.values)
            ButtonSegment(
              value: tipo,
              label: Text(tipo.etiqueta),
              icon: Icon(
                tipo.esFuerza ? Icons.fitness_center : Icons.directions_run,
              ),
            ),
        ],
        selected: {valor},
        onSelectionChanged: habilitado
            ? (seleccion) => onCambio(seleccion.first)
            : null,
      ),
      const SizedBox(height: 4),
      Text(
        valor.descripcionPlanificacion,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
