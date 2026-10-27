import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

part 'pack.freezed.dart';
part 'pack.g.dart';

/// Pack de entrenamiento: una plantilla de ejercicios que el entrenador
/// reutiliza al planificar.
///
/// POR QUE NO ES UN PLANNING: la cadena del planning
/// (`sesion -> bloque -> ejercicio planificado -> serie`) existe porque alguien
/// va a entrenar eso, y lo lleva encima: `estadoRegistro`, `minutosRealizados`,
/// `fechaRealizada`. Un pack no se entrena ni se registra, y **no lo ve ningun
/// cliente**: RLS lo deja solo al entrenador.
///
/// Lo que une a los dos es una **copia**: aplicar un pack a un bloque duplica
/// sus ejercicios y sus series dentro del planning, y a partir de ahi son del
/// planning. Editar el pack despues no cambia lo ya planificado.
@freezed
abstract class Pack with _$Pack {
  const Pack._();

  const factory Pack({
    required String id,
    required String nombre,

    /// Etiquetas de tipo, al menos una, sin repetidos y en el orden del enum
    /// (lo normaliza un trigger). **Solo descriptivas** desde el 2026-10-27:
    /// dicen de que va el pack, pero no limitan que ejercicios admite. Si un
    /// ejercicio lleva series o minutos lo decide su propio tipo.
    required List<TipoEjercicio> tipos,
    required DateTime creadoEn,
    @Default([])
    @JsonKey(name: 'pack_ejercicios')
    List<PackEjercicio> ejercicios,
  }) = _Pack;

  factory Pack.fromJson(Map<String, dynamic> json) => _$PackFromJson(json);

  /// Un pack sin ejercicios no se puede aplicar a ningun bloque: no hay nada
  /// que copiar. La base lo rechaza igual (`aplicar_pack_a_bloque`), esto es
  /// para poder decirlo antes de intentarlo.
  bool get sePuedeAplicar => ejercicios.isNotEmpty;

  /// Los ejercicios en su orden (1, 2, 3...).
  List<PackEjercicio> get ejerciciosOrdenados =>
      [...ejercicios]..sort((a, b) => a.orden.compareTo(b.orden));

  /// Numero que le toca al siguiente ejercicio que se anada.
  int get siguienteOrden =>
      ejercicios.fold<int>(
        0,
        (maximo, e) => e.orden > maximo ? e.orden : maximo,
      ) +
      1;
}

/// Un ejercicio dentro de un pack, con lo que el entrenador deje preparado.
///
/// **Todo lo preconfigurado es opcional**, a diferencia del planning: un pack
/// puede ser solo la lista de ejercicios. Lo que falte se rellena en el planning
/// despues de aplicarlo.
@freezed
abstract class PackEjercicio with _$PackEjercicio {
  const PackEjercicio._();

  const factory PackEjercicio({
    required String id,
    required String packId,
    required String ejercicioId,
    required int orden,
    @JsonKey(name: 'descanso_seg') int? descansoSeg,
    double? minutos,

    /// El ejercicio de la biblioteca, incrustado por la consulta. Es quien dice
    /// como se llama y si esta dado de baja.
    @JsonKey(name: 'ejercicios') Ejercicio? ejercicio,
    @Default([]) @JsonKey(name: 'pack_series') List<PackSerie> series,
  }) = _PackEjercicio;

  factory PackEjercicio.fromJson(Map<String, dynamic> json) =>
      _$PackEjercicioFromJson(json);

  /// Las series en su orden.
  List<PackSerie> get seriesOrdenadas =>
      [...series]..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie));

  /// Un ejercicio dado de baja se queda en el pack pero **no se copia** al
  /// aplicarlo: la regla de dominio dice que no se anade a bloques nuevos.
  bool get estaDeBaja => !(ejercicio?.estado.esActivo ?? true);

  /// Si el entrenador dejo algo preparado, o es solo el ejercicio.
  bool get tieneAlgoPreparado => series.isNotEmpty || minutos != null;
}

/// Una serie preconfigurada de un ejercicio del pack.
///
/// Es la hermana de `SeriePlanificada`, sin `ejercicioPlanificadoId`: aqui
/// cuelga del pack, no de una semana concreta.
@freezed
abstract class PackSerie with _$PackSerie {
  const factory PackSerie({
    required String id,
    required String packEjercicioId,
    required int numeroSerie,
    required int repeticiones,
    double? peso,
    int? rir,
  }) = _PackSerie;

  factory PackSerie.fromJson(Map<String, dynamic> json) =>
      _$PackSerieFromJson(json);
}

/// Lo que devuelve aplicar un pack a un bloque.
///
/// Los ejercicios dados de baja se omiten, y se dice **cuantos**: omitirlos en
/// silencio dejaria un bloque con menos ejercicios sin ninguna explicacion. Es
/// el mismo criterio que al duplicar una semana.
class ResultadoAplicarPack {
  const ResultadoAplicarPack({
    required this.ejerciciosAnadidos,
    required this.ejerciciosOmitidos,
  });

  factory ResultadoAplicarPack.fromJson(Map<String, dynamic> json) =>
      ResultadoAplicarPack(
        ejerciciosAnadidos: (json['ejercicios_anadidos'] as num?)?.toInt() ?? 0,
        ejerciciosOmitidos: (json['ejercicios_omitidos'] as num?)?.toInt() ?? 0,
      );

  final int ejerciciosAnadidos;
  final int ejerciciosOmitidos;

  bool get hayOmitidos => ejerciciosOmitidos > 0;
}
