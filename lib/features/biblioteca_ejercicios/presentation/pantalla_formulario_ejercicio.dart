import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes_flutter.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/lista_musculos_plegable.dart';

/// CU-02 (añadir) y CU-03 (editar) ejercicio.
///
/// Admite las dos entradas: con `ejercicio` cuando quien navega ya lo tiene
/// cargado, y con `idEjercicio` cuando se llega **por la URL**, que es lo que
/// permite recargar la página sin perder el sitio.
class PantallaFormularioEjercicio extends ConsumerWidget {
  const PantallaFormularioEjercicio({
    this.ejercicio,
    this.idEjercicio,
    super.key,
  });

  final Ejercicio? ejercicio;
  final String? idEjercicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Alta, o edición con el ejercicio ya en la mano.
    if (idEjercicio == null || ejercicio != null) {
      return _FormularioEjercicio(ejercicio: ejercicio);
    }

    return ref
        .watch(ejercicioPorIdProvider(idEjercicio!))
        .when(
          data: (e) => _FormularioEjercicio(ejercicio: e),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(mensajeDeError(error))),
          ),
        );
  }
}

class _FormularioEjercicio extends ConsumerStatefulWidget {
  const _FormularioEjercicio({this.ejercicio});

  final Ejercicio? ejercicio;

  bool get esEdicion => ejercicio != null;

  @override
  ConsumerState<_FormularioEjercicio> createState() =>
      _EstadoPantallaFormularioEjercicio();
}

class _EstadoPantallaFormularioEjercicio
    extends ConsumerState<_FormularioEjercicio> {
  late final TextEditingController _nombre;
  late final TextEditingController _equipamiento;
  late final TextEditingController _descripcion;
  late final TextEditingController _video;
  late TipoEjercicio _tipo;

  /// Clasificacion muscular. El grupo solo se guarda si no hay principal; con
  /// principal se deriva de el (ver `DatosEjercicio.grupoNormalizado`), pero
  /// aqui se mantiene para que el selector de musculos sepa que lista ofrecer.
  GrupoMuscular? _grupo;
  Musculo? _principal;
  List<Musculo> _secundarios = const [];

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
    _equipamiento = TextEditingController(text: e?.equipamiento ?? '');
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    _video = TextEditingController(text: e?.videoEjemploUrl ?? '');
    _tipo = e?.tipo ?? TipoEjercicio.fuerza;
    // El grupo efectivo, no el declarado: al editar un ejercicio con musculo
    // principal el selector tiene que aparecer ya en su grupo.
    _grupo = e?.grupo;
    _principal = e?.musculoPrincipal;
    _secundarios = e?.musculosSecundarios ?? const [];
  }

  @override
  void dispose() {
    _nombre.dispose();
    _equipamiento.dispose();
    _descripcion.dispose();
    _video.dispose();
    super.dispose();
  }

  DatosEjercicio get _datos => DatosEjercicio(
    nombre: _nombre.text,
    descripcion: _descripcion.text,
    tipo: _tipo,
    grupoDeclarado: _grupo,
    musculoPrincipal: _principal,
    musculosSecundarios: _secundarios,
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
      seccion: SeccionDeNavegacion.biblioteca,
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
        _SelectorMusculatura(
          grupo: _grupo,
          principal: _principal,
          secundarios: _secundarios,
          habilitado: !estado.enCurso,
          error: estado.errorDelCampo('musculos'),
          onGrupo: (grupo) => setState(() {
            _grupo = grupo;
            // El principal pertenecia al grupo anterior: dejarlo seria guardar
            // un ejercicio cuyo grupo y cuyo musculo no cuadran.
            if (_principal?.grupo != grupo) _principal = null;
          }),
          onPrincipal: (musculo) => setState(() {
            _principal = musculo;
            // Si estaba como secundario, pasa a principal y se quita de ahi:
            // la base de datos rechaza tenerlo en los dos sitios.
            _secundarios = _secundarios.where((m) => m != musculo).toList();
          }),
          onAlternarSecundario: (musculo) => setState(() {
            _secundarios = _secundarios.contains(musculo)
                ? _secundarios.where((m) => m != musculo).toList()
                : [..._secundarios, musculo];
          }),
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
            labelText: 'Descripción',
            helperText: 'Opcional. Técnica de ejecución. La ve el cliente.',
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

/// Selector de tipo. Obligatorio y sin valor vacio: el tipo determina como se
/// planifica el ejercicio (con series o con minutos).
///
/// Son `ChoiceChip` y no un `SegmentedButton` porque con el tercer tipo
/// ("Fortalecimiento", que es largo) los tres segmentos no caben a lo ancho de
/// un movil, y el boton segmentado no reparte en varias lineas.
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
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tipo in TipoEjercicio.values)
            ChoiceChip(
              key: Key('tipo_${tipo.name}'),
              avatar: Icon(tipo.icono, size: 18),
              label: Text(tipo.etiqueta),
              selected: valor == tipo,
              showCheckmark: false,
              onSelected: habilitado ? (_) => onCambio(tipo) : null,
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        valor.descripcionPlanificacion,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// Clasificacion muscular: grupo, musculo principal y secundarios.
///
/// Los tres son opcionales, y en ese orden: el grupo abre la lista de musculos
/// de ese grupo, y el principal es el que fija el grupo definitivo del
/// ejercicio. Sin principal (cardio, o fortalecimiento de una zona sin mas
/// detalle) se guarda solo el grupo.
///

/// Se usan `DropdownButton` controlados dentro de un `InputDecorator`, y no
/// `DropdownButtonFormField`: este ultimo solo admite `initialValue`, asi que al
/// cambiar de grupo y soltar el principal el desplegable seguiria mostrando el
/// musculo viejo.
class _SelectorMusculatura extends StatelessWidget {
  const _SelectorMusculatura({
    required this.grupo,
    required this.principal,
    required this.secundarios,
    required this.habilitado,
    required this.error,
    required this.onGrupo,
    required this.onPrincipal,
    required this.onAlternarSecundario,
  });

  final GrupoMuscular? grupo;
  final Musculo? principal;
  final List<Musculo> secundarios;
  final bool habilitado;
  final String? error;
  final ValueChanged<GrupoMuscular?> onGrupo;
  final ValueChanged<Musculo?> onPrincipal;
  final ValueChanged<Musculo> onAlternarSecundario;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final deEsteGrupo = grupo == null
        ? const <Musculo>[]
        : Musculo.delGrupo(grupo!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clasificación muscular', style: textos.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Opcional. Es lo que permite filtrar la biblioteca por grupo y por '
          'músculo.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 12),
        _Desplegable<GrupoMuscular>(
          clave: const Key('selector_grupo'),
          etiqueta: 'Grupo muscular',
          valor: grupo,
          habilitado: habilitado,
          sinValor: 'Sin especificar',
          opciones: {for (final g in GrupoMuscular.values) g: g.etiqueta},
          onCambio: onGrupo,
        ),
        const SizedBox(height: 16),
        _Desplegable<Musculo>(
          clave: const Key('selector_musculo_principal'),
          etiqueta: 'Músculo principal',
          ayuda: grupo == null
              ? 'Elige antes un grupo muscular.'
              : 'Déjalo vacío si no hay uno concreto, como en el cardio.',
          valor: principal,
          habilitado: habilitado && grupo != null,
          sinValor: 'Sin músculo principal',
          opciones: {for (final m in deEsteGrupo) m: m.etiquetaCompleta},
          onCambio: onPrincipal,
        ),
        const SizedBox(height: 8),
        // Dos niveles de plegado, y el de fuera cerrado: los seis grupos a la
        // vista alargaban el formulario aunque no se vaya a poner ningun
        // secundario, que es el caso mas comun.
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('secundarios'),
            // Al editar un ejercicio que ya tiene secundarios se abre solo: si
            // no, pareceria que no tiene ninguno.
            initiallyExpanded: secundarios.isNotEmpty,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
            title: Text('Músculos secundarios', style: textos.labelLarge),
            subtitle: Text(
              secundarios.isEmpty
                  ? 'Ninguno'
                  : secundarios.map((m) => m.etiqueta).join(', '),
              style: textos.bodySmall,
            ),
            children: [
              // Se eligen de **toda** la taxonomia, no solo del grupo del
              // principal: en un press de banca el principal es del pecho y
              // los secundarios son deltoides y triceps, de otros dos grupos.
              ListaMusculosPlegable(
                grupos: GrupoMuscular.values,
                musculosDe: Musculo.delGrupo,
                seleccionados: secundarios.toSet(),
                onMusculo: onAlternarSecundario,
                ocultar: {?principal},
                habilitado: habilitado,
                resumenDe: (grupo) {
                  final elegidos = Musculo.delGrupo(grupo)
                      .where(secundarios.contains)
                      .map((m) => m.etiqueta);
                  return elegidos.isEmpty ? '—' : elegidos.join(', ');
                },
              ),
            ],
          ),
        ),
        if (error case final mensaje?) ...[
          const SizedBox(height: 4),
          Text(
            mensaje,
            style: textos.bodySmall?.copyWith(color: Tokens.peligro),
          ),
        ],
      ],
    );
  }
}

/// Desplegable con una opcion "sin valor" al principio, controlado por `valor`.
class _Desplegable<T> extends StatelessWidget {
  const _Desplegable({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    required this.habilitado,
    required this.sinValor,
    required this.opciones,
    required this.onCambio,
    this.ayuda,
  });

  final Key clave;
  final String etiqueta;
  final String? ayuda;
  final T? valor;
  final bool habilitado;
  final String sinValor;
  final Map<T, String> opciones;
  final ValueChanged<T?> onCambio;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      enabled: habilitado,
    ),
    child: DropdownButton<T?>(
      key: clave,
      value: valor,
      isExpanded: true,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: null, child: Text(sinValor)),
        for (final opcion in opciones.entries)
          DropdownMenuItem(
            value: opcion.key,
            child: Text(opcion.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: habilitado ? onCambio : null,
    ),
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
