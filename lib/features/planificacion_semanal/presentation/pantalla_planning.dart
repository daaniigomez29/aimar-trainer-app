import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/dialogos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/formularios_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/tarjeta_sesion.dart';

/// La semana completa: sesiones, bloques y ejercicios (CU-06 a CU-16).
///
/// La misma pantalla sirve al cliente en modo lectura: RLS le deja ver su propio
/// planning, y aqui simplemente no se le ofrece ninguna accion de escritura. Un
/// planning archivado tampoco admite cambios, ni para el entrenador.
class PantallaPlanning extends ConsumerWidget {
  const PantallaPlanning({required this.planningId, super.key});

  final String planningId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esEntrenador = ref.watch(rolActualProvider)?.esEntrenador ?? false;
    final planning = ref.watch(planningCompletoProvider(planningId));
    ref.watch(controladorPlanificacionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning semanal'),
        actions: [
          if (esEntrenador && planning.value != null) ...[
            IconButton(
              tooltip: planning.requireValue.estado.esActivo
                  ? 'Archivar'
                  : 'Reactivar',
              icon: Icon(
                planning.requireValue.estado.esActivo
                    ? Icons.inventory_2_outlined
                    : Icons.unarchive_outlined,
              ),
              onPressed: () => alternarArchivadoPlanning(
                context: context,
                ref: ref,
                planning: planning.requireValue,
              ),
            ),
            IconButton(
              key: const Key('boton_eliminar_planning'),
              tooltip: 'Eliminar planning',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final eliminado = await confirmarEliminarPlanning(
                  context: context,
                  ref: ref,
                  planning: planning.requireValue,
                );
                if (eliminado && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(planningCompletoProvider(planningId)),
          ),
        ],
      ),
      body: planning.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensajeDeErrorPlanificacion(error),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(planningCompletoProvider(planningId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (datos) => _Semana(
          planning: datos,
          // Un planning archivado es de solo lectura, tambien para el entrenador.
          puedeEditar: esEntrenador && datos.esEditable,
          // Solo el cliente registra, y solo sobre un planning activo: es lo que
          // exige la politica de `series_realizadas`.
          puedeRegistrar: !esEntrenador && datos.estado.esActivo,
        ),
      ),
    );
  }
}

class _Semana extends ConsumerWidget {
  const _Semana({
    required this.planning,
    required this.puedeEditar,
    required this.puedeRegistrar,
  });

  final PlanningSemanal planning;
  final bool puedeEditar;
  final bool puedeRegistrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Cabecera(planning: planning, puedeEditar: puedeEditar),
        const Divider(height: 24),
        // Una sesion por fila, numeradas: ya no hay dias de la semana que
        // mostrar, porque la sesion no cae en ninguno.
        for (final sesion in planning.sesionesOrdenadas)
          _FilaSesion(
            sesion: sesion,
            planning: planning,
            puedeEditar: puedeEditar,
            puedeRegistrar: puedeRegistrar,
          ),
        if (puedeEditar && planning.esEditable) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('boton_anadir_sesion'),
              onPressed: () => pedirDatosSesion(
                context: context,
                ref: ref,
                planning: planning,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Añadir día ${planning.siguienteOrden}'),
            ),
          ),
        ],
        if (planning.sesiones.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              puedeEditar
                  ? 'Añade la primera sesión para empezar.'
                  : 'Esta semana no tiene sesiones.',
              style: textos.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _Cabecera extends ConsumerWidget {
  const _Cabecera({required this.planning, required this.puedeEditar});

  final PlanningSemanal planning;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = planning.sesiones
        .expand((s) => s.bloques)
        .expand((b) => b.ejercicios)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Del ${_comoFecha(planning.fechaInicio)} '
                'al ${_comoFecha(planning.fechaFin)}',
                style: textos.titleLarge,
              ),
            ),
            if (puedeEditar)
              IconButton(
                tooltip: 'Editar planning',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await pedirDatosPlanning(
                    context: context,
                    ref: ref,
                    clienteId: planning.clienteId,
                    planning: planning,
                  );
                  ref.invalidate(planningCompletoProvider(planning.id));
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (planning.nombreObjetivo case final objetivo?)
              Chip(label: Text(objetivo)),
            Chip(
              avatar: Icon(
                planning.estado.esActivo
                    ? Icons.play_circle_outline
                    : Icons.inventory_2_outlined,
                size: 18,
              ),
              label: Text(planning.estado.etiqueta),
            ),
            Chip(
              label: Text(
                '${planning.sesiones.length} '
                '${planning.sesiones.length == 1 ? "sesion" : "sesiones"} · '
                '$ejercicios ${ejercicios == 1 ? "ejercicio" : "ejercicios"}',
              ),
            ),
          ],
        ),
        if (!planning.esEditable) ...[
          const SizedBox(height: 8),
          Text(
            'Archivado: solo consulta. Reactivalo para poder modificarlo.',
            style: textos.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Una sesion de la semana, numerada.
class _FilaSesion extends ConsumerWidget {
  const _FilaSesion({
    required this.sesion,
    required this.planning,
    required this.puedeEditar,
    required this.puedeRegistrar,
  });

  final SesionEntrenamiento sesion;
  final PlanningSemanal planning;
  final bool puedeEditar;
  final bool puedeRegistrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final actual = sesion;
    // Esta pantalla la usan los dos roles y el planning cuelga de sitios
    // distintos (`/cliente/planning/:id` y `/entrenador/clientes/:id/...`), así
    // que las rutas hijas se construyen sobre aquella por la que se ha llegado.
    final rutaDeEstePlanning = GoRouterState.of(context).uri.path;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Día ${sesion.orden}',
                style: textos.titleSmall?.copyWith(color: esquema.primary),
              ),
              const Spacer(),
              if (sesion.fechaRealizada case final hecha?)
                Text('Hecha el ${_comoFecha(hecha)}', style: textos.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          TarjetaSesion(
            sesion: actual,
            planning: planning,
            puedeEditar: puedeEditar,
            onRegistrar: !puedeRegistrar
                ? null
                : () => context.go(
                    Rutas.registroDeSesion(planning.id, actual.id),
                  ),
            onAnadirBloque: () => pedirDatosBloque(
              context: context,
              ref: ref,
              sesion: actual,
              planningId: planning.id,
            ),
            onEditarSesion: () => pedirDatosSesion(
              context: context,
              ref: ref,
              planning: planning,
              sesion: actual,
            ),
            onEliminarSesion: () => confirmarEliminarSesion(
              context: context,
              ref: ref,
              sesion: actual,
              planningId: planning.id,
            ),
            onEditarBloque: (bloque) => pedirDatosBloque(
              context: context,
              ref: ref,
              sesion: actual,
              planningId: planning.id,
              bloque: bloque,
            ),
            onEliminarBloque: (bloque) => confirmarEliminarBloque(
              context: context,
              ref: ref,
              bloque: bloque,
              planningId: planning.id,
            ),
            onAnadirEjercicio: (bloque) => context.go(
              Rutas.nuevoEjercicioEnBloque(rutaDeEstePlanning, bloque.id),
            ),
            onEditarEjercicio: (bloque, ejercicio) => context.go(
              Rutas.editarEjercicioDelBloque(
                rutaDeEstePlanning,
                bloque.id,
                ejercicio.id,
              ),
            ),
            onEliminarEjercicio: (ejercicio) => confirmarEliminarEjercicio(
              context: context,
              ref: ref,
              ejercicio: ejercicio,
              planningId: planning.id,
            ),
            // Solo si se puede editar: en un planning archivado o en la vista
            // del cliente no hay asa que arrastrar.
            onMoverBloque: !puedeEditar
                ? null
                : (desde, hasta) => moverBloque(
                    context: context,
                    ref: ref,
                    sesion: actual,
                    planningId: planning.id,
                    desde: desde,
                    hasta: hasta,
                  ),
            onMoverEjercicio: !puedeEditar
                ? null
                : (bloque, desde, hasta) => moverEjercicio(
                    context: context,
                    ref: ref,
                    bloque: bloque,
                    planningId: planning.id,
                    desde: desde,
                    hasta: hasta,
                  ),
          ),
        ],
      ),
    );
  }
}

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
