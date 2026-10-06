import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes_flutter.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
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

  /// Imagen elegida y ya convertida, pendiente de subir al guardar.
  ImagenParaSubir? _imagenNueva;

  /// `true` si el entrenador ha quitado la que habia. Distinto de "no la ha
  /// tocado", que es lo que significa dejarlo todo a `null`.
  bool _imagenQuitada = false;

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
    imagenRuta: widget.ejercicio?.imagenRuta,
  );

  Future<void> _guardar() async {
    final guardado = await ref
        .read(controladorFormularioEjercicioProvider.notifier)
        .guardar(
          datos: _datos,
          id: widget.ejercicio?.id,
          imagenNueva: _imagenNueva,
          quitarImagen: _imagenQuitada,
        );

    if (!mounted || guardado == null) return;
    Navigator.of(context).pop(guardado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Avisos.duracion,
        content: Text(
          widget.esEdicion
              ? 'Ejercicio actualizado.'
              : 'Ejercicio añadido a la biblioteca.',
        ),
      ),
    );
  }

  Future<void> _elegirImagen() async {
    final elegida = await ref.read(servicioImagenesProvider).elegirFoto();
    if (!mounted) return;

    switch (elegida) {
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: Avisos.duracion, content: Text(error.mensaje)),
        );
      case Success(:final valor):
        // `null` es que cerro el selector sin elegir nada.
        if (valor == null) return;
        setState(() {
          _imagenNueva = valor;
          _imagenQuitada = false;
        });
    }
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
            labelText: 'Descripción *',
            helperText: 'Tecnica de ejecución. La ve el cliente.',
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
            labelText: 'Vídeo de ejemplo',
            helperText: 'Opcional. Enlace http(s).',
            errorText: estado.errorDelCampo('videoEjemploUrl'),
          ),
        ),
        const SizedBox(height: 16),
        _Imagen(
          rutaGuardada: _imagenQuitada ? null : widget.ejercicio?.imagenRuta,
          imagenNueva: _imagenNueva,
          habilitado: !estado.enCurso,
          onElegir: _elegirImagen,
          onQuitar: () => setState(() {
            _imagenNueva = null;
            _imagenQuitada = true;
          }),
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
              : Text(widget.esEdicion ? 'Guardar cambios' : 'Añadir ejercicio'),
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

/// Ilustracion del ejercicio: la que ya estaba, la recien elegida, o ninguna.
///
/// La recien elegida se pinta desde memoria (`Image.memory`) porque todavia no
/// se ha subido: subir al elegir dejaria ficheros sueltos en el bucket cada vez
/// que alguien abre el formulario y se arrepiente.
class _Imagen extends ConsumerWidget {
  const _Imagen({
    required this.rutaGuardada,
    required this.imagenNueva,
    required this.habilitado,
    required this.onElegir,
    required this.onQuitar,
  });

  final String? rutaGuardada;
  final ImagenParaSubir? imagenNueva;
  final bool habilitado;
  final VoidCallback onElegir;
  final VoidCallback onQuitar;

  static const double lado = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final nueva = imagenNueva;
    final ruta = rutaGuardada;
    final hayImagen = nueva != null || ruta != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imagen del ejercicio', style: textos.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Opcional. Una ilustración o foto que muestre la ejecución; la ve el '
          'cliente junto a la descripción.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hayImagen)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: lado,
                  height: lado,
                  child: nueva != null
                      ? Image.memory(nueva.bytes, fit: BoxFit.cover)
                      : Image.network(
                          ref
                              .read(ejercicioRepositorioProvider)
                              .urlPublicaDeImagen(ruta!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                ),
              ),
            if (hayImagen) const SizedBox(width: 12),
            // `Expanded` para que los botones tengan un ancho con el que contar:
            // dentro de una `Row`, una `Column` suelta no se lo da.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    key: const Key('boton_elegir_imagen'),
                    onPressed: habilitado ? onElegir : null,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(hayImagen ? 'Cambiar imagen' : 'Elegir imagen'),
                  ),
                  if (hayImagen)
                    TextButton.icon(
                      key: const Key('boton_quitar_imagen'),
                      onPressed: habilitado ? onQuitar : null,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Quitar'),
                    ),
                  if (nueva != null)
                    Text(
                      'Sin subir aun · ${nueva.tamanoKb} KB',
                      style: textos.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
