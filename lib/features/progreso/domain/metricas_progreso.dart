import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

part 'metricas_progreso.freezed.dart';
part 'metricas_progreso.g.dart';

/// Una fila de `vista_progreso_ejercicios`: o una serie de Fuerza, o los minutos
/// de un Cardio, ya con la fecha de la sesion a la que pertenece.
@freezed
abstract class RegistroProgreso with _$RegistroProgreso {
  const factory RegistroProgreso({
    required String clienteId,
    required String ejercicioId,
    required String ejercicioNombre,
    required TipoEjercicio ejercicioTipo,
    required String sesionId,
    required DateTime fecha,
    int? numeroSerie,
    int? repeticionesRealizadas,
    double? pesoReal,
    int? rirReal,
    double? minutosRealizados,
  }) = _RegistroProgreso;

  factory RegistroProgreso.fromJson(Map<String, dynamic> json) =>
      _$RegistroProgresoFromJson(json);
}

/// Un ejercicio con algo registrado, para el desplegable del filtro.
@freezed
abstract class EjercicioConRegistro with _$EjercicioConRegistro {
  const factory EjercicioConRegistro({
    required String ejercicioId,
    required String ejercicioNombre,
    required TipoEjercicio ejercicioTipo,
  }) = _EjercicioConRegistro;

  factory EjercicioConRegistro.fromJson(Map<String, dynamic> json) =>
      _$EjercicioConRegistroFromJson(json);
}

/// Que se mide de un ejercicio a lo largo del tiempo (CU-21).
///
/// Cada metrica resume en un unico numero todo lo registrado de ese ejercicio en
/// una sesion: por eso [resumir] recibe las filas de un mismo dia.
enum MetricaEjercicio {
  pesoMaximo,
  volumenTotal,
  repeticionesTotales,
  rirMedio,
  minutos;

  String get etiqueta => switch (this) {
    MetricaEjercicio.pesoMaximo => 'Peso máximo',
    MetricaEjercicio.volumenTotal => 'Volumen total',
    MetricaEjercicio.repeticionesTotales => 'Repeticiones totales',
    MetricaEjercicio.rirMedio => 'RIR medio',
    MetricaEjercicio.minutos => 'Minutos',
  };

  String get unidad => switch (this) {
    MetricaEjercicio.pesoMaximo => 'kg',
    MetricaEjercicio.volumenTotal => 'kg',
    MetricaEjercicio.repeticionesTotales => 'reps',
    MetricaEjercicio.rirMedio => 'RIR',
    MetricaEjercicio.minutos => 'min',
  };

  /// Explicacion corta, para que el cliente sepa que esta mirando.
  String get descripcion => switch (this) {
    MetricaEjercicio.pesoMaximo => 'La carga más alta levantada ese día.',
    MetricaEjercicio.volumenTotal =>
      'Suma de peso por repeticiones de todas las series.',
    MetricaEjercicio.repeticionesTotales =>
      'Repeticiones sumadas de todas las series.',
    MetricaEjercicio.rirMedio =>
      'Media del RIR de las series. Más bajo, más cerca del fallo.',
    MetricaEjercicio.minutos => 'Minutos registrados en la sesión.',
  };

  /// Las que tienen sentido para un tipo de ejercicio. Fuerza y Cardio no
  /// comparten ninguna: uno se mide en series, el otro en minutos.
  static List<MetricaEjercicio> deTipo(TipoEjercicio tipo) => switch (tipo) {
    TipoEjercicio.fuerza => const [
      MetricaEjercicio.pesoMaximo,
      MetricaEjercicio.volumenTotal,
      MetricaEjercicio.repeticionesTotales,
      MetricaEjercicio.rirMedio,
    ],
    TipoEjercicio.cardio => const [MetricaEjercicio.minutos],
  };

  /// Resume en un valor las filas de una misma sesion. `null` si esas filas no
  /// tienen el dato que la metrica necesita (por ejemplo, series sin peso).
  double? resumir(List<RegistroProgreso> registrosDeUnDia) {
    switch (this) {
      case MetricaEjercicio.pesoMaximo:
        final pesos = registrosDeUnDia.map((r) => r.pesoReal).nonNulls.toList();
        return pesos.isEmpty ? null : pesos.reduce((a, b) => a > b ? a : b);

      case MetricaEjercicio.volumenTotal:
        var total = 0.0;
        var hayDatos = false;
        for (final registro in registrosDeUnDia) {
          final peso = registro.pesoReal;
          final reps = registro.repeticionesRealizadas;
          if (peso == null || reps == null) continue;
          total += peso * reps;
          hayDatos = true;
        }
        return hayDatos ? total : null;

      case MetricaEjercicio.repeticionesTotales:
        final reps = registrosDeUnDia
            .map((r) => r.repeticionesRealizadas)
            .nonNulls
            .toList();
        return reps.isEmpty
            ? null
            : reps.fold<int>(0, (a, b) => a + b).toDouble();

      case MetricaEjercicio.rirMedio:
        final valores = registrosDeUnDia
            .map((r) => r.rirReal)
            .nonNulls
            .toList();
        if (valores.isEmpty) return null;
        return valores.fold<int>(0, (a, b) => a + b) / valores.length;

      case MetricaEjercicio.minutos:
        final minutos = registrosDeUnDia
            .map((r) => r.minutosRealizados)
            .nonNulls
            .toList();
        return minutos.isEmpty ? null : minutos.reduce((a, b) => a + b);
    }
  }
}

/// Que se mide del cuerpo (CU-21 sobre `registros_medidas`).
enum MetricaCorporal {
  pesoKg,
  pechoCm,
  cinturaCm,
  caderaCm,
  cuadricepsCm,
  brazosCm;

  String get etiqueta => switch (this) {
    MetricaCorporal.pesoKg => 'Peso corporal',
    MetricaCorporal.pechoCm => 'Pecho',
    MetricaCorporal.cinturaCm => 'Cintura',
    MetricaCorporal.caderaCm => 'Cadera',
    MetricaCorporal.cuadricepsCm => 'Cuádriceps',
    MetricaCorporal.brazosCm => 'Brazos',
  };

  String get unidad => this == MetricaCorporal.pesoKg ? 'kg' : 'cm';

  double? valorDe(RegistroMedidas registro) => switch (this) {
    MetricaCorporal.pesoKg => registro.pesoKg,
    MetricaCorporal.pechoCm => registro.pechoCm,
    MetricaCorporal.cinturaCm => registro.cinturaCm,
    MetricaCorporal.caderaCm => registro.caderaCm,
    MetricaCorporal.cuadricepsCm => registro.cuadricepsCm,
    MetricaCorporal.brazosCm => registro.brazosCm,
  };
}

/// Un punto de la grafica: una fecha y su valor ya resumido.
class PuntoProgreso {
  const PuntoProgreso({required this.fecha, required this.valor});

  final DateTime fecha;
  final double valor;
}

/// Rango de fechas del filtro. Ambos extremos incluidos.
class RangoFechas {
  const RangoFechas({required this.desde, required this.hasta});

  /// Por defecto, los ultimos tres meses: suficiente para ver una tendencia sin
  /// traerse el historico entero.
  factory RangoFechas.ultimosMeses(int meses, {DateTime? hoy}) {
    final fin = hoy ?? DateTime.now();
    final soloDia = DateTime(fin.year, fin.month, fin.day);
    return RangoFechas(
      desde: DateTime(soloDia.year, soloDia.month - meses, soloDia.day),
      hasta: soloDia,
    );
  }

  final DateTime desde;
  final DateTime hasta;

  bool get esValido => !desde.isAfter(hasta);

  bool contiene(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return !dia.isBefore(DateTime(desde.year, desde.month, desde.day)) &&
        !dia.isAfter(DateTime(hasta.year, hasta.month, hasta.day));
  }
}

/// Agrupa por dia y resume cada dia con la metrica, en orden cronologico.
///
/// Vive en el dominio y no en la pantalla porque es la regla de "que significa
/// progresar" en este ejercicio, no una cuestion de presentacion.
List<PuntoProgreso> serieDeProgreso({
  required List<RegistroProgreso> registros,
  required MetricaEjercicio metrica,
}) {
  final porDia = <DateTime, List<RegistroProgreso>>{};
  for (final registro in registros) {
    final dia = DateTime(
      registro.fecha.year,
      registro.fecha.month,
      registro.fecha.day,
    );
    porDia.putIfAbsent(dia, () => []).add(registro);
  }

  final puntos = <PuntoProgreso>[];
  for (final entrada in porDia.entries) {
    final valor = metrica.resumir(entrada.value);
    if (valor != null) {
      puntos.add(PuntoProgreso(fecha: entrada.key, valor: valor));
    }
  }
  puntos.sort((a, b) => a.fecha.compareTo(b.fecha));
  return puntos;
}

/// Lo mismo para las medidas corporales: un punto por registro que tenga ese dato.
List<PuntoProgreso> serieCorporal({
  required List<RegistroMedidas> registros,
  required MetricaCorporal metrica,
}) {
  final puntos = <PuntoProgreso>[];
  for (final registro in registros) {
    final valor = metrica.valorDe(registro);
    if (valor != null) {
      puntos.add(PuntoProgreso(fecha: registro.fecha, valor: valor));
    }
  }
  puntos.sort((a, b) => a.fecha.compareTo(b.fecha));
  return puntos;
}
