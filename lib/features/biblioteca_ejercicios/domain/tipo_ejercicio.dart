import 'package:json_annotation/json_annotation.dart';

/// Determina si el ejercicio se planifica con series (Fuerza) o con minutos
/// (Cardio). Se corresponde 1:1 con el enum `tipo_ejercicio` de Postgres.
///
/// Su efecto completo aparece en la fase 4 (`ejercicios_planificados`), donde
/// Fuerza y Cardio son mutuamente excluyentes, pero ya se elige aqui porque es
/// un atributo del ejercicio de la biblioteca, no de su planificacion.
@JsonEnum(fieldRename: FieldRename.snake)
enum TipoEjercicio {
  fuerza,
  cardio;

  bool get esFuerza => this == TipoEjercicio.fuerza;
  bool get esCardio => this == TipoEjercicio.cardio;

  /// Etiqueta para la interfaz.
  String get etiqueta => switch (this) {
    TipoEjercicio.fuerza => 'Fuerza',
    TipoEjercicio.cardio => 'Cardio',
  };

  /// Como se planifica este tipo, para explicarlo en el formulario.
  String get descripcionPlanificacion => switch (this) {
    TipoEjercicio.fuerza =>
      'Se planifica con series, repeticiones, peso y RIR.',
    TipoEjercicio.cardio => 'Se planifica con minutos.',
  };
}
