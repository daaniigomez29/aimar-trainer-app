import 'package:json_annotation/json_annotation.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';

/// Musculo concreto de la taxonomia (segundo nivel). Se corresponde 1:1 con el
/// enum `musculo` de Postgres, y cada valor **sabe a que grupo pertenece**: de
/// ahi sale el grupo de un ejercicio, sin guardarlo por duplicado.
///
/// La lista la fijo el entrenador. Anadir un musculo es una migracion de una
/// linea (`alter type musculo add value`) mas un valor aqui; **quitarlo o
/// renombrarlo obliga a recrear el tipo en Postgres**, asi que no es una lista
/// para ir tocando a la ligera.
///
/// [etiqueta] es la version corta, para los chips del filtro;
/// [etiquetaCompleta] la anatomica, para la ficha, donde hay sitio.
enum Musculo {
  // Pierna
  cuadriceps('cuadriceps', 'Cuádriceps', GrupoMuscular.pierna),
  isquiotibiales('isquiotibiales', 'Isquiotibiales', GrupoMuscular.pierna),
  gluteo('gluteo', 'Glúteo', GrupoMuscular.pierna),
  aductores('aductores', 'Aductores', GrupoMuscular.pierna),
  abductores('abductores', 'Abductores', GrupoMuscular.pierna),
  gemelo('gemelo', 'Gemelo', GrupoMuscular.pierna),

  // Pecho
  porcionEsternoClavicular(
    'porcion_esterno_clavicular',
    'Esterno-clavicular',
    GrupoMuscular.pecho,
    etiquetaLarga: 'Porción esterno-clavicular',
  ),
  porcionEsternoCostal(
    'porcion_esterno_costal',
    'Esterno-costal',
    GrupoMuscular.pecho,
    etiquetaLarga: 'Porción esterno-costal',
  ),

  // Espalda
  dorsalAncho('dorsal_ancho', 'Dorsal ancho', GrupoMuscular.espalda),
  trapecio('trapecio', 'Trapecio', GrupoMuscular.espalda),
  romboides('romboides', 'Romboides', GrupoMuscular.espalda),
  lumbar('lumbar', 'Lumbar', GrupoMuscular.espalda),

  // Hombro
  deltoidesAnterior(
    'deltoides_anterior',
    'Deltoides anterior',
    GrupoMuscular.hombro,
  ),
  deltoidesLateral(
    'deltoides_lateral',
    'Deltoides lateral',
    GrupoMuscular.hombro,
  ),
  deltoidesPosterior(
    'deltoides_posterior',
    'Deltoides posterior',
    GrupoMuscular.hombro,
  ),

  // Brazo
  biceps('biceps', 'Bíceps', GrupoMuscular.brazo),
  triceps('triceps', 'Tríceps', GrupoMuscular.brazo),
  antebrazo('antebrazo', 'Antebrazo', GrupoMuscular.brazo),

  // Core
  rectoAbdominal('recto_abdominal', 'Recto abdominal', GrupoMuscular.core),
  oblicuos('oblicuos', 'Oblicuos', GrupoMuscular.core),
  transverso('transverso', 'Transverso', GrupoMuscular.core);

  const Musculo(
    this.valorJson,
    this.etiqueta,
    this.grupo, {
    this.etiquetaLarga,
  });

  final String valorJson;

  /// Version corta, la que va en los chips del filtro.
  final String etiqueta;

  final GrupoMuscular grupo;

  /// Solo los musculos cuyo nombre anatomico no cabe en un chip la declaran.
  final String? etiquetaLarga;

  /// Nombre anatomico completo, para la ficha. Igual a [etiqueta] salvo en los
  /// dos del pecho, donde "Porción esterno-clavicular" no cabe en un chip.
  String get etiquetaCompleta => etiquetaLarga ?? etiqueta;

  /// "Pierna · Cuádriceps", para listados donde el grupo no se ve.
  String get etiquetaConGrupo => '${grupo.etiqueta} · $etiqueta';

  static Musculo? porValorJson(String? valor) {
    if (valor == null) return null;
    for (final musculo in Musculo.values) {
      if (musculo.valorJson == valor) return musculo;
    }
    return null;
  }

  /// Los de un grupo, en el orden de declaracion (el que dio el entrenador).
  static List<Musculo> delGrupo(GrupoMuscular grupo) =>
      Musculo.values.where((musculo) => musculo.grupo == grupo).toList();
}

/// Conversor del musculo principal.
///
/// POR QUE A MANO y no `@JsonEnum`: lo generado lanza si encuentra un valor que
/// no conoce, y eso tumbaria el parseo de **toda** la biblioteca (no solo de esa
/// fila) el dia que una migracion anada un musculo al enum de Postgres antes de
/// que la app se despliegue. Asi un valor desconocido se queda en `null`, el
/// ejercicio aparece sin clasificar y el entrenador lo ve en el chip "Sin
/// clasificar".
class ConversorMusculo implements JsonConverter<Musculo?, String?> {
  const ConversorMusculo();

  @override
  Musculo? fromJson(String? json) => Musculo.porValorJson(json);

  @override
  String? toJson(Musculo? objeto) => objeto?.valorJson;
}

/// Conversor de la lista de secundarios. Descarta en silencio lo que no
/// reconozca, por el mismo motivo que [ConversorMusculo].
class ConversorMusculos
    implements JsonConverter<List<Musculo>, List<dynamic>?> {
  const ConversorMusculos();

  @override
  List<Musculo> fromJson(List<dynamic>? json) => (json ?? const [])
      .map((valor) => Musculo.porValorJson(valor as String?))
      .nonNulls
      .toList();

  @override
  List<dynamic> toJson(List<Musculo> objeto) =>
      objeto.map((musculo) => musculo.valorJson).toList();
}

/// Conversor del grupo guardado a mano, con el mismo criterio.
class ConversorGrupoMuscular implements JsonConverter<GrupoMuscular?, String?> {
  const ConversorGrupoMuscular();

  @override
  GrupoMuscular? fromJson(String? json) => GrupoMuscular.porValorJson(json);

  @override
  String? toJson(GrupoMuscular? objeto) => objeto?.valorJson;
}
