import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/dialogos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/formularios_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_formulario_ejercicio_planificado.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/tarjeta_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_sesion.dart';

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
        // Un dia por fila, con o sin sesion: asi se ve de un vistazo qué dias son
        // de descanso.
        for (final dia in planning.dias)
          _FilaDia(
            dia: dia,
            sesion: planning.sesionDe(dia),
            planning: planning,
            puedeEditar: puedeEditar,
            puedeRegistrar: puedeRegistrar,
          ),
        if (planning.sesiones.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              puedeEditar
                  ? 'Anade una sesion a cualquier dia para empezar.'
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

/// Un dia de la semana, con su sesion si la tiene.
class _FilaDia extends ConsumerWidget {
  const _FilaDia({
    required this.dia,
    required this.sesion,
    required this.planning,
    required this.puedeEditar,
    required this.puedeRegistrar,
  });

  final DateTime dia;
  final SesionEntrenamiento? sesion;
  final PlanningSemanal planning;
  final bool puedeEditar;
  final bool puedeRegistrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final actual = sesion;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_nombreDia(dia)} ${_comoFecha(dia)}',
                style: textos.titleSmall?.copyWith(color: esquema.primary),
              ),
              const Spacer(),
              if (actual == null && puedeEditar)
                TextButton.icon(
                  key: Key('boton_anadir_sesion_${dia.day}'),
                  onPressed: () async {
                    await pedirDatosSesion(
                      context: context,
                      ref: ref,
                      planning: planning,
                      fechaSugerida: dia,
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Anadir sesion'),
                ),
            ],
          ),
          if (actual == null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text('Descanso', style: textos.bodySmall),
            )
          else
            TarjetaSesion(
              sesion: actual,
              planning: planning,
              puedeEditar: puedeEditar,
              onRegistrar: !puedeRegistrar
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PantallaRegistroSesion(
                          planningId: planning.id,
                          sesionId: actual.id,
                          clienteId: planning.clienteId,
                        ),
                      ),
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
              onAnadirEjercicio: (bloque) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PantallaFormularioEjercicioPlanificado(
                    bloque: bloque,
                    planningId: planning.id,
                  ),
                ),
              ),
              onEditarEjercicio: (bloque, ejercicio) =>
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PantallaFormularioEjercicioPlanificado(
                        bloque: bloque,
                        planningId: planning.id,
                        ejercicioPlanificado: ejercicio,
                      ),
                    ),
                  ),
              onEliminarEjercicio: (ejercicio) => confirmarEliminarEjercicio(
                context: context,
                ref: ref,
                ejercicio: ejercicio,
                planningId: planning.id,
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

String _nombreDia(DateTime fecha) => switch (fecha.weekday) {
  DateTime.monday => 'Lunes',
  DateTime.tuesday => 'Martes',
  DateTime.wednesday => 'Miercoles',
  DateTime.thursday => 'Jueves',
  DateTime.friday => 'Viernes',
  DateTime.saturday => 'Sabado',
  _ => 'Domingo',
};
