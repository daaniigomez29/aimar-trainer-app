import 'package:json_annotation/json_annotation.dart';

/// Dia recomendado para que el cliente registre medidas y check-in.
///
/// Es una preferencia recurrente, no una fecha: por eso es un enum y no un
/// `date`, al contrario que la fecha de una sesion de entrenamiento. Se
/// corresponde 1:1 con el enum `dia_semana` de Postgres (sin tildes, como las
/// etiquetas del enum SQL).
@JsonEnum(fieldRename: FieldRename.snake)
enum DiaSemana {
  lunes,
  martes,
  miercoles,
  jueves,
  viernes,
  sabado,
  domingo;

  /// Etiqueta para la interfaz, esta si acentuada.
  String get etiqueta => switch (this) {
    DiaSemana.lunes => 'Lunes',
    DiaSemana.martes => 'Martes',
    DiaSemana.miercoles => 'Miércoles',
    DiaSemana.jueves => 'Jueves',
    DiaSemana.viernes => 'Viernes',
    DiaSemana.sabado => 'Sábado',
    DiaSemana.domingo => 'Domingo',
  };
}
