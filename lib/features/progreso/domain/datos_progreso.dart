import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart'
    show soloFecha;

/// Una serie tal y como la registra el cliente (CU-20).
///
/// No tiene por que parecerse a la serie planificada: mas repeticiones, menos
/// peso, u otra serie que el entrenador no habia previsto. Esa diferencia es la
/// metrica de rendimiento, no un error que haya que impedir.
class DatosSerieRealizada {
  const DatosSerieRealizada({
    required this.numeroSerie,
    required this.repeticiones,
    this.peso,
    this.rir,
  });

  final int numeroSerie;
  final int repeticiones;
  final double? peso;
  final int? rir;

  static ErrorValidacion? validarRepeticiones(int repeticiones) =>
      repeticiones <= 0
      ? const ErrorValidacion(
          'Las repeticiones deben ser un número mayor que cero.',
          campo: 'repeticiones',
        )
      : null;

  static ErrorValidacion? validarPeso(double? peso) => peso != null && peso <= 0
      ? const ErrorValidacion(
          'El peso debe ser mayor que cero. Dejalo vacío si no usaste carga.',
          campo: 'peso',
        )
      : null;

  /// RIR en escala 0-10, igual que el planificado.
  static ErrorValidacion? validarRir(int? rir) =>
      rir != null && (rir < 0 || rir > 10)
      ? const ErrorValidacion('El RIR va de 0 a 10.', campo: 'rir')
      : null;

  ErrorValidacion? validar() =>
      validarRepeticiones(repeticiones) ?? validarPeso(peso) ?? validarRir(rir);

  Map<String, dynamic> aJson() => {
    'numero_serie': numeroSerie,
    'repeticiones': repeticiones,
    'peso': peso,
    'rir': rir,
  };
}

/// Resultado de un ejercicio: series si es Fuerza, minutos si es Cardio.
///
/// Los dos caminos son excluyentes, como al planificar. Lo comprueba tambien la
/// funcion `registrar_resultado_ejercicio` antes de escribir nada.
class DatosResultadoEjercicio {
  const DatosResultadoEjercicio.fuerza({
    required this.ejercicioPlanificadoId,
    required this.series,
  }) : minutos = null;

  const DatosResultadoEjercicio.cardio({
    required this.ejercicioPlanificadoId,
    required double this.minutos,
  }) : series = const [];

  final String ejercicioPlanificadoId;
  final List<DatosSerieRealizada> series;
  final double? minutos;

  bool get esCardio => minutos != null;

  static ErrorValidacion? validarMinutos(double? minutos) {
    if (minutos == null) {
      return const ErrorValidacion(
        'Indica cuantos minutos hiciste.',
        campo: 'minutos',
      );
    }
    if (minutos <= 0) {
      return const ErrorValidacion(
        'Los minutos deben ser mayores que cero.',
        campo: 'minutos',
      );
    }
    return null;
  }

  ErrorValidacion? validar() {
    if (esCardio) return validarMinutos(minutos);

    if (series.isEmpty) {
      return const ErrorValidacion(
        'Registra al menos una serie.',
        campo: 'series',
      );
    }
    for (final serie in series) {
      final error = serie.validar();
      if (error != null) return error;
    }

    final numeros = series.map((s) => s.numeroSerie).toSet();
    if (numeros.length != series.length) {
      return const ErrorValidacion(
        'Hay dos series con el mismo número.',
        campo: 'series',
      );
    }
    return null;
  }
}

/// Datos del formulario de medidas corporales.
///
/// `pesoKg` es el unico obligatorio; los perimetros se quedan en `null` si el
/// cliente no se los ha medido.
class DatosRegistroMedidas {
  const DatosRegistroMedidas({
    required this.clienteId,
    required this.fecha,
    required this.pesoKg,
    this.pechoCm,
    this.cinturaCm,
    this.caderaCm,
    this.cuadricepsCm,
    this.brazosCm,
  });

  final String clienteId;
  final DateTime fecha;
  final double? pesoKg;
  final double? pechoCm;
  final double? cinturaCm;
  final double? caderaCm;
  final double? cuadricepsCm;
  final double? brazosCm;

  static ErrorValidacion? validarPeso(double? pesoKg) {
    if (pesoKg == null) {
      return const ErrorValidacion('Indica tu peso.', campo: 'pesoKg');
    }
    if (pesoKg <= 0) {
      return const ErrorValidacion(
        'El peso debe ser mayor que cero.',
        campo: 'pesoKg',
      );
    }
    return null;
  }

  static ErrorValidacion? validarPerimetro(double? valor, String campo) =>
      valor != null && valor <= 0
      ? ErrorValidacion('Esa medida debe ser mayor que cero.', campo: campo)
      : null;

  ErrorValidacion? validar() =>
      validarPeso(pesoKg) ??
      validarPerimetro(pechoCm, 'pechoCm') ??
      validarPerimetro(cinturaCm, 'cinturaCm') ??
      validarPerimetro(caderaCm, 'caderaCm') ??
      validarPerimetro(cuadricepsCm, 'cuadricepsCm') ??
      validarPerimetro(brazosCm, 'brazosCm');

  Map<String, dynamic> aJson() => {
    'cliente_id': clienteId,
    'fecha': soloFecha(fecha),
    'peso_kg': pesoKg,
    'pecho_cm': pechoCm,
    'cintura_cm': cinturaCm,
    'cadera_cm': caderaCm,
    'cuadriceps_cm': cuadricepsCm,
    'brazos_cm': brazosCm,
  };
}

/// Datos del formulario de check-in de recuperacion.
class DatosCheckin {
  const DatosCheckin({
    required this.clienteId,
    required this.fecha,
    required this.horasSueno,
    required this.estres,
    required this.agujetas,
    required this.fatiga,
    this.notas,
  });

  final String clienteId;
  final DateTime fecha;
  final double? horasSueno;

  /// Escala 1-10, no 0-10: aqui no existe el "nada de nada" del RIR.
  final int estres;
  final int agujetas;
  final int fatiga;
  final String? notas;

  String? get notasNormalizadas {
    final limpio = notas?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  static ErrorValidacion? validarHorasSueno(double? horas) {
    if (horas == null) {
      return const ErrorValidacion(
        'Indica cuantas horas dormiste de media.',
        campo: 'horasSueno',
      );
    }
    // Sin tope superior, por decision del ERS; solo se descarta lo imposible.
    if (horas < 0) {
      return const ErrorValidacion(
        'Las horas de sueno no pueden ser negativas.',
        campo: 'horasSueno',
      );
    }
    return null;
  }

  static ErrorValidacion? validarEscala(int valor, String campo) =>
      valor < 1 || valor > 10
      ? ErrorValidacion('Esa valoración va de 1 a 10.', campo: campo)
      : null;

  ErrorValidacion? validar() =>
      validarHorasSueno(horasSueno) ??
      validarEscala(estres, 'estres') ??
      validarEscala(agujetas, 'agujetas') ??
      validarEscala(fatiga, 'fatiga');

  Map<String, dynamic> aJson() => {
    'cliente_id': clienteId,
    'fecha': soloFecha(fecha),
    'horas_sueno': horasSueno,
    'estres': estres,
    'agujetas': agujetas,
    'fatiga': fatiga,
    'notas': notasNormalizadas,
  };
}
