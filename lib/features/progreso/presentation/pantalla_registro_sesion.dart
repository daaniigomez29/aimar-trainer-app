import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Los ejercicios previstos de una sesion, con lo que falta por registrar (CU-20).
///
/// Se queda observando `planningCompletoProvider` en lugar de recibir la sesion y
/// no soltarla: al registrar un ejercicio cambian `estado_registro` y
/// `resultado_registrado`, que los recalculan triggers en la base de datos, y la
/// unica forma de verlos bien es volver a leerlos.
class PantallaRegistroSesion extends ConsumerWidget {
  const PantallaRegistroSesion({
    required this.planningId,
    required this.sesionId,
    required this.clienteId,
    super.key,
  });

  final String planningId;
  final String sesionId;
  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planning = ref.watch(planningCompletoProvider(planningId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar sesión'),
        actions: [
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
            child: Text(
              mensajeDeErrorPlanificacion(error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (datos) {
          final sesion = datos.sesiones
              .where((s) => s.id == sesionId)
              .firstOrNull;
          if (sesion == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Esa sesión ya no existe.'),
              ),
            );
          }
          return _Sesion(sesion: sesion, planning: datos, clienteId: clienteId);
        },
      ),
    );
  }
}

class _Sesion extends StatelessWidget {
  const _Sesion({
    required this.sesion,
    required this.planning,
    required this.clienteId,
  });

  final SesionEntrenamiento sesion;
  final PlanningSemanal planning;
  final String clienteId;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = [
      for (final bloque in sesion.bloques)
        for (final ejercicio in bloque.ejercicios) (bloque, ejercicio),
    ];
    final pendientes = ejercicios
        .where((par) => !par.$2.estadoRegistro.estaRegistrado)
        .length;
    // Un planning archivado ya no admite registros nuevos: lo impide la politica
    // de `series_realizadas`, que exige planning activo. Mejor decirlo antes.
    final puedeRegistrar = planning.estado.esActivo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(sesion.nombre, style: textos.headlineSmall),
        const SizedBox(height: 4),
        Text(
          sesion.fechaRealizada == null
              ? 'Día ${sesion.orden}'
              : 'Día ${sesion.orden} · hecha el '
                    '${_comoFecha(sesion.fechaRealizada!)}',
          style: textos.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (!puedeRegistrar)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Esta semana está archivada: ya no se pueden registrar '
                'resultados nuevos.',
              ),
            ),
          )
        else
          Text(
            pendientes == 0
                ? 'Has registrado todos los ejercicios de esta sesión.'
                : 'Te quedan $pendientes '
                      '${pendientes == 1 ? "ejercicio" : "ejercicios"} por '
                      'registrar.',
            style: textos.bodyMedium,
          ),
        const Divider(height: 32),
        if (ejercicios.isEmpty)
          const Text('Esta sesión no tiene ejercicios.')
        else
          for (final (bloque, ejercicio) in ejercicios)
            _FilaEjercicio(
              bloque: bloque,
              sesion: sesion,
              ejercicio: ejercicio,
              planningId: planning.id,
              clienteId: clienteId,
              habilitado: puedeRegistrar,
            ),
      ],
    );
  }
}

class _FilaEjercicio extends StatelessWidget {
  const _FilaEjercicio({
    required this.bloque,
    required this.sesion,
    required this.ejercicio,
    required this.planningId,
    required this.clienteId,
    required this.habilitado,
  });

  final BloqueEjercicio bloque;

  /// La sesion completa, para que el registro sepa en que punto esta
  /// ("ejercicio 2 de 5") y pueda encadenar con el siguiente.
  final SesionEntrenamiento sesion;
  final EjercicioPlanificado ejercicio;
  final String planningId;
  final String clienteId;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final registrado = ejercicio.estadoRegistro.estaRegistrado;
    final esCardio = ejercicio.ejercicio?.tipo == TipoEjercicio.cardio;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: Key('registrar_${ejercicio.id}'),
        leading: Icon(
          registrado ? Icons.task_alt : Icons.radio_button_unchecked,
          color: registrado ? esquema.primary : esquema.outline,
        ),
        title: Text(ejercicio.ejercicio?.nombre ?? 'Ejercicio'),
        subtitle: Text(_resumen(ejercicio, esCardio: esCardio)),
        trailing: habilitado ? const Icon(Icons.chevron_right) : null,
        enabled: habilitado,
        onTap: habilitado
            ? () => context.go(
                Rutas.registroDeEjercicio(planningId, sesion.id, ejercicio.id),
              )
            : null,
      ),
    );
  }

  /// Que toca y que se lleva hecho, en una linea.
  static String _resumen(
    EjercicioPlanificado ejercicio, {
    required bool esCardio,
  }) {
    if (esCardio) {
      final previstos = ejercicio.minutosPlanificados;
      final hechos = ejercicio.minutosRealizados;
      return [
        if (previstos != null) 'Previsto: ${_numero(previstos)} min',
        if (hechos != null) 'Hecho: ${_numero(hechos)} min',
      ].join(' · ');
    }

    final previstas = ejercicio.series.length;
    final hechas = ejercicio.seriesRealizadas.length;
    return [
      '$previstas ${previstas == 1 ? "serie prevista" : "series previstas"}',
      if (hechas > 0) '$hechas ${hechas == 1 ? "registrada" : "registradas"}',
    ].join(' · ');
  }
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
