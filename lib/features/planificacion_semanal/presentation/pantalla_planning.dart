import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';

import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/dialogos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/formularios_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/chips_de_dias.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/resultados_de_sesion.dart';

/// La semana de un cliente **en modo consulta**: lo planificado al lado de lo
/// que hizo, un dia a la vez (CU-21 desde el lado del entrenador).
///
/// POR QUE ES SOLO LECTURA: antes esta pantalla editaba sesiones, bloques y
/// ejercicios, las mismas operaciones que el editor de
/// `/entrenador/plannings/:id`, y a la vez **no ensenaba ningun resultado**. El
/// entrenador no tenia donde ver lo que sus clientes hacen el mismo dia si no
/// era poniendose a planificar la semana siguiente para mirar la columna de
/// referencia. Ahora cada vista tiene su funcion: aqui se consulta, alli se
/// planifica. Desde el editor hay un boton directo a esta pantalla, por dia.
///
/// Lo que si se queda son las acciones **del planning entero**, que no editan el
/// plan y no tienen otro sitio: archivar o reactivar, cambiar el objetivo y
/// eliminarlo.
///
/// La misma pantalla sirve al cliente para su historico, con el boton de
/// registrar su resultado (CU-20) si la semana sigue activa.
class PantallaPlanning extends ConsumerStatefulWidget {
  const PantallaPlanning({
    required this.planningId,
    this.diaInicial,
    super.key,
  });

  final String planningId;

  /// Dia por el que abrir, si se pide uno. Lo inyecta el enrutador desde la URL
  /// (`?dia=`): es como llega el boton "Visualizar resultados de la sesion" del
  /// editor, para caer en el dia que se estaba planificando.
  final int? diaInicial;

  @override
  ConsumerState<PantallaPlanning> createState() => _EstadoPantallaPlanning();
}

class _EstadoPantallaPlanning extends ConsumerState<PantallaPlanning> {
  /// Dia elegido en la tira. `null` hasta que se toca: manda el de la URL.
  int? _dia;

  @override
  Widget build(BuildContext context) {
    final esEntrenador = ref.watch(rolActualProvider)?.esEntrenador ?? false;
    final planning = ref.watch(planningCompletoProvider(widget.planningId));
    ref.watch(controladorPlanificacionProvider);

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.clientes,
      appBar: AppBar(
        title: const Text('Resultados de la semana'),
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
                ref.invalidate(planningCompletoProvider(widget.planningId)),
          ),
        ],
      ),
      cuerpo: planning.when(
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
                  onPressed: () => ref.invalidate(
                    planningCompletoProvider(widget.planningId),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (datos) => _Semana(
          planning: datos,
          diaElegido: _dia ?? widget.diaInicial,
          onElegirDia: (orden) => setState(() => _dia = orden),
          esEntrenador: esEntrenador,
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
    required this.diaElegido,
    required this.onElegirDia,
    required this.esEntrenador,
    required this.puedeRegistrar,
  });

  final PlanningSemanal planning;
  final int? diaElegido;
  final ValueChanged<int> onElegirDia;
  final bool esEntrenador;
  final bool puedeRegistrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final sesiones = planning.sesionesOrdenadas;
    // Por defecto, el primer dia: es la semana entera lo que se consulta, no
    // una sesion suelta.
    final sesion =
        planning.sesionNumero(diaElegido ?? -1) ?? sesiones.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(Tokens.margenPantalla),
      children: [
        _Cabecera(planning: planning, esEntrenador: esEntrenador),
        const Divider(height: 24),
        if (sesiones.isEmpty)
          Text(
            esEntrenador
                ? 'Esta semana no tiene sesiones. Se montan en la pantalla de '
                      'planificación.'
                : 'Esta semana no tiene sesiones.',
            style: textos.bodySmall,
          )
        else ...[
          ChipsDeDias(
            sesiones: sesiones,
            elegida: sesion?.orden,
            onElegir: onElegirDia,
          ),
          const SizedBox(height: 18),
          if (sesion != null) ResultadosDeSesion(sesion: sesion),
          if (puedeRegistrar && sesion != null) ...[
            const SizedBox(height: Tokens.separacionBloques),
            BotonCta(
              etiqueta: 'Registrar mi resultado',
              onPulsar: () =>
                  context.go(Rutas.registroDeSesion(planning.id, sesion.id)),
            ),
          ],
        ],
      ],
    );
  }
}

class _Cabecera extends ConsumerWidget {
  const _Cabecera({required this.planning, required this.esEntrenador});

  final PlanningSemanal planning;
  final bool esEntrenador;

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
            // Datos del planning, no su contenido: el objetivo y las fechas no
            // se editan en ningun otro sitio.
            if (esEntrenador)
              IconButton(
                tooltip: 'Editar los datos del planning',
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
      ],
    );
  }
}

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
