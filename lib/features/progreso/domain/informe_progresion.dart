import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Informe de progresion de un cliente sobre las semanas que elige el
/// entrenador: lo que antes Aimar sacaba a mano con tres consultas SQL
/// (resumen semanal, progresion por ejercicio e inicio frente a final).
///
/// Se calcula **aqui, en Dart**, sobre los plannings completos que ya trae el
/// repositorio, y no con una vista o una RPC: asi no hace falta tocar la base
/// de datos y el calculo se prueba sin servidor.
///
/// Las reglas son las de aquellas consultas, para que las cifras coincidan:
/// - **Volumen** = peso x repeticiones, **x2 si el peso es por lado**. Solo
///   ejercicios de Fuerza: en el resto el peso no significa lo mismo.
/// - **RIR medio**, tambien solo de Fuerza.
/// - Las series se emparejan **por numero**: una planificada cuenta como hecha
///   si tiene su realizada. Las series de mas no cuentan en el cumplimiento.
/// - **1RM estimado** con la formula de Epley: peso x (1 + reps / 30). Sirve
///   para comparar un ejercicio consigo mismo, no entre ejercicios.
class InformeProgresion with CifrasDeSemanas {
  const InformeProgresion({
    required this.semanas,
    required this.ejercicios,
    required this.inicioFinal,
  });

  /// Una por planning, de la mas antigua a la mas reciente.
  @override
  final List<ResumenSemana> semanas;

  /// Evolucion semana a semana de cada ejercicio de Fuerza, por nombre.
  final List<ProgresionEjercicio> ejercicios;

  /// Primera serie de trabajo planificada frente a la ultima mejor serie hecha,
  /// de cada ejercicio de Fuerza con peso. Ordenada de mas a menos mejora.
  final List<InicioFinal> inicioFinal;

  bool get estaVacio => semanas.isEmpty;

  /// El [inicioFinal] repartido por grupo muscular, en el orden de la
  /// taxonomia; los sin clasificar, al final.
  Map<GrupoMuscular?, List<InicioFinal>> get inicioFinalPorGrupo {
    final porGrupo = <GrupoMuscular?, List<InicioFinal>>{};
    for (final grupo in [...GrupoMuscular.values, null]) {
      final suyos = inicioFinal.where((e) => e.grupo == grupo).toList();
      if (suyos.isNotEmpty) porGrupo[grupo] = suyos;
    }
    return porGrupo;
  }
}

/// Las cifras que se resumen igual para todo el periodo que para un
/// mesociclo: solo dependen de que semanas entran.
mixin CifrasDeSemanas {
  List<ResumenSemana> get semanas;

  int get sesionesPlanificadas =>
      semanas.fold(0, (total, s) => total + s.sesionesPlanificadas);
  int get sesionesHechas =>
      semanas.fold(0, (total, s) => total + s.sesionesHechas);
  int get seriesPlanificadas =>
      semanas.fold(0, (total, s) => total + s.seriesPlanificadas);
  int get seriesHechas => semanas.fold(0, (total, s) => total + s.seriesHechas);
  int get seriesIdenticasAlPlan =>
      semanas.fold(0, (total, s) => total + s.seriesIdenticasAlPlan);

  double? get pctSesiones => _porcentaje(sesionesHechas, sesionesPlanificadas);
  double? get pctSeries => _porcentaje(seriesHechas, seriesPlanificadas);

  /// Cuantas de las series hechas son **identicas al plan** en reps, peso y
  /// RIR. Los campos llegan rellenos con lo planificado, asi que un porcentaje
  /// muy alto puede ser cumplimiento exacto o series guardadas sin tocar: el
  /// entrenador tiene que saberlo antes de sacar conclusiones.
  double? get pctIdenticasAlPlan =>
      _porcentaje(seriesIdenticasAlPlan, seriesHechas);

  /// Volumen real medio por semana, contando solo las semanas con algo hecho.
  double? get volumenMedioReal {
    final conAlgo = semanas.where((s) => s.volumenReal > 0).toList();
    if (conAlgo.isEmpty) return null;
    return conAlgo.fold<double>(0, (t, s) => t + s.volumenReal) /
        conAlgo.length;
  }

  double? get rirMedioPlanificado =>
      _media(semanas.expand((s) => s.rirsPlanificados));
  double? get rirMedioReal => _media(semanas.expand((s) => s.rirsReales));
}

/// Un mesociclo: un bloque de semanas seguidas con un mismo objetivo.
///
/// Aimar planifica y valora por mesociclos (p. ej. 2 de 4 semanas), no semana
/// a semana. **No se guarda en la base de datos**: sale de la semana de inicio
/// del informe y de la longitud que elige el entrenador
/// ([mesocicloDeLaSemana]).
class Mesociclo with CifrasDeSemanas {
  const Mesociclo({required this.numero, required this.semanas});

  /// Desde 1, del mas antiguo al mas reciente.
  final int numero;

  /// Las semanas **con planning** del mesociclo. Puede tener menos de las que
  /// le tocan si alguna no se planifico.
  @override
  final List<ResumenSemana> semanas;

  DateTime get inicio => semanas.first.semana;

  /// Domingo de su ultima semana.
  DateTime get fin => semanas.last.semana.add(const Duration(days: 6));
}

/// Semanas enteras entre dos lunes, contando por dias de calendario: con
/// `Duration` un cambio de hora daria 6 dias y 23 horas.
int semanasEntre(DateTime desde, DateTime hasta) =>
    DateTime.utc(
      hasta.year,
      hasta.month,
      hasta.day,
    ).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays ~/
    7;

/// Los plannings de las [cuantas] semanas que empiezan en [desde], del mas
/// antiguo al mas reciente.
///
/// Si una semana tiene un planning activo y otro archivado (se rehizo), entra
/// el activo: contar los dos duplicaria esa semana.
List<PlanningSemanal> planningsDelPeriodo(
  List<PlanningSemanal> plannings, {
  required DateTime desde,
  required int cuantas,
}) {
  final porSemana = <int, PlanningSemanal>{};
  for (final planning in plannings) {
    final semana = semanasEntre(desde, planning.fechaInicio);
    if (planning.fechaInicio.isBefore(desde) || semana >= cuantas) continue;
    final yaHay = porSemana[semana];
    if (yaHay == null || (!yaHay.estado.esActivo && planning.estado.esActivo)) {
      porSemana[semana] = planning;
    }
  }
  final semanas = porSemana.keys.toList()..sort();
  return [for (final semana in semanas) porSemana[semana]!];
}

/// El mesociclo de la semana que empieza en [semana], si el informe empieza
/// en [desde] y los mesociclos son de [semanasPorMesociclo]. Con 0, todo es
/// el 1.
///
/// Va **por fecha y hacia delante**: con 8 semanas y mesociclos de 4, las 4
/// primeras son el 1 y las 4 siguientes el 2. Que falte una semana sin
/// planificar no corre a las demas de mesociclo.
int mesocicloDeLaSemana(
  DateTime semana, {
  required DateTime desde,
  required int semanasPorMesociclo,
}) => semanasPorMesociclo <= 0
    ? 1
    : semanasEntre(desde, semana) ~/ semanasPorMesociclo + 1;

/// Los mesociclos del [informe], empezando en [desde]. Uno que no tenga
/// ninguna semana planificada no sale, pero tampoco renumera a los demas: si
/// falta el 2, el siguiente sigue siendo el 3, como en el calendario de Aimar.
List<Mesociclo> mesociclosDe(
  InformeProgresion informe, {
  required DateTime desde,
  required int semanasPorMesociclo,
}) {
  final porNumero = <int, List<ResumenSemana>>{};
  for (final semana in informe.semanas) {
    porNumero
        .putIfAbsent(
          mesocicloDeLaSemana(
            semana.semana,
            desde: desde,
            semanasPorMesociclo: semanasPorMesociclo,
          ),
          () => [],
        )
        .add(semana);
  }
  final numeros = porNumero.keys.toList()..sort();
  return [
    for (final numero in numeros)
      Mesociclo(numero: numero, semanas: porNumero[numero]!),
  ];
}

/// Lo hecho en una semana (un planning) frente a lo planificado.
class ResumenSemana {
  const ResumenSemana({
    required this.planningId,
    required this.semana,
    required this.sesionesPlanificadas,
    required this.sesionesHechas,
    required this.seriesPlanificadas,
    required this.seriesHechas,
    required this.seriesIdenticasAlPlan,
    required this.volumenPlanificado,
    required this.volumenReal,
    required this.minutosCardioPlanificados,
    required this.minutosCardioHechos,
    this.rirsPlanificados = const [],
    this.rirsReales = const [],
  });

  final String planningId;

  /// Lunes de la semana: la `fechaInicio` del planning.
  final DateTime semana;
  final int sesionesPlanificadas;
  final int sesionesHechas;
  final int seriesPlanificadas;
  final int seriesHechas;
  final int seriesIdenticasAlPlan;
  final double volumenPlanificado;
  final double volumenReal;
  final double minutosCardioPlanificados;
  final double minutosCardioHechos;

  /// Se guardan sueltos y no la media: la media del periodo sale de todas las
  /// series, no de la media de las medias.
  final List<int> rirsPlanificados;
  final List<int> rirsReales;

  double? get pctSeries => _porcentaje(seriesHechas, seriesPlanificadas);
  double? get rirMedioPlanificado => _media(rirsPlanificados);
  double? get rirMedioReal => _media(rirsReales);
}

/// Un ejercicio de Fuerza a lo largo de las semanas.
class ProgresionEjercicio {
  const ProgresionEjercicio({
    required this.nombre,
    required this.grupo,
    required this.pesoPorLado,
    required this.semanas,
  });

  final String nombre;
  final GrupoMuscular? grupo;
  final bool pesoPorLado;

  /// Solo las semanas en que aparece, en orden.
  final List<SemanaDeEjercicio> semanas;
}

class SemanaDeEjercicio {
  const SemanaDeEjercicio({
    required this.semana,
    required this.seriesPlanificadas,
    required this.seriesHechas,
    required this.pesoMaxPlanificado,
    required this.pesoMaxReal,
    required this.volumenReal,
    required this.rmEstimado,
  });

  final DateTime semana;
  final int seriesPlanificadas;
  final int seriesHechas;
  final double? pesoMaxPlanificado;
  final double? pesoMaxReal;
  final double volumenReal;

  /// El mejor de la semana entre las series hechas con peso.
  final double? rmEstimado;
}

/// Una serie concreta: peso x reps, con su RIR.
class SerieDeReferencia {
  const SerieDeReferencia({
    required this.fecha,
    required this.peso,
    required this.repeticiones,
    this.rir,
  });

  /// La semana (inicio) o el dia en que se hizo (final).
  final DateTime fecha;
  final double peso;
  final int repeticiones;
  final int? rir;

  double get rmEstimado => rmEpley(peso, repeticiones);
}

/// De donde partio un ejercicio y donde ha acabado.
///
/// **Inicio**: la serie planificada mas pesada de la primera semana en que
/// aparece. No la mas ligera de todo el periodo: esa suele ser una serie de
/// aproximacion, no de trabajo, y la comparacion saldria inflada.
///
/// **Final**: la serie hecha mas pesada de la ultima sesion en que se hizo.
class InicioFinal {
  const InicioFinal({
    required this.nombre,
    required this.grupo,
    required this.pesoPorLado,
    required this.inicio,
    required this.fin,
  });

  final String nombre;
  final GrupoMuscular? grupo;
  final bool pesoPorLado;
  final SerieDeReferencia inicio;
  final SerieDeReferencia fin;

  double get diferenciaKg => fin.peso - inicio.peso;
  double get diferenciaPct => diferenciaKg / inicio.peso * 100;
  double get diferenciaRm => fin.rmEstimado - inicio.rmEstimado;
}

double rmEpley(double peso, int repeticiones) => peso * (1 + repeticiones / 30);

/// Calcula el informe de [plannings], en el orden que sea: se ordenan aqui.
InformeProgresion calcularInforme(List<PlanningSemanal> plannings) {
  final ordenados = [...plannings]
    ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

  final semanas = [for (final planning in ordenados) _resumir(planning)];

  // Por nombre y no por id: es como lo lee el entrenador, y dos fichas con el
  // mismo nombre no pueden convivir activas en la biblioteca.
  final porEjercicio = <String, List<_Apariciones>>{};
  for (final planning in ordenados) {
    for (final ep in _ejerciciosDe(planning)) {
      final ejercicio = ep.ejercicio;
      if (ejercicio == null || ejercicio.tipo != TipoEjercicio.fuerza) continue;
      porEjercicio
          .putIfAbsent(ejercicio.nombre, () => [])
          .add(_Apariciones(planning, ep));
    }
  }

  final ejercicios = <ProgresionEjercicio>[];
  final inicioFinal = <InicioFinal>[];
  for (final MapEntry(key: nombre, value: apariciones)
      in porEjercicio.entries) {
    final ficha = apariciones.first.ejercicio.ejercicio!;
    ejercicios.add(
      ProgresionEjercicio(
        nombre: nombre,
        grupo: ficha.grupo,
        pesoPorLado: ficha.pesoPorLado,
        semanas: _semanasDe(apariciones),
      ),
    );
    final inicio = _inicio(apariciones);
    final fin = _fin(apariciones);
    if (inicio != null && fin != null) {
      inicioFinal.add(
        InicioFinal(
          nombre: nombre,
          grupo: ficha.grupo,
          pesoPorLado: ficha.pesoPorLado,
          inicio: inicio,
          fin: fin,
        ),
      );
    }
  }

  ejercicios.sort((a, b) => a.nombre.compareTo(b.nombre));
  inicioFinal.sort((a, b) {
    final porMejora = b.diferenciaPct.compareTo(a.diferenciaPct);
    return porMejora != 0 ? porMejora : a.nombre.compareTo(b.nombre);
  });

  return InformeProgresion(
    semanas: semanas,
    ejercicios: ejercicios,
    inicioFinal: inicioFinal,
  );
}

class _Apariciones {
  const _Apariciones(this.planning, this.ejercicio);

  final PlanningSemanal planning;
  final EjercicioPlanificado ejercicio;

  /// Fecha en que se hizo la sesion; `null` si no se hizo.
  DateTime? get fechaRealizada => planning.sesiones
      .where((s) => s.bloques.any((b) => b.id == ejercicio.bloqueId))
      .firstOrNull
      ?.fechaRealizada;
}

Iterable<EjercicioPlanificado> _ejerciciosDe(PlanningSemanal planning) =>
    planning.sesiones.expand((s) => s.bloques).expand((b) => b.ejercicios);

double _factorLado(EjercicioPlanificado ep) =>
    (ep.ejercicio?.pesoPorLado ?? false) ? 2 : 1;

SerieRealizada? _realizadaDe(EjercicioPlanificado ep, SeriePlanificada plan) =>
    ep.seriesRealizadas
        .where((r) => r.numeroSerie == plan.numeroSerie)
        .firstOrNull;

ResumenSemana _resumir(PlanningSemanal planning) {
  var seriesPlanificadas = 0;
  var seriesHechas = 0;
  var identicas = 0;
  var volumenPlanificado = 0.0;
  var volumenReal = 0.0;
  var minutosPlanificados = 0.0;
  var minutosHechos = 0.0;
  final rirsPlanificados = <int>[];
  final rirsReales = <int>[];

  // Una sesion sin ningun ejercicio no estaba planificada de verdad.
  final sesiones = planning.sesiones
      .where((s) => s.bloques.any((b) => b.ejercicios.isNotEmpty))
      .toList();

  for (final ep in _ejerciciosDe(planning)) {
    final esFuerza = ep.ejercicio?.tipo == TipoEjercicio.fuerza;
    final lado = _factorLado(ep);
    minutosPlanificados += ep.minutosPlanificados ?? 0;
    minutosHechos += ep.minutosRealizados ?? 0;

    for (final plan in ep.series) {
      seriesPlanificadas++;
      final hecha = _realizadaDe(ep, plan);
      if (esFuerza) {
        volumenPlanificado +=
            (plan.pesoPlanificado ?? 0) * plan.repeticionesPlanificadas * lado;
        if (plan.rirPlanificado case final rir?) rirsPlanificados.add(rir);
      }
      if (hecha == null) continue;

      seriesHechas++;
      if (hecha.repeticionesRealizadas == plan.repeticionesPlanificadas &&
          hecha.pesoReal == plan.pesoPlanificado &&
          hecha.rirReal == plan.rirPlanificado) {
        identicas++;
      }
      if (esFuerza) {
        volumenReal +=
            (hecha.pesoReal ?? 0) * hecha.repeticionesRealizadas * lado;
        if (hecha.rirReal case final rir?) rirsReales.add(rir);
      }
    }
  }

  return ResumenSemana(
    planningId: planning.id,
    semana: planning.fechaInicio,
    sesionesPlanificadas: sesiones.length,
    sesionesHechas: sesiones.where((s) => s.fechaRealizada != null).length,
    seriesPlanificadas: seriesPlanificadas,
    seriesHechas: seriesHechas,
    seriesIdenticasAlPlan: identicas,
    volumenPlanificado: volumenPlanificado,
    volumenReal: volumenReal,
    minutosCardioPlanificados: minutosPlanificados,
    minutosCardioHechos: minutosHechos,
    rirsPlanificados: rirsPlanificados,
    rirsReales: rirsReales,
  );
}

List<SemanaDeEjercicio> _semanasDe(List<_Apariciones> apariciones) {
  final porSemana = <DateTime, List<EjercicioPlanificado>>{};
  for (final aparicion in apariciones) {
    porSemana
        .putIfAbsent(aparicion.planning.fechaInicio, () => [])
        .add(aparicion.ejercicio);
  }

  return [
    for (final MapEntry(key: semana, value: eps) in porSemana.entries)
      () {
        var planificadas = 0;
        var hechas = 0;
        var volumen = 0.0;
        double? pesoPlan;
        double? pesoReal;
        double? rm;
        for (final ep in eps) {
          final lado = _factorLado(ep);
          for (final plan in ep.series) {
            planificadas++;
            pesoPlan = _mayor(pesoPlan, plan.pesoPlanificado);
            final hecha = _realizadaDe(ep, plan);
            if (hecha == null) continue;
            hechas++;
            pesoReal = _mayor(pesoReal, hecha.pesoReal);
            if (hecha.pesoReal case final peso?) {
              volumen += peso * hecha.repeticionesRealizadas * lado;
              rm = _mayor(rm, rmEpley(peso, hecha.repeticionesRealizadas));
            }
          }
        }
        return SemanaDeEjercicio(
          semana: semana,
          seriesPlanificadas: planificadas,
          seriesHechas: hechas,
          pesoMaxPlanificado: pesoPlan,
          pesoMaxReal: pesoReal,
          volumenReal: volumen,
          rmEstimado: rm,
        );
      }(),
  ];
}

SerieDeReferencia? _inicio(List<_Apariciones> apariciones) {
  for (final aparicion in apariciones) {
    final conPeso = aparicion.ejercicio.series
        .where((s) => s.pesoPlanificado != null)
        .toList();
    if (conPeso.isEmpty) continue;
    // Las apariciones van por semana: la primera con peso es la de partida.
    // Si en esa semana hay otra aparicion mas pesada, la mejor de las dos.
    final mismaSemana = apariciones
        .where((a) => a.planning.fechaInicio == aparicion.planning.fechaInicio)
        .expand((a) => a.ejercicio.series)
        .where((s) => s.pesoPlanificado != null)
        .toList();
    final mejor = mismaSemana.reduce(
      (a, b) =>
          _comparar(
                a.pesoPlanificado!,
                a.repeticionesPlanificadas,
                b.pesoPlanificado!,
                b.repeticionesPlanificadas,
              ) >=
              0
          ? a
          : b,
    );
    return SerieDeReferencia(
      fecha: aparicion.planning.fechaInicio,
      peso: mejor.pesoPlanificado!,
      repeticiones: mejor.repeticionesPlanificadas,
      rir: mejor.rirPlanificado,
    );
  }
  return null;
}

SerieDeReferencia? _fin(List<_Apariciones> apariciones) {
  SerieDeReferencia? mejor;
  for (final aparicion in apariciones) {
    final fecha = aparicion.fechaRealizada;
    if (fecha == null) continue;
    for (final hecha in aparicion.ejercicio.seriesRealizadas) {
      final peso = hecha.pesoReal;
      if (peso == null) continue;
      final candidata = SerieDeReferencia(
        fecha: fecha,
        peso: peso,
        repeticiones: hecha.repeticionesRealizadas,
        rir: hecha.rirReal,
      );
      if (mejor == null || _esMejorFinal(candidata, mejor)) mejor = candidata;
    }
  }
  return mejor;
}

/// La mas reciente; en el mismo dia, la mas pesada y, a igual peso, la de mas
/// repeticiones.
bool _esMejorFinal(SerieDeReferencia a, SerieDeReferencia b) {
  final porFecha = a.fecha.compareTo(b.fecha);
  if (porFecha != 0) return porFecha > 0;
  return _comparar(a.peso, a.repeticiones, b.peso, b.repeticiones) > 0;
}

int _comparar(double pesoA, int repsA, double pesoB, int repsB) {
  final porPeso = pesoA.compareTo(pesoB);
  return porPeso != 0 ? porPeso : repsA.compareTo(repsB);
}

double? _mayor(double? a, double? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a > b ? a : b;
}

double? _porcentaje(int parte, int total) =>
    total == 0 ? null : parte / total * 100;

double? _media(Iterable<int> valores) {
  final lista = valores.toList();
  if (lista.isEmpty) return null;
  return lista.fold<int>(0, (t, v) => t + v) / lista.length;
}
