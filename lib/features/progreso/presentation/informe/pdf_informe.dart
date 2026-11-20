import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:aimar_trainer_app/features/progreso/domain/informe_progresion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/informe/formato_informe.dart';

/// Lo que lleva el PDF ademas de las cifras: lo que escribe el entrenador.
class DatosPdfInforme {
  const DatosPdfInforme({
    required this.nombreCliente,
    required this.informe,
    required this.emitido,
    this.resumen = '',
    this.valoracion = '',
    this.proximosPasos = '',
    this.mesociclos = const [],
  });

  final String nombreCliente;
  final InformeProgresion informe;
  final DateTime emitido;

  /// Texto libre de Aimar. Lo que no sale de los datos (molestias, contexto,
  /// objetivos) lo pone el, no la app: un informe automatico solo puede decir
  /// lo que dicen los registros. Vacio, no sale.
  ///
  /// El [resumen] va como texto corrido antes de las cifras; la [valoracion] y
  /// los [proximosPasos], destacados en un recuadro. Ver [parrafosDe] para lo
  /// que admiten (parrafos y listas).
  final String resumen;
  final String valoracion;
  final String proximosPasos;

  /// Vacio, el informe no habla de mesociclos.
  final List<TextoMesociclo> mesociclos;

  String get nombreArchivo =>
      'Informe de progresión - $nombreCliente - '
      '${emitido.year}-${_dos(emitido.month)}-${_dos(emitido.day)}.pdf';
}

/// Un mesociclo con lo que escribe de el el entrenador.
class TextoMesociclo {
  const TextoMesociclo({
    required this.mesociclo,
    this.foco = '',
    this.hitos = '',
  });

  final Mesociclo mesociclo;
  final String foco;
  final String hitos;

  bool get tieneTexto => foco.trim().isNotEmpty || hitos.trim().isNotEmpty;
}

/// El texto tal como lo puede dibujar el PDF.
///
/// POR QUE: la fuente del PDF (Helvetica, la estandar) solo tiene Latin-1, y
/// lo que no esta ahi **desaparece sin avisar**. El teclado del movil escribe
/// comillas tipograficas, rayas y flechas sin que uno lo note, asi que se
/// cambian por su equivalente; lo que no tiene, por `?`, para que se vea que
/// falta algo en vez de perderse.
String paraPdf(String texto) {
  final salida = StringBuffer();
  for (final rune in texto.runes) {
    if (rune <= 0xFF) {
      salida.writeCharCode(rune);
      continue;
    }
    salida.write(switch (rune) {
      0x2018 || 0x2019 || 0x201A || 0x201B || 0x2032 => "'",
      0x201C || 0x201D || 0x201E || 0x2033 => '"',
      0x2010 || 0x2011 || 0x2012 || 0x2013 || 0x2014 || 0x2015 || 0x2212 => '-',
      0x2026 => '...',
      0x2022 || 0x25CF || 0x25E6 => '·',
      0x2192 || 0x2794 || 0x279C || 0x27A1 || 0x21D2 || 0x2799 => '->',
      0x2190 => '<-',
      0x2264 => '<=',
      0x2265 => '>=',
      0x2248 => '~',
      0x00A0 || 0x2009 || 0x202F || 0x2002 || 0x2003 => ' ',
      0x0141 => 'L',
      0x0142 => 'l',
      0x0152 => 'OE',
      0x0153 => 'oe',
      0x0160 => 'S',
      0x0161 => 's',
      0x017D => 'Z',
      0x017E => 'z',
      0x010C => 'C',
      0x010D => 'c',
      0x011B => 'e',
      0x0159 => 'r',
      _ => '?',
    });
  }
  return salida.toString();
}

/// Cuantos ejercicios entran en la grafica de inicio frente a final: los que
/// mas han mejorado. La tabla de debajo los lleva todos.
const int ejerciciosEnGrafica = 8;

// Colores de impresion: el tema de la app es oscuro, el PDF va sobre blanco.
final _acento = PdfColor.fromInt(0xFF1C85FF);
final _mejora = PdfColor.fromInt(0xFF16A34A);
final _plan = PdfColor.fromInt(0xFFCBD5E1);
final _texto = PdfColor.fromInt(0xFF111827);
final _suave = PdfColor.fromInt(0xFF6B7280);
final _linea = PdfColor.fromInt(0xFFE5E7EB);
final _fondoTarjeta = PdfColor.fromInt(0xFFF3F6FA);

/// Ancho util de un A4 con los margenes de abajo.
const double _anchoUtil = 595.28 - 2 * 40;

Future<Uint8List> generarPdfInforme(DatosPdfInforme datos) {
  final informe = datos.informe;
  // Con un solo mesociclo, marcar cada semana con su numero no aporta nada.
  final mesocicloDe = datos.mesociclos.length < 2
      ? const <String, int>{}
      : {
          for (final texto in datos.mesociclos)
            for (final semana in texto.mesociclo.semanas)
              semana.planningId: texto.mesociclo.numero,
        };
  final documento = pw.Document(
    title: 'Informe de progresión - ${datos.nombreCliente}',
    author: 'AimarTrainer',
  );

  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 40),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 9.5, color: _texto)),
      footer: (contexto) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'AIMAR TRAINER · Informe de progresión · '
            '${paraPdf(datos.nombreCliente)}',
            style: pw.TextStyle(fontSize: 8, color: _suave),
          ),
          pw.Text(
            'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _suave),
          ),
        ],
      ),
      build: (contexto) => [
        _cabecera(datos),
        pw.SizedBox(height: 18),
        _titulo('Resumen del periodo'),
        if (datos.resumen.trim().isNotEmpty) ...[
          ...parrafosDe(datos.resumen),
          pw.SizedBox(height: 10),
        ],
        _tarjetas(informe),
        if (datos.valoracion.trim().isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _textoDelEntrenador('Valoración del entrenador', datos.valoracion),
        ],
        pw.SizedBox(height: 18),
        _titulo('Evolución semanal'),
        _graficaVolumen(informe.semanas, mesocicloDe),
        pw.SizedBox(height: 10),
        _tablaSemanas(informe.semanas, mesocicloDe),
        if (_conAnalisisDeMesociclos(datos)) ...[
          pw.SizedBox(height: 18),
          _titulo('Análisis por mesociclos'),
          for (final texto in datos.mesociclos) ..._mesociclo(texto),
        ],
        if (informe.inicioFinal.isNotEmpty) ...[
          // En pagina propia: si no, el titulo se queda solo al pie de la
          // anterior y la grafica pasa a la siguiente.
          pw.NewPage(),
          _titulo('Progresión de cargas'),
          pw.Text(
            'Primera serie de trabajo planificada frente a la mejor '
            'serie hecha en la última sesión de cada ejercicio.',
            style: pw.TextStyle(color: _suave),
          ),
          if (_conMejora(informe).isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _graficaInicioFinal(_conMejora(informe)),
          ],
          pw.SizedBox(height: 12),
          ..._tablasPorGrupo(informe),
        ],
        if (datos.proximosPasos.trim().isNotEmpty) ...[
          pw.SizedBox(height: 18),
          _textoDelEntrenador('Próximos pasos', datos.proximosPasos),
        ],
        pw.SizedBox(height: 18),
        _notas(),
      ],
    ),
  );

  return documento.save();
}

pw.Widget _cabecera(DatosPdfInforme datos) {
  final semanas = datos.informe.semanas;
  final mesociclos = datos.mesociclos.length;
  final periodo = semanas.isEmpty
      ? 'Sin semanas'
      : [
          'Del ${fecha(semanas.first.semana)} al '
              '${fecha(semanas.last.semana.add(const Duration(days: 6)))}',
          '${semanas.length} ${semanas.length == 1 ? 'semana' : 'semanas'}',
          if (mesociclos > 0)
            '$mesociclos ${mesociclos == 1 ? 'mesociclo' : 'mesociclos'}',
        ].join(' · ');

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      color: _acento,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _marca(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Informe de progresión de entrenamiento',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Cliente: ${paraPdf(datos.nombreCliente)}',
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 13),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          '$periodo · Emitido el ${fecha(datos.emitido)}',
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
        ),
      ],
    ),
  );
}

/// "A I M A R   T R A I N E R": cada palabra espaciada letra a letra y con
/// mas aire entre las dos, para que se lean como dos palabras y no como una
/// fila de letras sueltas.
pw.Widget _marca() {
  final estilo = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 9,
    letterSpacing: 3,
    fontWeight: pw.FontWeight.bold,
  );
  return pw.Row(
    children: [
      pw.Text('AIMAR', style: estilo),
      pw.SizedBox(width: 10),
      pw.Text('TRAINER', style: estilo),
    ],
  );
}

/// El texto libre del entrenador, maquetado.
///
/// Admite lo justo para escribir como en el informe que Aimar hacia a mano:
/// - una linea en blanco separa parrafos;
/// - una linea que empieza por `-`, `*` o `•` es un punto de una lista;
/// - en un punto, lo que va antes de los primeros dos puntos, si es corto,
///   sale en negrita ("Volumen total: entre 17.900 y 20.400 kg").
List<pw.Widget> parrafosDe(String texto) {
  final widgets = <pw.Widget>[];
  final parrafo = <String>[];

  void cerrarParrafo() {
    if (parrafo.isEmpty) return;
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          parrafo.join(' '),
          style: const pw.TextStyle(lineSpacing: 2),
        ),
      ),
    );
    parrafo.clear();
  }

  for (final linea in paraPdf(texto).trim().split('\n').map((l) => l.trim())) {
    final punto = RegExp(r'^[-*·]\s*').firstMatch(linea);
    if (linea.isEmpty) {
      cerrarParrafo();
    } else if (punto != null) {
      cerrarParrafo();
      widgets.add(_punto(linea.substring(punto.end)));
    } else {
      parrafo.add(linea);
    }
  }
  cerrarParrafo();
  return widgets;
}

pw.Widget _punto(String texto) {
  final dosPuntos = texto.indexOf(':');
  final conEtiqueta = dosPuntos > 0 && dosPuntos <= 40;
  return pw.Padding(
    padding: const pw.EdgeInsets.only(left: 6, bottom: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 4, right: 8),
          decoration: pw.BoxDecoration(
            color: _acento,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(lineSpacing: 2),
              children: [
                if (conEtiqueta)
                  pw.TextSpan(
                    text: texto.substring(0, dosPuntos + 1),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                pw.TextSpan(
                  text: conEtiqueta ? texto.substring(dosPuntos + 1) : texto,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

bool _conAnalisisDeMesociclos(DatosPdfInforme datos) =>
    datos.mesociclos.length > 1 ||
    datos.mesociclos.any((texto) => texto.tieneTexto);

/// Un mesociclo: sus fechas, sus cifras y lo que escribe el entrenador.
List<pw.Widget> _mesociclo(TextoMesociclo texto) {
  final meso = texto.mesociclo;
  final semanas = meso.semanas.length;
  final volumen = meso.volumenMedioReal;
  final cifras = [
    'Sesiones ${meso.sesionesHechas}/${meso.sesionesPlanificadas} '
        '(${porcentaje(meso.pctSesiones)})',
    'Series ${meso.seriesHechas}/${meso.seriesPlanificadas} '
        '(${porcentaje(meso.pctSeries)})',
    'Volumen medio ${volumen == null ? '-' : '${miles(volumen)} kg'}',
    'RIR ${decimal(meso.rirMedioReal)} '
        '(plan ${decimal(meso.rirMedioPlanificado)})',
  ];

  pw.Widget apartado(String titulo, String contenido) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
        child: pw.Text(
          titulo,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
      ...parrafosDe(contenido),
    ],
  );

  return [
    // Nombre y cifras juntos: el nombre solo al pie de una pagina no se
    // entiende.
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 6),
          pw.Text(
            'Mesociclo ${meso.numero}',
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: _acento,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Del ${fecha(meso.inicio)} al ${fecha(meso.fin)} · '
            '$semanas ${semanas == 1 ? 'semana' : 'semanas'}',
            style: pw.TextStyle(color: _suave),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _fondoTarjeta,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              cifras.join('   ·   '),
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          pw.SizedBox(height: 4),
        ],
      ),
    ),
    if (texto.foco.trim().isNotEmpty) apartado('Foco principal', texto.foco),
    if (texto.hitos.trim().isNotEmpty) apartado('Hitos', texto.hitos),
    pw.SizedBox(height: 8),
  ];
}

pw.Widget _titulo(String texto) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 8),
  child: pw.Text(
    texto,
    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
  ),
);

pw.Widget _tarjetas(InformeProgresion informe) {
  pw.Widget tarjeta(String etiqueta, String valor, String detalle) =>
      pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _fondoTarjeta,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                etiqueta,
                style: pw.TextStyle(fontSize: 8, color: _suave),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                valor,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _acento,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(detalle, style: pw.TextStyle(fontSize: 8, color: _suave)),
            ],
          ),
        ),
      );

  final volumen = informe.volumenMedioReal;
  return pw.Row(
    children: [
      tarjeta(
        'Sesiones hechas',
        porcentaje(informe.pctSesiones),
        '${informe.sesionesHechas} de ${informe.sesionesPlanificadas}',
      ),
      tarjeta(
        'Series hechas',
        porcentaje(informe.pctSeries),
        '${informe.seriesHechas} de ${informe.seriesPlanificadas}',
      ),
      tarjeta(
        'Volumen medio semanal',
        volumen == null ? '-' : '${miles(volumen)} kg',
        'Peso x repeticiones, fuerza',
      ),
      tarjeta(
        'RIR medio',
        decimal(informe.rirMedioReal),
        'Planificado: ${decimal(informe.rirMedioPlanificado)}',
      ),
    ],
  );
}

/// Por encima de estos caracteres, un recuadro puede no caber en una pagina
/// y tiene que poder partirse.
const int _caracteresInseparables = 2500;

pw.Widget _textoDelEntrenador(String titulo, String texto) {
  final recuadro = pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border(left: pw.BorderSide(color: _acento, width: 3)),
      color: _fondoTarjeta,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...parrafosDe(texto),
      ],
    ),
  );
  // Entero en una pagina, si cabe: partido, deja una tira del recuadro al pie
  // de la anterior.
  return texto.length > _caracteresInseparables
      ? recuadro
      : pw.Inseparable(child: recuadro);
}

pw.Widget _leyenda(List<(PdfColor, String)> elementos) => pw.Row(
  children: [
    for (final (color, texto) in elementos) ...[
      pw.Container(width: 8, height: 8, color: color),
      pw.SizedBox(width: 4),
      pw.Text(texto, style: pw.TextStyle(fontSize: 8, color: _suave)),
      pw.SizedBox(width: 12),
    ],
  ],
);

/// Barras de volumen planificado y real por semana. Con [mesocicloDe], cada
/// semana dice a que mesociclo pertenece.
pw.Widget _graficaVolumen(
  List<ResumenSemana> semanas,
  Map<String, int> mesocicloDe,
) {
  const alto = 110.0;
  final maximo = semanas.fold<double>(
    0,
    (m, s) => [
      m,
      s.volumenPlanificado,
      s.volumenReal,
    ].reduce((a, b) => a > b ? a : b),
  );
  if (maximo == 0) {
    return pw.Text(
      'No hay series de fuerza con peso en estas semanas.',
      style: pw.TextStyle(color: _suave),
    );
  }
  final anchoBarra = (_anchoUtil / semanas.length / 2 - 8).clamp(6.0, 26.0);

  pw.Widget barra(double valor, PdfColor color) => pw.Container(
    width: anchoBarra,
    height: alto * valor / maximo,
    color: color,
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _leyenda([
        (_plan, 'Volumen planificado (kg)'),
        (_acento, 'Volumen real (kg)'),
      ]),
      pw.SizedBox(height: 8),
      pw.Container(
        height: alto + 30,
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _linea)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            for (final semana in semanas)
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    miles(semana.volumenReal),
                    style: pw.TextStyle(fontSize: 7, color: _suave),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      barra(semana.volumenPlanificado, _plan),
                      pw.SizedBox(width: 2),
                      barra(semana.volumenReal, _acento),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          for (final semana in semanas)
            pw.Column(
              children: [
                pw.Text(
                  fechaCorta(semana.semana),
                  style: pw.TextStyle(fontSize: 8, color: _suave),
                ),
                if (mesocicloDe[semana.planningId] case final meso?)
                  pw.Text(
                    'Meso $meso',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: _acento,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
        ],
      ),
    ],
  );
}

pw.Widget _tabla({
  required List<String> cabecera,
  required List<List<String>> filas,
  Map<int, pw.TableColumnWidth>? anchos,
}) => pw.TableHelper.fromTextArray(
  headers: cabecera,
  data: [
    for (final fila in filas) [for (final celda in fila) paraPdf(celda)],
  ],
  columnWidths: anchos,
  border: null,
  headerStyle: pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: _suave,
  ),
  headerDecoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _linea)),
  ),
  cellStyle: const pw.TextStyle(fontSize: 8.5),
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  rowDecoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _linea, width: 0.5)),
  ),
  cellAlignment: pw.Alignment.centerRight,
  cellAlignments: {0: pw.Alignment.centerLeft},
  headerAlignments: {0: pw.Alignment.centerLeft},
  headerAlignment: pw.Alignment.centerRight,
);

pw.Widget _tablaSemanas(
  List<ResumenSemana> semanas,
  Map<String, int> mesocicloDe,
) => _tabla(
  cabecera: [
    'Semana',
    if (mesocicloDe.isNotEmpty) 'Meso',
    'Sesiones',
    'Series',
    '% series',
    'Vol. plan. (kg)',
    'Vol. real (kg)',
    'RIR plan. / real',
    'Cardio (min)',
  ],
  filas: [
    for (final s in semanas)
      [
        fecha(s.semana),
        if (mesocicloDe.isNotEmpty) '${mesocicloDe[s.planningId] ?? '-'}',
        '${s.sesionesHechas} / ${s.sesionesPlanificadas}',
        '${s.seriesHechas} / ${s.seriesPlanificadas}',
        porcentaje(s.pctSeries),
        miles(s.volumenPlanificado),
        miles(s.volumenReal),
        '${decimal(s.rirMedioPlanificado)} / ${decimal(s.rirMedioReal)}',
        '${kg(s.minutosCardioHechos)} / ${kg(s.minutosCardioPlanificados)}',
      ],
  ],
);

/// Los que mas han mejorado, para la grafica. Sin los que siguen igual: una
/// barra junto a otra identica no dice nada.
List<InicioFinal> _conMejora(InformeProgresion informe) => informe.inicioFinal
    .where((e) => e.diferenciaKg > 0)
    .take(ejerciciosEnGrafica)
    .toList();

/// Barras horizontales: de donde partio cada ejercicio y donde acaba.
pw.Widget _graficaInicioFinal(List<InicioFinal> ejercicios) {
  const anchoNombre = 150.0;
  const anchoValor = 52.0;
  const anchoMaximo = _anchoUtil - anchoNombre - anchoValor - 8;
  final maximo = ejercicios.fold<double>(
    0,
    (m, e) => [m, e.inicio.peso, e.fin.peso].reduce((a, b) => a > b ? a : b),
  );

  pw.Widget barra(double peso, PdfColor color) => pw.Row(
    children: [
      pw.Container(
        width: maximo == 0 ? 0 : anchoMaximo * peso / maximo,
        height: 7,
        color: color,
      ),
      pw.SizedBox(width: 4),
      pw.Text(
        '${kg(peso)} kg',
        style: pw.TextStyle(fontSize: 7, color: _suave),
      ),
    ],
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _leyenda([(_plan, 'Inicio'), (_mejora, 'Final')]),
      pw.SizedBox(height: 8),
      for (final ejercicio in ejercicios)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: anchoNombre,
                child: pw.Text(
                  paraPdf(ejercicio.nombre),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    barra(ejercicio.inicio.peso, _plan),
                    pw.SizedBox(height: 2),
                    barra(ejercicio.fin.peso, _mejora),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Por encima de estas filas, la tabla de un grupo puede no caber en una
/// pagina y tiene que poder partirse.
const int _filasInseparables = 25;

List<pw.Widget> _tablasPorGrupo(InformeProgresion informe) => [
  for (final MapEntry(key: grupo, value: ejercicios)
      in informe.inicioFinalPorGrupo.entries)
    _grupo(grupo?.etiqueta ?? 'Sin clasificar', ejercicios),
];

/// El nombre del grupo con su tabla. Juntos, si caben: si no, el nombre se
/// queda solo al pie de una pagina y la tabla empieza en la siguiente.
pw.Widget _grupo(String nombre, List<InicioFinal> ejercicios) {
  final contenido = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
        child: pw.Text(
          nombre,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _acento),
        ),
      ),
      _tabla(
        cabecera: const [
          'Ejercicio',
          'Inicio',
          'Final',
          'Dif. kg',
          'Dif. %',
          '1RM est. (kg)',
        ],
        // Fijos, para que las tablas de cada grupo queden alineadas.
        anchos: const {
          0: pw.FlexColumnWidth(2.6),
          1: pw.FlexColumnWidth(1.3),
          2: pw.FlexColumnWidth(1.3),
          3: pw.FlexColumnWidth(0.8),
          4: pw.FlexColumnWidth(0.8),
          5: pw.FlexColumnWidth(1.1),
        },
        filas: [
          for (final e in ejercicios)
            [
              e.nombre,
              serie(
                e.inicio.peso,
                e.inicio.repeticiones,
                porLado: e.pesoPorLado,
              ),
              serie(e.fin.peso, e.fin.repeticiones, porLado: e.pesoPorLado),
              diferencia(e.diferenciaKg, unidad: 'kg'),
              diferencia(e.diferenciaPct),
              '${kg(e.inicio.rmEstimado)} a ${kg(e.fin.rmEstimado)}',
            ],
        ],
      ),
    ],
  );
  return ejercicios.length > _filasInseparables
      ? contenido
      : pw.Inseparable(child: contenido);
}

pw.Widget _notas() => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      'Cómo leer este informe',
      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 3),
    for (final nota in const [
      'Los datos son los que registra el cliente en la app al entrenar. Las '
          'semanas sin registrar no aparecen.',
      'Volumen: peso x repeticiones de los ejercicios de fuerza. Si el peso se '
          'indica por lado, cuenta el doble.',
      '1RM estimado: fórmula de Epley, peso x (1 + repeticiones / 30). Sirve '
          'para comparar un ejercicio consigo mismo, no entre ejercicios.',
      'En las máquinas, el peso es el de la carga de la máquina.',
    ])
      pw.Text('· $nota', style: pw.TextStyle(fontSize: 7.5, color: _suave)),
  ],
);

String _dos(int n) => n.toString().padLeft(2, '0');
