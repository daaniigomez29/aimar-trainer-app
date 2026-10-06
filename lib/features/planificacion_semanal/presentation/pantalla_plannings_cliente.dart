import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/formularios_planificacion.dart';

/// Historico de plannings de un cliente (CU-23) y punto de entrada a CU-05.
class PantallaPlanningsCliente extends ConsumerWidget {
  const PantallaPlanningsCliente({required this.clienteId, super.key});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannings = ref.watch(planningsDeClienteProvider(clienteId));
    final nombreCliente = ref
        .watch(clientePorIdProvider(clienteId))
        .value
        ?.nombre;
    ref.watch(controladorPlanificacionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plannings'),
        bottom: nombreCliente == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(nombreCliente),
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(planningsDeClienteProvider(clienteId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('boton_nuevo_planning'),
        onPressed: () async {
          final creado = await pedirDatosPlanning(
            context: context,
            ref: ref,
            clienteId: clienteId,
          );
          if (creado == null || !context.mounted) return;
          ref.invalidate(planningsDeClienteProvider(clienteId));
          context.go(Rutas.planningDeClienteConcreto(clienteId, creado.id));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo planning'),
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
                  onPressed: () =>
                      ref.invalidate(planningsDeClienteProvider(clienteId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (lista) => lista.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Este cliente no tiene ningún planning todavía.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                itemBuilder: (context, indice) =>
                    _Tarjeta(planning: lista[indice], clienteId: clienteId),
              ),
      ),
    );
  }
}

class _Tarjeta extends ConsumerWidget {
  const _Tarjeta({required this.planning, required this.clienteId});

  final PlanningSemanal planning;
  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esquema = Theme.of(context).colorScheme;
    final archivado = planning.estado.estaArchivado;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        key: Key('planning_${planning.id}'),
        leading: Icon(
          archivado ? Icons.inventory_2_outlined : Icons.calendar_month,
          color: archivado ? esquema.outline : esquema.primary,
        ),
        title: Text(
          'Semana del ${_comoFecha(planning.fechaInicio)}'
          ' al ${_comoFecha(planning.fechaFin)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: archivado ? esquema.outline : null,
          ),
        ),
        subtitle: Text(
          [?planning.nombreObjetivo, if (archivado) 'Archivado'].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.go(Rutas.planningDeClienteConcreto(clienteId, planning.id)),
      ),
    );
  }
}

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
