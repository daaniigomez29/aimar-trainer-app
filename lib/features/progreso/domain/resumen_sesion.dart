import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/referencia_anterior.dart';

/// Lo que el cliente acaba de hacer en una sesion, para celebrarlo al
/// terminarla.
///
/// POR QUE: terminar un entrenamiento era volver al planning sin mas. Ver lo
/// hecho, y sobre todo **lo que ha mejorado frente a la ultima vez**, es lo
/// que lo hace gratificante; y son datos suyos de verdad, no un mensaje
/// generico.
class ResumenSesion {
  const ResumenSesion({
    required this.ejerciciosHechos,
    required this.ejerciciosPlanificados,
    required this.seriesHechas,
    required this.seriesPlanificadas,
    required this.volumenKg,
    required this.minutosCardio,
    required this.mejoras,
  });

  final int ejerciciosHechos;
  final int ejerciciosPlanificados;

  /// Todas las registradas, tambien las de mas: aqui se celebra lo hecho, no
  /// se mide el cumplimiento.
  final int seriesHechas;
  final int seriesPlanificadas;

  /// Peso x repeticiones de los ejercicios de Fuerza, x2 si el peso es por
  /// lado. La misma regla que el informe de progresion.
  final double volumenKg;
  final double minutosCardio;
  final List<Mejora> mejoras;
}

enum TipoDeMejora { peso, repeticiones, minutos }

/// Un ejercicio en el que hoy se ha superado lo de la ultima vez.
class Mejora {
  const Mejora({
    required this.ejercicio,
    required this.tipo,
    required this.antes,
    required this.ahora,
    this.porLado = false,
    this.deLaSemanaPasada = false,
    this.fechaAnterior,
  });

  final String ejercicio;
  final TipoDeMejora tipo;

  /// En kg, repeticiones o minutos, segun [tipo].
  final double antes;
  final double ahora;
  final bool porLado;

  /// Respecto a que se mejora. El cliente no tiene por que recordar que hizo
  /// la ultima vez, y "la ultima vez" no siempre es la semana pasada: si esa
  /// semana no hizo el ejercicio, se compara con el ultimo dia que lo
  /// registro ([fechaAnterior]).
  final bool deLaSemanaPasada;
  final DateTime? fechaAnterior;

  double get diferencia => ahora - antes;

  /// La misma mejora, diciendo de cuando es la referencia.
  Mejora respectoDe(ReferenciaAnterior referencia) => Mejora(
    ejercicio: ejercicio,
    tipo: tipo,
    antes: antes,
    ahora: ahora,
    porLado: porLado,
    deLaSemanaPasada: referencia.esSemanaAnterior,
    fechaAnterior: referencia.fecha,
  );
}

/// El resumen de [sesion], comparando con [ultimaVez] (por `ejercicioId`, lo
/// que hizo el cliente la ultima vez en cada ejercicio).
ResumenSesion resumirSesion(
  SesionEntrenamiento sesion, {
  Map<String, ReferenciaAnterior> ultimaVez = const {},
}) {
  final ejercicios = sesion.bloques.expand((b) => b.ejercicios).toList();

  var hechos = 0;
  var seriesHechas = 0;
  var seriesPlanificadas = 0;
  var volumen = 0.0;
  var minutos = 0.0;
  final mejoras = <Mejora>[];
  // Un ejercicio repetido en la sesion se compara una sola vez.
  final comparados = <String>{};

  for (final ep in ejercicios) {
    final ficha = ep.ejercicio;
    final porLado = ficha?.pesoPorLado ?? false;
    seriesPlanificadas += ep.series.length;
    seriesHechas += ep.seriesRealizadas.length;
    minutos += ep.minutosRealizados ?? 0;
    if (ep.seriesRealizadas.isNotEmpty || ep.minutosRealizados != null) {
      hechos++;
    }
    if (ficha?.tipo == TipoEjercicio.fuerza) {
      for (final serie in ep.seriesRealizadas) {
        volumen +=
            (serie.pesoReal ?? 0) *
            serie.repeticionesRealizadas *
            (porLado ? 2 : 1);
      }
    }

    final anterior = ultimaVez[ep.ejercicioId];
    if (ficha == null || anterior == null || !comparados.add(ep.ejercicioId)) {
      continue;
    }
    if (_mejora(ficha.nombre, ep, anterior, porLado: porLado)
        case final mejora?) {
      mejoras.add(mejora.respectoDe(anterior));
    }
  }

  return ResumenSesion(
    ejerciciosHechos: hechos,
    ejerciciosPlanificados: ejercicios.length,
    seriesHechas: seriesHechas,
    seriesPlanificadas: seriesPlanificadas,
    volumenKg: volumen,
    minutosCardio: minutos,
    mejoras: mejoras,
  );
}

/// Si hoy se ha superado lo de la ultima vez, y en que.
///
/// Se compara **la mejor serie**: primero el peso mas alto; a igual peso, las
/// repeticiones hechas con el. Sin peso (peso corporal), las repeticiones de
/// la mejor serie. En cardio, los minutos. Solo cuenta superar, no igualar.
Mejora? _mejora(
  String nombre,
  EjercicioPlanificado hoy,
  ReferenciaAnterior anterior, {
  required bool porLado,
}) {
  if (hoy.minutosRealizados case final ahora?) {
    final antes = anterior.minutos;
    return antes != null && ahora > antes
        ? Mejora(
            ejercicio: nombre,
            tipo: TipoDeMejora.minutos,
            antes: antes,
            ahora: ahora,
          )
        : null;
  }

  final mejorHoy = _mejorSerie(hoy.seriesRealizadas);
  final mejorAntes = _mejorSerie(anterior.series);
  if (mejorHoy == null || mejorAntes == null) return null;

  final pesoHoy = mejorHoy.pesoReal ?? 0;
  final pesoAntes = mejorAntes.pesoReal ?? 0;
  if (pesoHoy > pesoAntes) {
    return Mejora(
      ejercicio: nombre,
      tipo: TipoDeMejora.peso,
      antes: pesoAntes,
      ahora: pesoHoy,
      porLado: porLado,
    );
  }
  if (pesoHoy == pesoAntes &&
      mejorHoy.repeticionesRealizadas > mejorAntes.repeticionesRealizadas) {
    return Mejora(
      ejercicio: nombre,
      tipo: TipoDeMejora.repeticiones,
      antes: mejorAntes.repeticionesRealizadas.toDouble(),
      ahora: mejorHoy.repeticionesRealizadas.toDouble(),
      porLado: porLado,
    );
  }
  return null;
}

SerieRealizada? _mejorSerie(List<SerieRealizada> series) {
  SerieRealizada? mejor;
  for (final serie in series) {
    if (mejor == null) {
      mejor = serie;
      continue;
    }
    final peso = serie.pesoReal ?? 0;
    final pesoMejor = mejor.pesoReal ?? 0;
    if (peso > pesoMejor ||
        (peso == pesoMejor &&
            serie.repeticionesRealizadas > mejor.repeticionesRealizadas)) {
      mejor = serie;
    }
  }
  return mejor;
}

/// Si una serie recien confirmada supera **a la misma serie** (mismo numero)
/// de la ultima vez: mas peso, o el mismo peso con mas repeticiones. Igualar
/// no cuenta. `null` si no hay con que comparar.
///
/// Es lo que enciende la insignia de "Mejora" al confirmar la serie, mientras
/// se entrena; [resumirSesion] compara en cambio la mejor serie del dia.
Mejora? mejoraDeLaSerie({
  required String ejercicio,
  required int repeticiones,
  required double? peso,
  required SerieRealizada? anterior,
  bool porLado = false,
  bool deLaSemanaPasada = false,
  DateTime? fechaAnterior,
}) {
  if (anterior == null) return null;
  final ahora = peso ?? 0;
  final antes = anterior.pesoReal ?? 0;
  if (ahora > antes) {
    return Mejora(
      ejercicio: ejercicio,
      tipo: TipoDeMejora.peso,
      antes: antes,
      ahora: ahora,
      porLado: porLado,
      deLaSemanaPasada: deLaSemanaPasada,
      fechaAnterior: fechaAnterior,
    );
  }
  if (ahora == antes && repeticiones > anterior.repeticionesRealizadas) {
    return Mejora(
      ejercicio: ejercicio,
      tipo: TipoDeMejora.repeticiones,
      antes: anterior.repeticionesRealizadas.toDouble(),
      ahora: repeticiones.toDouble(),
      porLado: porLado,
      deLaSemanaPasada: deLaSemanaPasada,
      fechaAnterior: fechaAnterior,
    );
  }
  return null;
}
