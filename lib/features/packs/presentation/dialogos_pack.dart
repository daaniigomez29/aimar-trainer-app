import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/application/controlador_packs.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';

/// Crear un pack o cambiarle el nombre.
///
/// Es un dialogo y no una pantalla porque son dos campos. Los ejercicios se
/// anaden despues, en la ficha del pack, igual que una sesion del planning se
/// crea vacia y se llena luego.
///
/// **El tipo no se puede cambiar al editar**: todos los ejercicios del pack son
/// de ese tipo (lo impone un trigger), asi que cambiarlo dejaria dentro
/// ejercicios que no encajan. Para eso se hace otro pack.
Future<Pack?> pedirDatosPack({
  required BuildContext context,
  required WidgetRef ref,
  Pack? pack,
}) {
  ref.read(controladorPacksProvider.notifier).reiniciar();
  return showDialog<Pack>(
    context: context,
    builder: (_) => _DialogoPack(pack: pack),
  );
}

class _DialogoPack extends ConsumerStatefulWidget {
  const _DialogoPack({this.pack});

  final Pack? pack;

  @override
  ConsumerState<_DialogoPack> createState() => _EstadoDialogoPack();
}

class _EstadoDialogoPack extends ConsumerState<_DialogoPack> {
  late final TextEditingController _nombre;
  late TipoEjercicio _tipo;

  bool get _esEdicion => widget.pack != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.pack?.nombre ?? '');
    _tipo = widget.pack?.tipo ?? TipoEjercicio.fuerza;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final controlador = ref.read(controladorPacksProvider.notifier);
    final datos = DatosPack(nombre: _nombre.text, tipo: _tipo);
    final resultado = _esEdicion
        ? await controlador.editar(id: widget.pack!.id, datos: datos)
        : await controlador.crear(datos);

    if (!mounted || resultado.esFallo) return;
    Navigator.of(context).pop(resultado.valorONulo);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorPacksProvider);
    final controlador = ref.read(controladorPacksProvider.notifier);

    return AlertDialog(
      title: Text(_esEdicion ? 'Editar el pack' : 'Nuevo pack'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (estado.errorGeneral case final mensaje?) ...[
            AvisoEnLinea(mensaje: mensaje),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('campo_nombre_pack'),
            controller: _nombre,
            autofocus: true,
            enabled: !estado.enCurso,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => controlador.limpiarError(),
            onSubmitted: (_) => _guardar(),
            decoration: InputDecoration(
              labelText: 'Nombre *',
              errorText: estado.errorDelCampo('nombre'),
            ),
          ),
          const SizedBox(height: 16),
          if (_esEdicion)
            // El tipo se ensena, pero no se toca.
            Row(
              children: [
                Icon(_tipo.icono, size: 18, color: _tipo.color),
                const SizedBox(width: 8),
                Text(_tipo.etiqueta),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El tipo no se cambia: sus ejercicios son de este tipo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            )
          else
            DropdownButtonFormField<TipoEjercicio>(
              key: const Key('selector_tipo_pack'),
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo *'),
              items: [
                for (final tipo in TipoEjercicio.values)
                  DropdownMenuItem(
                    value: tipo,
                    child: Row(
                      children: [
                        Icon(tipo.icono, size: 18, color: tipo.color),
                        const SizedBox(width: 8),
                        Text(tipo.etiqueta),
                      ],
                    ),
                  ),
              ],
              onChanged: estado.enCurso
                  ? null
                  : (valor) => setState(() => _tipo = valor ?? _tipo),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_guardar_pack'),
          onPressed: estado.enCurso ? null : _guardar,
          child: Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

/// Borra el pack entero, con sus ejercicios y lo que tuvieran preparado.
///
/// Es un borrado fisico, como el de un planning: un pack es una plantilla y no
/// tiene historico que conservar. **Lo ya planificado no se toca**: al aplicar
/// un pack se copió, y esa copia es del planning.
Future<bool> confirmarEliminarPack({
  required BuildContext context,
  required WidgetRef ref,
  required Pack pack,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      icon: const Icon(Icons.warning_amber_outlined),
      title: const Text('Eliminar el pack'),
      content: Text(
        'Se eliminará "${pack.nombre}"'
        '${pack.ejercicios.isEmpty ? '' : ' con sus ${pack.ejercicios.length} '
                  '${pack.ejercicios.length == 1 ? 'ejercicio' : 'ejercicios'}'}.'
        '\n\nLo que ya hayas planificado con él no se toca.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_confirmar_eliminar_pack'),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return false;

  final resultado = await ref
      .read(controladorPacksProvider.notifier)
      .eliminar(pack.id);
  if (!context.mounted) return resultado.esExito;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Avisos.duracion,
      content: Text(
        resultado.esExito
            ? 'Pack eliminado.'
            : (resultado.errorONulo?.mensaje ??
                  'No se ha podido eliminar el pack.'),
      ),
    ),
  );
  return resultado.esExito;
}

/// Quitar un ejercicio del pack. No toca la biblioteca.
Future<bool> confirmarQuitarDelPack({
  required BuildContext context,
  required WidgetRef ref,
  required PackEjercicio ejercicio,
  required String packId,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      icon: const Icon(Icons.warning_amber_outlined),
      title: const Text('Quitar del pack'),
      content: Text(
        'Se quitará "${ejercicio.ejercicio?.nombre ?? 'este ejercicio'}" del '
        'pack, con lo que tuviera preparado. El ejercicio sigue en la '
        'biblioteca.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_confirmar_quitar_del_pack'),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: const Text('Quitar'),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return false;

  final resultado = await ref
      .read(controladorPacksProvider.notifier)
      .eliminarEjercicio(id: ejercicio.id, packId: packId);
  if (!context.mounted) return resultado.esExito;

  if (resultado.esFallo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Avisos.duracion,
        content: Text(
          resultado.errorONulo?.mensaje ?? 'No se ha podido quitar.',
        ),
      ),
    );
  }
  return resultado.esExito;
}
