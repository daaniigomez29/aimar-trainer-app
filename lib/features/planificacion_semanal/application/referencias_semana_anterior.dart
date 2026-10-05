import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';

part 'referencias_semana_anterior.g.dart';

/// Lo que el cliente hizo la ultima vez en cada ejercicio del Dia [orden], para
/// que el entrenador planifique mirandolo.
///
/// Dos fuentes, en este orden:
///  1. El Dia [orden] del planning inmediatamente anterior. Es la referencia
///     buena: misma sesion, una semana antes.
///  2. Para lo que no aparezca ahi (ejercicio nuevo ese dia, o esa semana no lo
///     hizo), lo ultimo que haya registrado de ese ejercicio, venga de cuando
///     venga. Queda marcado como `esSemanaAnterior: false` para que la pantalla
///     avise con la fecha.
///
/// Si algo falla, devuelve lo que tenga en vez de propagar el error: esto es una
/// ayuda, y quedarse sin planificar porque el historico no carga seria peor que
/// no verlo.
@riverpod
Future<Map<String, ReferenciaAnterior>> referenciasDeSesion(
  Ref ref,
  String planningId,
  int orden,
) async {
  final planning = await ref.watch(planningCompletoProvider(planningId).future);
  final sesion = planning.sesionNumero(orden);
  if (sesion == null) return const {};

  final ejerciciosDelDia = {
    for (final bloque in sesion.bloques)
      for (final ejercicio in bloque.ejercicios) ejercicio.ejercicioId,
  };
  if (ejerciciosDelDia.isEmpty) return const {};

  final repositorio = ref.watch(planningRepositorioProvider);
  final referencias = <String, ReferenciaAnterior>{};

  // --- 1. El mismo dia de la semana anterior ---
  final listado = await repositorio.listarDeCliente(planning.clienteId);
  if (listado case Success(valor: final plannings)) {
    final anterior = planningAnteriorA(
      plannings: plannings,
      idActual: planning.id,
      fechaInicioActual: planning.fechaInicio,
    );
    if (anterior != null) {
      final completo = await repositorio.obtenerPlanningCompleto(anterior.id);
      if (completo case Success(valor: final semanaPasada)) {
        referencias.addAll(
          referenciasDelDia(anterior: semanaPasada, orden: orden)
            ..removeWhere((id, _) => !ejerciciosDelDia.contains(id)),
        );
      }
    }
  }

  // --- 2. Historico, solo para lo que falte ---
  final sinReferencia = ejerciciosDelDia.difference(referencias.keys.toSet());
  if (sinReferencia.isEmpty) return referencias;

  final historico = await ref
      .watch(progresoRepositorioProvider)
      .ultimoDeCadaEjercicio(
        clienteId: planning.clienteId,
        ejercicioIds: sinReferencia.toList(),
        antesDe: planning.fechaInicio,
      );
  if (historico case Success(valor: final filas)) {
    referencias.addAll(referenciasDesdeHistorico(filas));
  }

  return referencias;
}

/// Agrupa las filas de `vista_progreso_ejercicios` quedandose, para cada
/// ejercicio, con **la ultima fecha** en que se registro.
///
/// Las filas vienen de lo mas reciente a lo mas antiguo, pero no se da por
/// supuesto: se compara la fecha, que es barato y no depende del `order` de la
/// consulta.
Map<String, ReferenciaAnterior> referenciasDesdeHistorico(
  List<RegistroProgreso> filas,
) {
  final ultimaFecha = <String, DateTime>{};
  for (final fila in filas) {
    final actual = ultimaFecha[fila.ejercicioId];
    if (actual == null || fila.fecha.isAfter(actual)) {
      ultimaFecha[fila.ejercicioId] = fila.fecha;
    }
  }

  final referencias = <String, ReferenciaAnterior>{};
  for (final (ejercicioId, fecha) in ultimaFecha.entries.map(
    (e) => (e.key, e.value),
  )) {
    final deEseDia = filas.where(
      (f) => f.ejercicioId == ejercicioId && f.fecha == fecha,
    );

    final series = [
      for (final fila in deEseDia)
        if (fila.numeroSerie case final numero?)
          SerieRealizada(
            // La vista no trae el id de la serie ni el del ejercicio
            // planificado: aqui solo se pintan numeros, nadie los va a
            // guardar ni a editar.
            id: '$ejercicioId-$numero',
            ejercicioPlanificadoId: '',
            numeroSerie: numero,
            repeticionesRealizadas: fila.repeticionesRealizadas ?? 0,
            pesoReal: fila.pesoReal,
            rirReal: fila.rirReal,
            fechaHoraRegistro: fecha,
          ),
    ]..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie));

    final minutos = deEseDia
        .map((f) => f.minutosRealizados)
        .nonNulls
        .firstOrNull;

    if (series.isEmpty && minutos == null) continue;
    referencias[ejercicioId] = ReferenciaAnterior(
      series: series,
      minutos: minutos,
      fecha: fecha,
      esSemanaAnterior: false,
    );
  }
  return referencias;
}
