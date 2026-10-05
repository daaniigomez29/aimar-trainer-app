import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Lo que el cliente hizo de verdad la ultima vez que entreno ese ejercicio.
///
/// POR QUE EXISTE: el entrenador no planifica desde cero cada semana. Mira como
/// le fue al cliente y ajusta a partir de ahi. Tener que abrir el planning de la
/// semana pasada en otra pantalla para eso es justo el trabajo manual que esta
/// aplicacion viene a quitar.
///
/// No se mezcla con lo planificado: son datos distintos y se pintan aparte. Lo
/// planificado y lo realizado son independientes por regla de dominio.
class ReferenciaAnterior {
  const ReferenciaAnterior({
    required this.series,
    required this.fecha,
    required this.esSemanaAnterior,
    this.minutos,
  });

  /// Las series realizadas, ordenadas por numero de serie. Vacio en Cardio.
  final List<SerieRealizada> series;

  /// Dia en que el cliente hizo aquella sesion. Puede faltar si la sesion quedo
  /// registrada antes de que existiera `fecha_realizada`.
  final DateTime? fecha;

  /// `true` si viene del Dia N del planning inmediatamente anterior; `false` si
  /// hubo que tirar de historico porque esa semana no lo hizo. La pantalla lo
  /// dice, para que nadie confunda "la semana pasada" con "hace un mes".
  final bool esSemanaAnterior;

  /// Minutos realizados, en Cardio.
  final double? minutos;

  bool get tieneAlgo => series.isNotEmpty || minutos != null;

  /// La serie con ese numero, si la hay. Lo realizado puede tener mas o menos
  /// series que lo planificado: no se fuerzan a coincidir.
  SerieRealizada? serieNumero(int numero) =>
      series.where((s) => s.numeroSerie == numero).firstOrNull;
}

/// El planning del cliente inmediatamente anterior al que se esta editando.
///
/// Por `fechaInicio`, no por fecha de creacion: lo que importa es a que semana
/// corresponde. Cuenta tambien un planning archivado, que es el estado normal de
/// una semana ya pasada.
PlanningSemanal? planningAnteriorA({
  required List<PlanningSemanal> plannings,
  required String idActual,
  required DateTime fechaInicioActual,
}) {
  final anteriores =
      plannings
          .where(
            (p) =>
                p.id != idActual && p.fechaInicio.isBefore(fechaInicioActual),
          )
          .toList()
        ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
  return anteriores.firstOrNull;
}

/// Lo realizado en el Dia [orden] de [anterior], por ejercicio de la biblioteca.
///
/// Se cruza por `ejercicioId`, no por posicion: el entrenador puede haber
/// cambiado el orden de los bloques o de los ejercicios, y seguir siendo el
/// mismo ejercicio. Si un ejercicio aparece dos veces en la misma sesion, se
/// queda con el primero que tenga algo registrado.
Map<String, ReferenciaAnterior> referenciasDelDia({
  required PlanningSemanal anterior,
  required int orden,
}) {
  final sesion = anterior.sesionNumero(orden);
  if (sesion == null) return const {};

  final referencias = <String, ReferenciaAnterior>{};
  for (final bloque in sesion.bloques) {
    for (final ejercicio in bloque.ejercicios) {
      final series = [...ejercicio.seriesRealizadas]
        ..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie));
      if (series.isEmpty && ejercicio.minutosRealizados == null) continue;
      referencias.putIfAbsent(
        ejercicio.ejercicioId,
        () => ReferenciaAnterior(
          series: series,
          minutos: ejercicio.minutosRealizados,
          fecha: sesion.fechaRealizada,
          esSemanaAnterior: true,
        ),
      );
    }
  }
  return referencias;
}

/// Lo realizado convertido en punto de partida de lo planificado (el boton de
/// copiar).
///
/// Se copia tal cual, sin subir ni bajar nada: el entrenador decide el
/// incremento, que depende del cliente y del ejercicio. Lo que se le ahorra es
/// teclear otra vez lo que ya hizo.
///
/// Las series se renumeran del 1 en adelante: si de lo realizado faltara alguna
/// (el cliente registro la 1 y la 3), lo planificado no puede heredar ese hueco,
/// porque `numero_serie` es unico y correlativo.
List<DatosSerie> comoPlanificadas(ReferenciaAnterior referencia) => [
  for (final (indice, serie) in referencia.series.indexed)
    DatosSerie(
      numeroSerie: indice + 1,
      repeticiones: serie.repeticionesRealizadas,
      peso: serie.pesoReal,
      rir: serie.rirReal,
    ),
];
