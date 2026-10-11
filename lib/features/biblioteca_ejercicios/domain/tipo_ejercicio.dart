import 'package:json_annotation/json_annotation.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/modo_planificacion.dart';

/// Tipo de ejercicio de la biblioteca. Se corresponde 1:1 con el enum
/// `tipo_ejercicio` de Postgres.
///
/// Lo que decide como se planifica y se registra **no es el tipo, es su
/// [modo]**: Fuerza y Fortalecimiento van por series, Cardio por minutos. No se
/// pregunta por el tipo para eso, porque anadir un cuarto tipo volveria a
/// dejar ternarios que compilan y mienten (ver [ModoPlanificacion]).
///
/// Se elige aqui, en la biblioteca, y no en la planificacion, porque es un
/// atributo del ejercicio: la sentadilla es de Fuerza en cualquier planning.
@JsonEnum(fieldRename: FieldRename.snake)
enum TipoEjercicio {
  fuerza,
  cardio,

  /// Trabajo para clientes con una lesion: readaptacion y prevencion. Se
  /// planifica como Fuerza, con la diferencia practica de que casi siempre es
  /// peso corporal o goma, y ahi el peso y el RIR se dejan vacios.
  fortalecimiento;

  ModoPlanificacion get modo => switch (this) {
    TipoEjercicio.cardio => ModoPlanificacion.minutos,
    TipoEjercicio.fuerza ||
    TipoEjercicio.fortalecimiento => ModoPlanificacion.series,
  };

  bool get vaPorSeries => modo.esSeries;
  bool get vaPorMinutos => modo.esMinutos;

  /// Etiqueta para la interfaz.
  String get etiqueta => switch (this) {
    TipoEjercicio.fuerza => 'Fuerza',
    TipoEjercicio.cardio => 'Cardio',
    TipoEjercicio.fortalecimiento => 'Fortalecimiento',
  };

  /// Como se planifica este tipo, para explicarlo en el formulario.
  String get descripcionPlanificacion => switch (this) {
    TipoEjercicio.fuerza =>
      'Se planifica con series, repeticiones, peso y RIR.',
    TipoEjercicio.cardio => 'Se planifica con minutos.',
    TipoEjercicio.fortalecimiento =>
      'Se planifica con series, como Fuerza. El peso y el RIR pueden '
          'quedarse vacíos.',
  };
}
