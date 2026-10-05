import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Datos de alta y edicion de un planning (CU-05, CU-09).
class DatosPlanning {
  const DatosPlanning({
    required this.clienteId,
    required this.fechaInicio,
    this.nombreObjetivo,
  });

  final String clienteId;
  final DateTime fechaInicio;
  final String? nombreObjetivo;

  String? get nombreObjetivoNormalizado {
    final limpio = nombreObjetivo?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  static ErrorValidacion? validarCliente(String clienteId) =>
      clienteId.trim().isEmpty
      ? const ErrorValidacion('Elige un cliente.', campo: 'clienteId')
      : null;

  ErrorValidacion? validar() => validarCliente(clienteId);

  Map<String, dynamic> aJson() => {
    'cliente_id': clienteId,
    'fecha_inicio': soloFecha(fechaInicio),
    'nombre_objetivo': nombreObjetivoNormalizado,
  };
}

/// Datos de alta y edicion de una sesion (CU-06, CU-10).
///
/// Sin fecha: la sesion se numera dentro del planning. El `orden` no lo escribe
/// el entrenador, lo propone el planning (`siguienteOrden`) y solo cambia si se
/// reordenan las sesiones.
class DatosSesion {
  const DatosSesion({
    required this.planningId,
    required this.orden,
    required this.nombre,
  });

  static const int longitudMaximaNombre = 120;

  final String planningId;
  final int orden;
  final String nombre;

  String get nombreNormalizado => nombre.trim();

  static ErrorValidacion? validarNombre(String nombre) {
    final valor = nombre.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion(
        'Pon un nombre a la sesion (por ejemplo, "Empuje" o "Pierna").',
        campo: 'nombre',
      );
    }
    if (valor.length > longitudMaximaNombre) {
      return const ErrorValidacion(
        'El nombre no puede pasar de $longitudMaximaNombre caracteres.',
        campo: 'nombre',
      );
    }
    return null;
  }

  /// No puede haber dos sesiones con el mismo numero en el mismo planning. Lo
  /// garantiza un indice unico; esto evita el viaje de ida y vuelta.
  static ErrorValidacion? validarOrdenLibre({
    required int orden,
    required PlanningSemanal planning,
    String? idSesionQueSeEdita,
  }) {
    if (orden < 1) {
      return const ErrorValidacion('El dia empieza en 1.', campo: 'orden');
    }
    final ocupado = planning.sesiones
        .where((s) => s.orden == orden && s.id != idSesionQueSeEdita)
        .firstOrNull;
    if (ocupado != null) {
      return ErrorValidacion(
        'El dia $orden ya es "${ocupado.nombre}".',
        campo: 'orden',
      );
    }
    return null;
  }

  ErrorValidacion? validar({
    required PlanningSemanal planning,
    String? idSesionQueSeEdita,
  }) =>
      validarNombre(nombre) ??
      validarOrdenLibre(
        orden: orden,
        planning: planning,
        idSesionQueSeEdita: idSesionQueSeEdita,
      );

  Map<String, dynamic> aJson() => {
    'planning_id': planningId,
    'orden': orden,
    'nombre': nombreNormalizado,
  };
}

/// Datos de alta y edicion de un bloque (CU-07, CU-11).
class DatosBloque {
  const DatosBloque({
    required this.sesionId,
    required this.tipo,
    required this.orden,
    this.notas,
  });

  final String sesionId;
  final TipoBloque tipo;
  final int orden;
  final String? notas;

  String? get notasNormalizadas {
    final limpio = notas?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  /// No puede haber dos bloques con el mismo orden en la misma sesion.
  static ErrorValidacion? validarOrdenLibre({
    required int orden,
    required SesionEntrenamiento sesion,
    String? idBloqueQueSeEdita,
  }) {
    if (orden < 1) {
      return const ErrorValidacion('El orden empieza en 1.', campo: 'orden');
    }
    final ocupado = sesion.bloques
        .where((b) => b.orden == orden && b.id != idBloqueQueSeEdita)
        .firstOrNull;
    if (ocupado != null) {
      return ErrorValidacion(
        'Ya hay un bloque de ${ocupado.tipo.etiqueta} en la posicion $orden.',
        campo: 'orden',
      );
    }
    return null;
  }

  ErrorValidacion? validar({
    required SesionEntrenamiento sesion,
    String? idBloqueQueSeEdita,
  }) => validarOrdenLibre(
    orden: orden,
    sesion: sesion,
    idBloqueQueSeEdita: idBloqueQueSeEdita,
  );

  Map<String, dynamic> aJson() => {
    'sesion_id': sesionId,
    'tipo': tipo.name,
    'orden': orden,
    'notas': notasNormalizadas,
  };
}

/// Una serie tal como se introduce en el formulario, antes de existir en la base
/// de datos.
class DatosSerie {
  const DatosSerie({
    required this.numeroSerie,
    required this.repeticiones,
    this.peso,
    this.rir,
  });

  static const int rirMinimo = 0;
  static const int rirMaximo = 10;
  static const double pesoMaximo = 9999.99;
  static const int repeticionesMaximas = 999;

  final int numeroSerie;
  final int repeticiones;
  final double? peso;
  final int? rir;

  static ErrorValidacion? validarRepeticiones(int repeticiones) {
    if (repeticiones <= 0) {
      return const ErrorValidacion(
        'Las repeticiones deben ser mayores que cero.',
        campo: 'repeticiones',
      );
    }
    if (repeticiones > repeticionesMaximas) {
      return const ErrorValidacion(
        'Revisa las repeticiones: el maximo es $repeticionesMaximas.',
        campo: 'repeticiones',
      );
    }
    return null;
  }

  static ErrorValidacion? validarPeso(double? peso) {
    if (peso == null) return null;
    if (peso <= 0) {
      return const ErrorValidacion(
        'El peso debe ser mayor que cero. Dejalo vacio si no aplica.',
        campo: 'peso',
      );
    }
    if (peso > pesoMaximo) {
      return const ErrorValidacion(
        'El peso no puede pasar de $pesoMaximo kg.',
        campo: 'peso',
      );
    }
    return null;
  }

  /// RIR (repeticiones en reserva) en escala 0-10.
  static ErrorValidacion? validarRir(int? rir) {
    if (rir == null) return null;
    if (rir < rirMinimo || rir > rirMaximo) {
      return const ErrorValidacion(
        'El RIR va de $rirMinimo a $rirMaximo.',
        campo: 'rir',
      );
    }
    return null;
  }

  ErrorValidacion? validar() =>
      validarRepeticiones(repeticiones) ?? validarPeso(peso) ?? validarRir(rir);

  Map<String, dynamic> aJson(String ejercicioPlanificadoId) => {
    'ejercicio_planificado_id': ejercicioPlanificadoId,
    'numero_serie': numeroSerie,
    'repeticiones_planificadas': repeticiones,
    'peso_planificado': peso,
    'rir_planificado': rir,
  };

  factory DatosSerie.desdeSerie(SeriePlanificada serie) => DatosSerie(
    numeroSerie: serie.numeroSerie,
    repeticiones: serie.repeticionesPlanificadas,
    peso: serie.pesoPlanificado,
    rir: serie.rirPlanificado,
  );
}

/// Datos de alta y edicion de un ejercicio dentro de un bloque (CU-08, CU-12).
///
/// Aqui vive la regla central de la fase: **Fuerza y Cardio son mutuamente
/// excluyentes**. La validacion no deja construir una combinacion imposible, y el
/// trigger `validar_tipo_ejercicio_planificado` la garantiza en la base de datos.
class DatosEjercicioPlanificado {
  const DatosEjercicioPlanificado({
    required this.bloqueId,
    required this.ejercicioId,
    required this.tipoEjercicio,
    required this.orden,
    this.descansoSeg,
    this.minutos,
    this.series = const [],
  });

  static const int descansoMaximoSeg = 3600;
  static const double minutosMaximos = 999.9;
  static const int seriesMaximas = 20;

  final String bloqueId;
  final String ejercicioId;

  /// Tipo del ejercicio de la biblioteca. Determina qué campos son validos.
  final TipoEjercicio tipoEjercicio;
  final int orden;

  /// Solo Fuerza.
  final int? descansoSeg;

  /// Solo Cardio.
  final double? minutos;

  /// Solo Fuerza.
  final List<DatosSerie> series;

  bool get esFuerza => tipoEjercicio.esFuerza;
  bool get esCardio => tipoEjercicio.esCardio;

  static ErrorValidacion? validarDescanso(int? segundos) {
    if (segundos == null) return null;
    if (segundos <= 0) {
      return const ErrorValidacion(
        'El descanso debe ser mayor que cero. Dejalo vacio si no aplica.',
        campo: 'descansoSeg',
      );
    }
    if (segundos > descansoMaximoSeg) {
      return const ErrorValidacion(
        'El descanso no puede pasar de una hora.',
        campo: 'descansoSeg',
      );
    }
    return null;
  }

  static ErrorValidacion? validarMinutos(double? minutos) {
    if (minutos == null) {
      return const ErrorValidacion(
        'Un ejercicio de cardio necesita minutos.',
        campo: 'minutos',
      );
    }
    if (minutos <= 0) {
      return const ErrorValidacion(
        'Los minutos deben ser mayores que cero.',
        campo: 'minutos',
      );
    }
    if (minutos > minutosMaximos) {
      return const ErrorValidacion(
        'Revisa los minutos: el maximo es $minutosMaximos.',
        campo: 'minutos',
      );
    }
    return null;
  }

  /// Valida la exclusion Fuerza/Cardio y lo que corresponda a cada tipo.
  ErrorValidacion? validar({BloqueEjercicio? bloque, String? idQueSeEdita}) {
    if (orden < 1) {
      return const ErrorValidacion('El orden empieza en 1.', campo: 'orden');
    }
    if (bloque != null) {
      final ocupado = bloque.ejercicios
          .where((e) => e.orden == orden && e.id != idQueSeEdita)
          .firstOrNull;
      if (ocupado != null) {
        return ErrorValidacion(
          'Ya hay un ejercicio en la posicion $orden de este bloque.',
          campo: 'orden',
        );
      }
    }

    if (esCardio) {
      if (series.isNotEmpty) {
        return const ErrorValidacion(
          'Un ejercicio de cardio se planifica con minutos, no con series.',
          campo: 'series',
        );
      }
      if (descansoSeg != null) {
        return const ErrorValidacion(
          'El descanso entre series no aplica a un ejercicio de cardio.',
          campo: 'descansoSeg',
        );
      }
      return validarMinutos(minutos);
    }

    // Fuerza.
    if (minutos != null) {
      return const ErrorValidacion(
        'Un ejercicio de fuerza se planifica con series, no con minutos.',
        campo: 'minutos',
      );
    }
    if (series.isEmpty) {
      return const ErrorValidacion(
        'Anade al menos una serie.',
        campo: 'series',
      );
    }
    if (series.length > seriesMaximas) {
      return const ErrorValidacion(
        'Como maximo $seriesMaximas series por ejercicio.',
        campo: 'series',
      );
    }
    final numeros = series.map((s) => s.numeroSerie).toList();
    if (numeros.toSet().length != numeros.length) {
      return const ErrorValidacion(
        'Hay dos series con el mismo numero.',
        campo: 'series',
      );
    }
    for (final serie in series) {
      final error = serie.validar();
      if (error != null) return error;
    }
    return validarDescanso(descansoSeg);
  }

  /// Cuerpo del `insert`/`update` de `ejercicios_planificados`. Los campos del
  /// tipo que no aplica van explicitamente a `null`, para que una edicion que
  /// cambie de tipo los limpie en lugar de dejar restos.
  Map<String, dynamic> aJson() => {
    'bloque_id': bloqueId,
    'ejercicio_id': ejercicioId,
    'orden': orden,
    'descanso_planificado_seg': esFuerza ? descansoSeg : null,
    'minutos_planificados': esCardio ? minutos : null,
  };
}

/// `YYYY-MM-DD` para las columnas `date`, sin arrastrar hora ni zona horaria.
String soloFecha(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

/// Comprueba que una reordenacion es una permutacion completa de lo que hay
/// (CU-11, CU-12).
///
/// La funcion de Postgres rechaza igualmente una lista incompleta o con
/// repetidos, pero ese viaje sobra: si la pantalla manda algo asi es que ha
/// perdido el hilo de lo que muestra, y eso se ve mejor aqui que en un error del
/// servidor. Tambien evita la llamada cuando no hay nada que mover.
ErrorValidacion? validarReordenacion({
  required List<String> idsEnOrden,
  required List<String> idsActuales,
}) {
  if (idsEnOrden.length != idsActuales.length ||
      idsEnOrden.toSet().length != idsEnOrden.length ||
      !idsEnOrden.toSet().containsAll(idsActuales)) {
    return const ErrorValidacion(
      'La lista no coincide con lo que hay: recarga el planning.',
    );
  }
  return null;
}

/// Aplica un arrastre a una lista: saca el elemento de [desde] y lo mete en
/// [hasta], que es su posicion **final**.
///
/// Son los indices que da `onReorderItem` de `ReorderableListView`, ya
/// corregidos por Flutter. Con el `onReorder` antiguo habria que restar uno al
/// arrastrar hacia abajo, porque daba el destino contando el hueco que deja el
/// elemento movido; por eso se usa el nuevo.
List<T> reordenarLista<T>(List<T> original, int desde, int hasta) {
  final copia = [...original];
  if (desde < 0 || desde >= copia.length) return copia;
  final destino = hasta.clamp(0, copia.length - 1);
  copia.insert(destino, copia.removeAt(desde));
  return copia;
}
