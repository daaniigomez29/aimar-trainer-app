import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Una sesion con sus bloques y los ejercicios de cada bloque.
///
/// Recibe los callbacks en lugar de llamar a los controladores: asi este widget no
/// depende de Riverpod y se puede probar con acciones falsas.
class TarjetaSesion extends StatelessWidget {
  const TarjetaSesion({
    required this.sesion,
    required this.planning,
    required this.puedeEditar,
    required this.onAnadirBloque,
    required this.onEditarSesion,
    required this.onEliminarSesion,
    required this.onEditarBloque,
    required this.onEliminarBloque,
    required this.onAnadirEjercicio,
    required this.onEditarEjercicio,
    required this.onEliminarEjercicio,
    this.onRegistrar,
    super.key,
  });

  final SesionEntrenamiento sesion;
  final PlanningSemanal planning;
  final bool puedeEditar;
  final VoidCallback onAnadirBloque;
  final VoidCallback onEditarSesion;
  final VoidCallback onEliminarSesion;
  final ValueChanged<BloqueEjercicio> onEditarBloque;
  final ValueChanged<BloqueEjercicio> onEliminarBloque;
  final ValueChanged<BloqueEjercicio> onAnadirEjercicio;
  final void Function(BloqueEjercicio, EjercicioPlanificado) onEditarEjercicio;
  final ValueChanged<EjercicioPlanificado> onEliminarEjercicio;

  /// Solo lo recibe el cliente, para registrar su resultado (CU-20). El
  /// entrenador planifica; registrar es cosa de quien entrena.
  final VoidCallback? onRegistrar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      key: Key('sesion_${sesion.id}'),
      margin: const EdgeInsets.only(top: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(sesion.nombre, style: textos.titleMedium)),
                if (sesion.resultadoRegistrado)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: 'El cliente ya registro el resultado',
                      child: Icon(Icons.task_alt, size: 20),
                    ),
                  ),
                if (puedeEditar) ...[
                  IconButton(
                    tooltip: 'Editar sesion',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEditarSesion,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    key: Key('eliminar_sesion_${sesion.id}'),
                    tooltip: 'Eliminar sesion',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onEliminarSesion,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (sesion.bloques.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  puedeEditar
                      ? 'Sin bloques todavia.'
                      : 'Esta sesion aun no tiene contenido.',
                  style: textos.bodySmall,
                ),
              )
            else
              for (final bloque in sesion.bloques)
                _Bloque(
                  bloque: bloque,
                  puedeEditar: puedeEditar,
                  onEditar: () => onEditarBloque(bloque),
                  onEliminar: () => onEliminarBloque(bloque),
                  onAnadirEjercicio: () => onAnadirEjercicio(bloque),
                  onEditarEjercicio: (ejercicio) =>
                      onEditarEjercicio(bloque, ejercicio),
                  onEliminarEjercicio: onEliminarEjercicio,
                ),
            if (onRegistrar != null && sesion.bloques.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  key: Key('registrar_sesion_${sesion.id}'),
                  onPressed: onRegistrar,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(
                    sesion.resultadoRegistrado
                        ? 'Revisar lo registrado'
                        : 'Registrar resultado',
                  ),
                ),
              ),
            if (puedeEditar)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('anadir_bloque_${sesion.id}'),
                  onPressed: onAnadirBloque,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Anadir bloque'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.bloque,
    required this.puedeEditar,
    required this.onEditar,
    required this.onEliminar,
    required this.onAnadirEjercicio,
    required this.onEditarEjercicio,
    required this.onEliminarEjercicio,
  });

  final BloqueEjercicio bloque;
  final bool puedeEditar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onAnadirEjercicio;
  final ValueChanged<EjercicioPlanificado> onEditarEjercicio;
  final ValueChanged<EjercicioPlanificado> onEliminarEjercicio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Container(
      key: Key('bloque_${bloque.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${bloque.orden}. ${bloque.tipo.etiqueta}',
                style: textos.labelLarge,
              ),
              const Spacer(),
              if (puedeEditar) ...[
                IconButton(
                  tooltip: 'Editar bloque',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEditar,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  key: Key('eliminar_bloque_${bloque.id}'),
                  tooltip: 'Eliminar bloque',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onEliminar,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          if (bloque.notas case final notas?)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(notas, style: textos.bodySmall),
            ),
          for (final ejercicio in bloque.ejercicios)
            _Ejercicio(
              ejercicio: ejercicio,
              puedeEditar: puedeEditar,
              onEditar: () => onEditarEjercicio(ejercicio),
              onEliminar: () => onEliminarEjercicio(ejercicio),
            ),
          if (puedeEditar)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('anadir_ejercicio_${bloque.id}'),
                onPressed: onAnadirEjercicio,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Anadir ejercicio'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ejercicio extends StatelessWidget {
  const _Ejercicio({
    required this.ejercicio,
    required this.puedeEditar,
    required this.onEditar,
    required this.onEliminar,
  });

  final EjercicioPlanificado ejercicio;
  final bool puedeEditar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final nombre = ejercicio.ejercicio?.nombre ?? 'Ejercicio';

    return Padding(
      key: Key('ejercicio_planificado_${ejercicio.id}'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 6),
            child: Icon(Icons.drag_indicator, size: 14),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ejercicio.orden}. $nombre', style: textos.bodyMedium),
                Text(_resumen(ejercicio), style: textos.bodySmall),
              ],
            ),
          ),
          if (puedeEditar) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 16),
              onPressed: onEditar,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              key: Key('eliminar_ejercicio_${ejercicio.id}'),
              tooltip: 'Quitar del bloque',
              icon: const Icon(Icons.close, size: 16),
              onPressed: onEliminar,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  /// Resumen en una linea: series para Fuerza, minutos para Cardio.
  static String _resumen(EjercicioPlanificado ejercicio) {
    if (ejercicio.minutosPlanificados case final minutos?) {
      return '${_sinDecimalSobrante(minutos)} min';
    }
    if (ejercicio.series.isEmpty) return 'Sin series planificadas';

    final partes = [
      for (final serie in ejercicio.series)
        [
          '${serie.repeticionesPlanificadas}',
          if (serie.pesoPlanificado case final peso?)
            '${_sinDecimalSobrante(peso)}kg',
          if (serie.rirPlanificado case final rir?) 'RIR$rir',
        ].join(' '),
    ];
    final descanso = ejercicio.descansoPlanificadoSeg;
    return [
      '${ejercicio.series.length}x: ${partes.join(' | ')}',
      if (descanso != null) 'descanso ${descanso}s',
    ].join(' · ');
  }

  static String _sinDecimalSobrante(double valor) =>
      valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);
}
