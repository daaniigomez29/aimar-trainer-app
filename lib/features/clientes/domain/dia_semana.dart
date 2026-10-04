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

  /// Equivalente en `DateTime.weekday`: el enum va de lunes a domingo, igual que
  /// `DateTime.monday` (1) a `DateTime.sunday` (7).
  int get numeroDeDateTime => index + 1;

  /// Ultima fecha en la que cayo este dia, contando hoy.
  ///
  /// Es la fecha sobre la que se ofrece el control semanal (medidas y check-in):
  /// el dia preferido es una preferencia recurrente, y lo que se registra necesita
  /// una fecha concreta.
  DateTime ultimaFecha({DateTime? hoy}) {
    final referencia = hoy ?? DateTime.now();
    final dia = DateTime(referencia.year, referencia.month, referencia.day);
    final diferencia = (dia.weekday - numeroDeDateTime + 7) % 7;
    return dia.subtract(Duration(days: diferencia));
  }

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
