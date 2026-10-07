/// La semana de lunes a domingo a la que pertenece una fecha.
///
/// POR QUE EXISTE: un planning es **de una semana**, no de un dia, pero eso
/// estaba repartido en copias del mismo calculo (la navegacion de la pantalla
/// del entrenador y el formulario de crear planning tenian cada una la suya) y
/// nada impedia que se separasen.
///
/// Lo importante para la interfaz: **cualquier dia vale para nombrar su
/// semana**. Si el entrenador elige el miercoles 14 en el calendario, la semana
/// es la del 12 al 18; no hay que obligarle a acertar con el lunes.
class Semana {
  /// La semana a la que pertenece [fecha]. La hora se descarta.
  factory Semana.de(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return Semana._(_sumarDias(dia, 1 - dia.weekday));
  }

  /// La semana en la que se esta hoy.
  factory Semana.deHoy() => Semana.de(DateTime.now());

  const Semana._(this.lunes);

  /// Primer dia, a las 00:00. Es la `fechaInicio` del planning.
  final DateTime lunes;

  DateTime get domingo => _sumarDias(lunes, 6);

  Semana get anterior => Semana._(_sumarDias(lunes, -7));
  Semana get siguiente => Semana._(_sumarDias(lunes, 7));

  /// Suma dias **de calendario**, que no es lo mismo que sumar 24 horas.
  ///
  /// POR QUE NO `add(Duration(days: n))`: un `Duration` son horas absolutas, y
  /// la noche en que cambia la hora dura 23 o 25. Con el cambio de octubre de
  /// 2026, sumar siete "dias" al lunes 19 caia en el **domingo 25 a las 23:00**,
  /// que es la misma semana: la flecha de siguiente se quedaba clavada ahi. En
  /// marzo pasaba al reves y la de anterior se saltaba una semana entera.
  ///
  /// `DateTime(ano, mes, dia + n)` normaliza por calendario —acepta de sobra
  /// dias fuera de rango, como el 38 de octubre— y siempre cae a medianoche de
  /// la zona, que es justo lo que es el primer dia de una semana.
  static DateTime _sumarDias(DateTime dia, int dias) =>
      DateTime(dia.year, dia.month, dia.day + dias);

  bool contiene(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return !dia.isBefore(lunes) && !dia.isAfter(domingo);
  }

  /// "12-18 oct", o "28 sep - 4 oct" cuando la semana cambia de mes.
  ///
  /// Con el calendario se salta a semanas lejanas, y a caballo entre dos meses
  /// un solo nombre de mes se lee mal: no se sabe a cual de los dos pertenece
  /// cada numero.
  String get etiqueta => lunes.month == domingo.month
      ? '${lunes.day}-${domingo.day} ${mesAbreviado(domingo)}'
      : '${lunes.day} ${mesAbreviado(lunes)} - '
            '${domingo.day} ${mesAbreviado(domingo)}';

  @override
  bool operator ==(Object other) => other is Semana && other.lunes == lunes;

  @override
  int get hashCode => lunes.hashCode;

  @override
  String toString() => 'Semana(${lunes.toIso8601String()})';
}

String mesAbreviado(DateTime fecha) => const [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
][fecha.month - 1];
