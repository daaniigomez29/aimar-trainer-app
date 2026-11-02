import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

/// Lo que un cliente registro un dia de control: medidas, check-in o las dos.
///
/// Son **dos guardados independientes** y sin relacion en la base (entidades 9 y
/// 10): el cliente puede guardar las medidas y abandonar antes del check-in. Por
/// eso se unen aqui por fecha: un dia con solo medidas tambien es un control, y
/// si solo se listaran los check-in, esas medidas no se podrian consultar.
class ControlDelDia {
  const ControlDelDia({required this.fecha, this.medidas, this.checkin});

  final DateTime fecha;
  final RegistroMedidas? medidas;
  final CheckinRecuperacion? checkin;
}

DateTime _soloDia(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

/// Une medidas y check-in por dia, de lo mas reciente a lo mas antiguo.
List<ControlDelDia> unirControles({
  required List<RegistroMedidas> medidas,
  required List<CheckinRecuperacion> checkins,
}) {
  final medidasPorDia = {for (final m in medidas) _soloDia(m.fecha): m};
  final checkinsPorDia = {for (final c in checkins) _soloDia(c.fecha): c};
  final dias = {...medidasPorDia.keys, ...checkinsPorDia.keys}.toList()
    ..sort((a, b) => b.compareTo(a));

  return [
    for (final dia in dias)
      ControlDelDia(
        fecha: dia,
        medidas: medidasPorDia[dia],
        checkin: checkinsPorDia[dia],
      ),
  ];
}

/// Los controles de la lista cuyo mes es el de [mes].
List<ControlDelDia> controlesDelMes(
  List<ControlDelDia> controles,
  DateTime mes,
) => controles
    .where((c) => c.fecha.year == mes.year && c.fecha.month == mes.month)
    .toList();

/// El dia 1 del mes de [fecha]. Es como se representa "un mes".
DateTime mesDe(DateTime fecha) => DateTime(fecha.year, fecha.month);

/// El mes [meses] despues de [mes] (o antes, si es negativo). `DateTime`
/// normaliza el desbordamiento: el mes 13 de 2026 es enero de 2027.
DateTime mesSumando(DateTime mes, int meses) =>
    DateTime(mes.year, mes.month + meses);

/// "Noviembre de 2026".
String etiquetaDeMes(DateTime mes) {
  const nombres = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${nombres[mes.month - 1]} de ${mes.year}';
}
