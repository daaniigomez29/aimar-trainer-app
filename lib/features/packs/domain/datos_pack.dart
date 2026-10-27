import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';

/// Datos de alta y edicion de un pack.
class DatosPack {
  const DatosPack({required this.nombre, required this.tipos});

  static const int longitudMaximaNombre = 120;

  final String nombre;

  /// Etiquetas de tipo: al menos una. Solo descriptivas, ver [Pack.tipos].
  final Set<TipoEjercicio> tipos;

  String get nombreNormalizado => nombre.trim();

  static ErrorValidacion? validarNombre(String nombre) {
    final valor = nombre.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion('Ponle un nombre al pack.', campo: 'nombre');
    }
    if (valor.length > longitudMaximaNombre) {
      return const ErrorValidacion(
        'El nombre no puede pasar de $longitudMaximaNombre caracteres.',
        campo: 'nombre',
      );
    }
    return null;
  }

  static ErrorValidacion? validarTipos(Set<TipoEjercicio> tipos) =>
      tipos.isEmpty
      ? const ErrorValidacion(
          'Elige al menos un tipo para el pack.',
          campo: 'tipos',
        )
      : null;

  ErrorValidacion? validar() => validarNombre(nombre) ?? validarTipos(tipos);

  /// Los tipos en el orden del enum, el mismo en que los deja la base.
  Map<String, dynamic> aJson() => {
    'nombre': nombreNormalizado,
    'tipos': [
      for (final tipo in TipoEjercicio.values)
        if (tipos.contains(tipo)) tipo.name,
    ],
  };
}

/// Un ejercicio del pack tal como se introduce en el formulario.
///
/// **Todo lo de preparar es opcional**: un pack puede ser solo la lista de
/// ejercicios. Es la diferencia con `DatosEjercicioPlanificado`, que exige
/// series a lo que va por series.
///
/// Lo que si se mantiene es la exclusion: lo que va por minutos no lleva series
/// y al reves. Lo garantizan ademas dos triggers, porque la regla no puede
/// depender de que la interfaz se acuerde.
class DatosPackEjercicio {
  const DatosPackEjercicio({
    required this.packId,
    required this.ejercicioId,
    required this.tipo,
    required this.orden,
    this.descansoSeg,
    this.minutos,
    this.series = const <DatosSerie>[],
  });

  final String packId;
  final String ejercicioId;

  /// El tipo **del ejercicio** elegido: decide si se guardan series o minutos.
  /// Hasta el 2026-10-27 era el del pack, que entonces era el de todos sus
  /// ejercicios; ahora un pack puede mezclarlos.
  final TipoEjercicio tipo;
  final int orden;
  final int? descansoSeg;
  final double? minutos;
  final List<DatosSerie> series;

  bool get vaPorSeries => tipo.vaPorSeries;
  bool get vaPorMinutos => tipo.vaPorMinutos;

  /// Lo que de verdad se guarda de cada campo, segun el tipo: asi cambiar de
  /// ejercicio (de una sentadilla a una cinta) no deja series ni minutos
  /// colgando.
  int? get descansoNormalizado => vaPorSeries ? descansoSeg : null;
  double? get minutosNormalizados => vaPorMinutos ? minutos : null;
  List<DatosSerie> get seriesNormalizadas =>
      vaPorSeries ? series : const <DatosSerie>[];

  static ErrorValidacion? validarEjercicio(String ejercicioId) =>
      ejercicioId.trim().isEmpty
      ? const ErrorValidacion('Elige un ejercicio.', campo: 'ejercicioId')
      : null;

  static ErrorValidacion? validarDescanso(int? segundos) {
    if (segundos == null) return null;
    return segundos <= 0
        ? const ErrorValidacion(
            'El descanso debe ser mayor que cero. Déjalo vacío si no aplica.',
            campo: 'descansoSeg',
          )
        : null;
  }

  static ErrorValidacion? validarMinutos(double? minutos) {
    if (minutos == null) return null;
    return minutos <= 0
        ? const ErrorValidacion(
            'Los minutos deben ser mayores que cero. Déjalos vacíos si no los '
            'quieres fijar.',
            campo: 'minutos',
          )
        : null;
  }

  /// Las series, sin repetir numero y cada una valida por su cuenta.
  static ErrorValidacion? validarSeries(List<DatosSerie> series) {
    final numeros = <int>{};
    for (final serie in series) {
      if (!numeros.add(serie.numeroSerie)) {
        return const ErrorValidacion(
          'Hay dos series con el mismo número.',
          campo: 'series',
        );
      }
      final error = serie.validar();
      if (error != null) return error;
    }
    return null;
  }

  ErrorValidacion? validar() =>
      validarEjercicio(ejercicioId) ??
      validarDescanso(descansoNormalizado) ??
      validarMinutos(minutosNormalizados) ??
      validarSeries(seriesNormalizadas);

  /// Los parametros de `guardar_ejercicio_del_pack`, que guarda el ejercicio y
  /// sus series en una sola transaccion.
  Map<String, dynamic> aParametrosDeRpc({String? id}) => {
    'p_id': id,
    'p_pack_id': packId,
    'p_ejercicio_id': ejercicioId,
    'p_orden': orden,
    'p_descanso_seg': descansoNormalizado,
    'p_minutos': minutosNormalizados,
    'p_series': [for (final serie in seriesNormalizadas) serie.aJsonDeRpc()],
  };

  /// Los mismos datos a partir de lo que ya hay guardado, para editar.
  factory DatosPackEjercicio.desde(
    PackEjercicio ejercicio, {
    required TipoEjercicio tipo,
  }) => DatosPackEjercicio(
    packId: ejercicio.packId,
    ejercicioId: ejercicio.ejercicioId,
    tipo: tipo,
    orden: ejercicio.orden,
    descansoSeg: ejercicio.descansoSeg,
    minutos: ejercicio.minutos,
    series: [
      for (final serie in ejercicio.seriesOrdenadas)
        DatosSerie(
          numeroSerie: serie.numeroSerie,
          repeticiones: serie.repeticiones,
          peso: serie.peso,
          rir: serie.rir,
        ),
    ],
  );
}
