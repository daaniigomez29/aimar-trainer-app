/// Como se escriben las cifras del informe, igual en la pantalla y en el PDF.
library;

import 'package:aimar_trainer_app/features/progreso/domain/resumen_sesion.dart';

/// `22,5`, `15`. Coma decimal y sin ceros sobrantes.
String kg(double valor) {
  final redondeado = (valor * 10).round() / 10;
  final texto = redondeado == redondeado.truncateToDouble()
      ? redondeado.toStringAsFixed(0)
      : redondeado.toStringAsFixed(1);
  return texto.replaceAll('.', ',');
}

/// `19.125`: miles con punto, para el volumen.
String miles(double valor) {
  final entero = valor.round().abs().toString();
  final grupos = <String>[];
  for (var fin = entero.length; fin > 0; fin -= 3) {
    grupos.insert(0, entero.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return '${valor < 0 ? '-' : ''}${grupos.join('.')}';
}

/// `93 %`, o un guion si no hay nada con que calcularlo.
String porcentaje(double? valor) => valor == null ? '-' : '${valor.round()} %';

/// `+16,1 %`, con signo: es una diferencia.
String diferencia(double valor, {String unidad = '%'}) =>
    '${valor > 0 ? '+' : ''}${kg(valor)} $unidad';

String decimal(double? valor) =>
    valor == null ? '-' : valor.toStringAsFixed(1).replaceAll('.', ',');

/// `09/11/2026`.
String fecha(DateTime dia) => '${_dos(dia.day)}/${_dos(dia.month)}/${dia.year}';

/// `09/11`, para los ejes de las graficas.
String fechaCorta(DateTime dia) => '${_dos(dia.day)}/${_dos(dia.month)}';

String _dos(int n) => n.toString().padLeft(2, '0');

/// `36 kg x 10`, o `8 kg/lado x 10`.
String serie(double peso, int repeticiones, {required bool porLado}) =>
    '${kg(peso)} kg${porLado ? '/lado' : ''} x $repeticiones';

/// Respecto a que es una [Mejora], ya con la preposicion para seguir a
/// "respecto": "a la semana pasada", "al 01/10" o, si no se sabe el dia,
/// "a la última vez".
String respectoA(Mejora mejora) => mejora.deLaSemanaPasada
    ? 'a la semana pasada'
    : switch (mejora.fechaAnterior) {
        final dia? => 'al ${fechaCorta(dia)}',
        null => 'a la última vez',
      };

/// "kg", "kg/lado", "reps" o "min", segun lo que se haya mejorado.
String unidadDe(Mejora mejora) => switch (mejora.tipo) {
  TipoDeMejora.peso => mejora.porLado ? 'kg/lado' : 'kg',
  TipoDeMejora.repeticiones => 'reps',
  TipoDeMejora.minutos => 'min',
};
