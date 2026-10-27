import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
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
/// Las **etiquetas de tipo** son varias, al menos una, y se pueden cambiar
/// tambien al editar: desde el 2026-10-27 son solo descriptivas y no limitan
/// que ejercicios admite el pack (antes el tipo era uno, mandaba sobre los
/// ejercicios y no se podia tocar).
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
  late Set<TipoEjercicio> _tipos;

  bool get _esEdicion => widget.pack != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.pack?.nombre ?? '');
    _tipos = {...?widget.pack?.tipos};
    if (_tipos.isEmpty) _tipos.add(TipoEjercicio.fuerza);
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final controlador = ref.read(controladorPacksProvider.notifier);
    final datos = DatosPack(nombre: _nombre.text, tipos: _tipos);
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
          Text('Tipos *', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tipo in TipoEjercicio.values)
                ChipFiltro(
                  key: Key('tipo_pack_${tipo.name}'),
                  etiqueta: tipo.etiqueta,
                  icono: tipo.icono,
                  activo: _tipos.contains(tipo),
                  onPulsar: estado.enCurso
                      ? () {}
                      : () {
                          controlador.limpiarError();
                          setState(() {
                            // Se puede dejar sin ninguno mientras se elige; el
                            // "al menos uno" lo dice la validacion al guardar.
                            _tipos.contains(tipo)
                                ? _tipos.remove(tipo)
                                : _tipos.add(tipo);
                          });
                        },
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (estado.errorDelCampo('tipos') case final error?)
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            )
          else
            Text(
              'Para reconocerlo en la lista: puede llevar ejercicios de '
              'cualquier tipo.',
              style: Theme.of(context).textTheme.bodySmall,
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
