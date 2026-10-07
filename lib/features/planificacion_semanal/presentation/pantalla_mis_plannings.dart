import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/al_dia_con_el_entrenador.dart';

/// Lo que ve el cliente de su planificacion: sus semanas activas y el historico
/// de las archivadas (CU-23 desde su lado).
///
/// Es solo lectura, y no por omision: la semana se abre con [PantallaPlanning],
/// que decide por rol si ofrece acciones de escritura. Planificar sigue siendo
/// del entrenador, que llega a los mismos plannings desde la ficha del cliente.
class PantallaMisPlannings extends ConsumerWidget {
  const PantallaMisPlannings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannings = ref.watch(misPlanningsProvider);

    return AlDiaConElEntrenador(
      hijo: Scaffold(
        appBar: AppBar(
          title: const Text('Mi planning'),
          actions: [
            IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(misPlanningsProvider),
            ),
          ],
        ),
        body: plannings.when(
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
                    onPressed: () => ref.invalidate(misPlanningsProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (lista) => _Listado(plannings: lista),
        ),
      ),
    );
  }
}

class _Listado extends StatelessWidget {
  const _Listado({required this.plannings});

  final List<PlanningSemanal> plannings;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    if (plannings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'Tu entrenador todavía no te ha preparado ningún planning.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Pueden coexistir varias semanas activas (el indice unico solo impide dos
    // con la misma fecha de inicio), asi que se listan todas, mas recientes
    // primero, en lugar de suponer que hay una sola.
    final activos = plannings.where((p) => p.estado.esActivo).toList();
    final archivados = plannings.where((p) => p.estado.estaArchivado).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'No tienes ninguna semana activa ahora mismo.',
              style: textos.bodyMedium,
            ),
          )
        else
          for (final planning in activos) _SemanaActiva(planning: planning),
        if (archivados.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Semanas anteriores', style: textos.titleSmall),
          const SizedBox(height: 4),
          for (final planning in archivados) _FilaArchivada(planning: planning),
        ],
      ],
    );
  }
}

/// Una semana activa, con lo que toca hoy si la semana incluye el dia de hoy.
class _SemanaActiva extends ConsumerWidget {
  const _SemanaActiva({required this.planning});

  final PlanningSemanal planning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final hoy = DateTime.now();
    final incluyeHoy = planning.contiene(hoy);

    // La lista llega sin sesiones (es una consulta plana), asi que para saber que
    // toca hoy hace falta el planning completo. No es una peticion de mas: es la
    // misma que usara la pantalla de la semana al abrirla.
    final completo = incluyeHoy
        ? ref.watch(planningCompletoProvider(planning.id)).value
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: Key('planning_${planning.id}'),
        onTap: () => context.go(Rutas.planningDelCliente(planning.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Semana del ${_comoFecha(planning.fechaInicio)}'
                      ' al ${_comoFecha(planning.fechaFin)}',
                      style: textos.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (planning.nombreObjetivo case final objetivo?) ...[
                const SizedBox(height: 4),
                Text(objetivo, style: textos.bodySmall),
              ],
              if (incluyeHoy) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.today_outlined,
                      size: 18,
                      color: esquema.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _comoVaLaSemana(completo),
                        style: textos.bodyMedium?.copyWith(
                          color: esquema.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Como va la semana. Ya no se puede hablar de "lo de hoy": las sesiones no
  /// caen en un dia, el cliente las hace cuando puede.
  String _comoVaLaSemana(PlanningSemanal? completo) {
    if (completo == null) return 'Esta es tu semana en curso.';

    final total = completo.sesiones.length;
    if (total == 0) return 'Esta semana aún no tiene sesiones.';

    final hechas = completo.sesiones.where((s) => s.resultadoRegistrado).length;
    if (hechas == total) return 'Semana completa: $hechas de $total.';

    final siguiente = completo.siguientePendiente;
    return siguiente == null
        ? '$hechas de $total sesiones hechas.'
        : 'Te toca el día ${siguiente.orden}: ${siguiente.nombre} '
              '($hechas de $total hechas).';
  }
}

class _FilaArchivada extends StatelessWidget {
  const _FilaArchivada({required this.planning});

  final PlanningSemanal planning;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        key: Key('planning_${planning.id}'),
        leading: Icon(Icons.inventory_2_outlined, color: esquema.outline),
        title: Text(
          'Semana del ${_comoFecha(planning.fechaInicio)}'
          ' al ${_comoFecha(planning.fechaFin)}',
          style: TextStyle(color: esquema.outline),
        ),
        subtitle: Text([?planning.nombreObjetivo, 'Archivado'].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(Rutas.planningDelCliente(planning.id)),
      ),
    );
  }
}

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
