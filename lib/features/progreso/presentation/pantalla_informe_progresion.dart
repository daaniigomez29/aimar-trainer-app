import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_informe.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/informe_progresion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/informe/formato_informe.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/informe/pdf_informe.dart';

/// Informe de progresion en PDF de un cliente (solo el entrenador).
///
/// El entrenador dice desde que semana, cuantas y de cuantas semanas son sus
/// mesociclos; el reparto lo hace la app. Despues escribe lo que los datos no
/// pueden decir (resumen, valoracion, foco e hitos de cada mesociclo y
/// proximos pasos). La app pone el resto: cumplimiento, volumen, RIR y la
/// progresion de cada ejercicio.
class PantallaInformeProgresion extends ConsumerStatefulWidget {
  const PantallaInformeProgresion({required this.clienteId, super.key});

  final String clienteId;

  @override
  ConsumerState<PantallaInformeProgresion> createState() =>
      _PantallaInformeProgresionState();
}

/// Por encima de este porcentaje de series identicas al plan se avisa: puede
/// ser cumplimiento exacto, o series guardadas sin tocar los valores que
/// llegan rellenos con lo planificado.
const double _umbralIdenticas = 50;

/// Cuantas semanas puede abarcar un informe.
const int _duracionMaxima = 24;

/// Las longitudes de mesociclo que se ofrecen; 0 es no dividir. Aimar trabaja
/// sobre todo con mesociclos de 4 semanas.
const List<int> _longitudesDeMesociclo = [0, 1, 2, 3, 4, 5, 6, 8];

class _PantallaInformeProgresionState
    extends ConsumerState<PantallaInformeProgresion> {
  final _resumen = TextEditingController();
  final _valoracion = TextEditingController();
  final _proximosPasos = TextEditingController();

  /// Por numero de mesociclo. Se conservan aunque cambie el reparto: lo
  /// escrito para el "Mesociclo 2" sigue ahi si se cambia la duracion.
  final _focos = <int, TextEditingController>{};
  final _hitos = <int, TextEditingController>{};

  /// Lunes de la semana con la que empieza el informe. `null` hasta que el
  /// entrenador elige uno: de partida, la semana planificada de hace 8.
  DateTime? _desde;
  int _duracion = 8;
  int _semanasPorMesociclo = 4;
  bool _generando = false;

  @override
  void dispose() {
    for (final controlador in [
      _resumen,
      _valoracion,
      _proximosPasos,
      ..._focos.values,
      ..._hitos.values,
    ]) {
      controlador.dispose();
    }
    super.dispose();
  }

  TextEditingController _de(Map<int, TextEditingController> mapa, int n) =>
      mapa.putIfAbsent(n, TextEditingController.new);

  /// Las semanas que se pueden elegir: las ya empezadas, de la mas reciente a
  /// la mas antigua. Una semana futura no tiene nada que informar.
  List<PlanningSemanal> _semanasElegibles(List<PlanningSemanal> todas) {
    final hoy = DateTime.now();
    return todas.where((p) => !p.fechaInicio.isAfter(hoy)).toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
  }

  Future<void> _descargar(
    String nombreCliente,
    List<PlanningSemanal> periodo,
    DateTime desde,
  ) async {
    setState(() => _generando = true);
    try {
      final informe = await ref.read(
        informeProgresionProvider(clavePlannings(periodo.map((p) => p.id)))
            .future,
      );
      final datos = DatosPdfInforme(
        nombreCliente: nombreCliente,
        informe: informe,
        emitido: DateTime.now(),
        resumen: _resumen.text,
        valoracion: _valoracion.text,
        proximosPasos: _proximosPasos.text,
        mesociclos: _semanasPorMesociclo == 0
            ? const []
            : [
                for (final meso in mesociclosDe(
                  informe,
                  desde: desde,
                  semanasPorMesociclo: _semanasPorMesociclo,
                ))
                  TextoMesociclo(
                    mesociclo: meso,
                    foco: _de(_focos, meso.numero).text,
                    hitos: _de(_hitos, meso.numero).text,
                  ),
              ],
      );
      final bytes = await generarPdfInforme(datos);
      await ref
          .read(descargadorPdfProvider)
          .descargar(bytes, nombreArchivo: datos.nombreArchivo);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Avisos.duracion,
            content: Text(
              'No se ha podido generar el PDF. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plannings = ref.watch(planningsDeClienteProvider(widget.clienteId));
    final nombre =
        ref.watch(clientePorIdProvider(widget.clienteId)).value?.nombre ??
        'Cliente';

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.clientes,
      appBar: AppBar(title: const Text('Informe de progresión')),
      cuerpo: plannings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(mensajeDeErrorProgreso(error)),
          ),
        ),
        data: (todas) {
          final semanas = _semanasElegibles(todas);
          if (semanas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Este cliente todavía no tiene ninguna semana planificada.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // De partida, las ultimas 8 semanas: dos mesociclos de 4.
          final desde =
              _desde ??
              Semana.de(
                semanas[(_duracion - 1).clamp(0, semanas.length - 1)]
                    .fechaInicio,
              ).lunes;
          final periodo = planningsDelPeriodo(
            semanas,
            desde: desde,
            cuantas: _duracion,
          );
          final mesocicloDe = {
            for (final p in periodo)
              p.id: mesocicloDeLaSemana(
                p.fechaInicio,
                desde: desde,
                semanasPorMesociclo: _semanasPorMesociclo,
              ),
          };
          final mesociclos = mesocicloDe.values.toSet().toList()..sort();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(Tokens.margenPantalla),
                children: [
                  Text(nombre, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _EleccionDelPeriodo(
                    desde: desde,
                    primeraSemana: Semana.de(semanas.last.fechaInicio).lunes,
                    duracion: _duracion,
                    semanasPorMesociclo: _semanasPorMesociclo,
                    periodo: periodo,
                    mesocicloDe: mesocicloDe,
                    onDesde: (lunes) => setState(() => _desde = lunes),
                    onDuracion: (duracion) => setState(() {
                      // Fija el inicio que se esta viendo: si no, el de
                      // partida se recalcularia con la nueva duracion.
                      _desde = desde;
                      _duracion = duracion;
                    }),
                    onLongitud: (semanas) => setState(() {
                      _desde = desde;
                      _semanasPorMesociclo = semanas;
                    }),
                  ),
                  const SizedBox(height: 20),
                  _VistaPrevia(clave: clavePlannings(periodo.map((p) => p.id))),
                  const SizedBox(height: 24),
                  _LoQueAnadesTu(
                    resumen: _resumen,
                    valoracion: _valoracion,
                    proximosPasos: _proximosPasos,
                    mesociclos: [
                      if (_semanasPorMesociclo > 0)
                        for (final numero in mesociclos)
                          (
                            numero: numero,
                            semanas: [
                              for (final p in periodo)
                                if (mesocicloDe[p.id] == numero) p.fechaInicio,
                            ],
                            foco: _de(_focos, numero),
                            hitos: _de(_hitos, numero),
                          ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('boton_descargar_pdf'),
                    onPressed: periodo.isEmpty || _generando
                        ? null
                        : () => _descargar(nombre, periodo, desde),
                    icon: _generando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Descargar PDF'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Desde que semana, cuantas y de cuantas semanas son los mesociclos. Debajo,
/// como queda el reparto, solo para leerlo: lo calcula la app.
class _EleccionDelPeriodo extends StatelessWidget {
  const _EleccionDelPeriodo({
    required this.desde,
    required this.primeraSemana,
    required this.duracion,
    required this.semanasPorMesociclo,
    required this.periodo,
    required this.mesocicloDe,
    required this.onDesde,
    required this.onDuracion,
    required this.onLongitud,
  });

  /// Lunes de la semana de inicio.
  final DateTime desde;

  /// Lunes de la semana planificada mas antigua del cliente: antes no hay
  /// nada que informar.
  final DateTime primeraSemana;
  final int duracion;
  final int semanasPorMesociclo;

  /// Las que entran en el informe, de la mas antigua a la mas reciente.
  final List<PlanningSemanal> periodo;
  final Map<String, int> mesocicloDe;

  /// Recibe siempre un lunes.
  final ValueChanged<DateTime> onDesde;
  final ValueChanged<int> onDuracion;
  final ValueChanged<int> onLongitud;

  /// Vale cualquier dia: el informe empieza el lunes de su semana, como al
  /// elegir semana en el planning.
  Future<void> _elegirEnElCalendario(BuildContext context) async {
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: desde,
      firstDate: desde.isBefore(primeraSemana) ? desde : primeraSemana,
      lastDate: hoy,
      helpText: 'Semana de inicio del informe',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (elegido != null) onDesde(Semana.de(elegido).lunes);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fin = DateTime(desde.year, desde.month, desde.day + 7 * duracion - 1);
    final mesociclos = mesocicloDe.values.toSet().toList()..sort();

    Widget eleccion(String etiqueta, Widget desplegable) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: textos.bodySmall),
        desplegable,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Periodo', style: textos.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            eleccion(
              'Desde la semana del',
              // Calendario y no una lista: con meses de plannings, buscar la
              // semana en un desplegable era bajar sin fin.
              TextButton.icon(
                key: const Key('semana_de_inicio'),
                onPressed: () => _elegirEnElCalendario(context),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(fecha(desde)),
              ),
            ),
            eleccion(
              'Durante',
              DropdownButton<int>(
                key: const Key('duracion_informe'),
                value: duracion,
                onChanged: (valor) {
                  if (valor != null) onDuracion(valor);
                },
                items: [
                  for (var n = 1; n <= _duracionMaxima; n++)
                    DropdownMenuItem(
                      value: n,
                      child: Text('$n ${n == 1 ? 'semana' : 'semanas'}'),
                    ),
                ],
              ),
            ),
            eleccion(
              'Mesociclos de',
              DropdownButton<int>(
                key: const Key('semanas_por_mesociclo'),
                value: semanasPorMesociclo,
                onChanged: (valor) => onLongitud(valor ?? 0),
                items: [
                  for (final n in _longitudesDeMesociclo)
                    DropdownMenuItem(
                      value: n,
                      child: Text(
                        n == 0
                            ? 'Sin dividir'
                            : '$n ${n == 1 ? 'semana' : 'semanas'}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Tarjeta(
          key: const Key('reparto_del_periodo'),
          padding: const EdgeInsets.all(12),
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Del ${fecha(desde)} al ${fecha(fin)} · '
                '${periodo.length} de $duracion '
                '${duracion == 1 ? 'semana planificada' : 'semanas planificadas'}',
                style: textos.bodyMedium,
              ),
              if (semanasPorMesociclo > 0)
                for (final numero in mesociclos) ...[
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Mesociclo $numero:  ',
                          style: TextStyle(
                            color: Tokens.acento,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: [
                            for (final p in periodo)
                              if (mesocicloDe[p.id] == numero)
                                fechaCorta(p.fechaInicio),
                          ].join(', '),
                        ),
                      ],
                    ),
                    style: textos.bodySmall,
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

typedef _CamposDeMesociclo = ({
  int numero,
  List<DateTime> semanas,
  TextEditingController foco,
  TextEditingController hitos,
});

/// Los textos del entrenador, en el orden en que salen en el PDF.
class _LoQueAnadesTu extends StatelessWidget {
  const _LoQueAnadesTu({
    required this.resumen,
    required this.valoracion,
    required this.proximosPasos,
    required this.mesociclos,
  });

  final TextEditingController resumen;
  final TextEditingController valoracion;
  final TextEditingController proximosPasos;
  final List<_CamposDeMesociclo> mesociclos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    Widget campo(
      String clave,
      TextEditingController controlador,
      String etiqueta, {
      String? pista,
      int lineas = 3,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: Key(clave),
        controller: controlador,
        minLines: lineas,
        maxLines: lineas + 8,
        decoration: InputDecoration(
          labelText: etiqueta,
          hintText: pista,
          alignLabelWithHint: true,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lo que añades tú', style: textos.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Lo que no sale de los datos: molestias, contexto, objetivos. Lo que '
          'dejes vacío no aparece en el PDF. Una línea en blanco separa '
          'párrafos; una línea que empieza por "-" es un punto de una lista, y '
          'lo que pongas antes de ":" sale en negrita.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 12),
        campo(
          'campo_resumen',
          resumen,
          'Resumen del periodo',
          pista:
              'Va antes de las cifras, como texto normal. Ej.: Durante estas '
              'semanas ha mostrado una evolución muy sólida...\n'
              '- Volumen total: entre 17.900 y 20.400 kg por semana.',
          lineas: 4,
        ),
        campo(
          'campo_valoracion',
          valoracion,
          'Valoración del entrenador',
          pista: 'Sale destacada en un recuadro.',
        ),
        for (final meso in mesociclos) ...[
          const SizedBox(height: 4),
          Text(
            'Mesociclo ${meso.numero}',
            style: textos.titleSmall?.copyWith(color: Tokens.acento),
          ),
          Text(
            meso.semanas.isEmpty
                ? ''
                : 'Del ${fecha(meso.semanas.first)} al '
                      '${fecha(meso.semanas.last.add(const Duration(days: 6)))}'
                      ' · ${meso.semanas.length} '
                      '${meso.semanas.length == 1 ? 'semana' : 'semanas'}',
            style: textos.bodySmall,
          ),
          const SizedBox(height: 8),
          campo(
            'campo_foco_${meso.numero}',
            meso.foco,
            'Foco principal',
            pista: 'Ej.: Adaptación anatómica y bases técnicas.',
            lineas: 2,
          ),
          campo(
            'campo_hitos_${meso.numero}',
            meso.hitos,
            'Hitos',
            pista: 'Ej.: Resolución de las molestias en la rodilla.',
            lineas: 2,
          ),
        ],
        campo(
          'campo_proximos_pasos',
          proximosPasos,
          'Próximos pasos',
          lineas: 2,
        ),
      ],
    );
  }
}

/// Las cifras del informe antes de descargarlo, para comprobar que las semanas
/// elegidas son las que se querian.
class _VistaPrevia extends ConsumerWidget {
  const _VistaPrevia({required this.clave});

  final String clave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final informe = ref.watch(informeProgresionProvider(clave));

    return informe.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text(mensajeDeErrorProgreso(error)),
      data: (informe) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vista previa', style: textos.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Cifra(
                clave: 'cifra_sesiones',
                etiqueta: 'Sesiones hechas',
                valor: porcentaje(informe.pctSesiones),
                detalle:
                    '${informe.sesionesHechas} de '
                    '${informe.sesionesPlanificadas}',
              ),
              _Cifra(
                clave: 'cifra_series',
                etiqueta: 'Series hechas',
                valor: porcentaje(informe.pctSeries),
                detalle:
                    '${informe.seriesHechas} de ${informe.seriesPlanificadas}',
              ),
              _Cifra(
                clave: 'cifra_volumen',
                etiqueta: 'Volumen medio semanal',
                valor: informe.volumenMedioReal == null
                    ? '-'
                    : '${miles(informe.volumenMedioReal!)} kg',
                detalle: 'Fuerza',
              ),
              _Cifra(
                clave: 'cifra_rir',
                etiqueta: 'RIR medio',
                valor: decimal(informe.rirMedioReal),
                detalle: 'Plan: ${decimal(informe.rirMedioPlanificado)}',
              ),
            ],
          ),
          if ((informe.pctIdenticasAlPlan ?? 0) >= _umbralIdenticas) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('aviso_identicas'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Tokens.secundario.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Tokens.radioBoton),
                border: Border.all(color: Tokens.secundario),
              ),
              child: Text(
                'El ${porcentaje(informe.pctIdenticasAlPlan)} de las series '
                'hechas coincide exactamente con el plan (reps, peso y RIR). '
                'Puede ser cumplimiento exacto, o series guardadas sin tocar '
                'los valores que llegan rellenos. Tenlo en cuenta al valorar. '
                'Este aviso no sale en el PDF.',
                style: textos.bodySmall,
              ),
            ),
          ],
          if (informe.inicioFinal.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Mayores mejoras', style: textos.titleSmall),
            const SizedBox(height: 4),
            for (final e in informe.inicioFinal.take(ejerciciosEnGrafica))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(e.nombre, style: textos.bodyMedium)),
                    Text(
                      '${serie(e.inicio.peso, e.inicio.repeticiones, porLado: e.pesoPorLado)}'
                      '  →  '
                      '${serie(e.fin.peso, e.fin.repeticiones, porLado: e.pesoPorLado)}',
                      style: textos.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: Text(
                        diferencia(e.diferenciaPct),
                        textAlign: TextAlign.end,
                        style: textos.bodySmall?.copyWith(
                          color: e.diferenciaKg > 0
                              ? Tokens.exito
                              : e.diferenciaKg < 0
                              ? Tokens.peligro
                              : Tokens.textoSuave,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    required this.detalle,
  });

  final String clave;
  final String etiqueta;
  final String valor;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SizedBox(
      width: 170,
      child: Tarjeta(
        key: Key(clave),
        padding: const EdgeInsets.all(12),
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: textos.bodySmall),
            const SizedBox(height: 4),
            Text(
              valor,
              style: textos.titleLarge?.copyWith(color: Tokens.acento),
            ),
            Text(detalle, style: textos.bodySmall),
          ],
        ),
      ),
    );
  }
}
