import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

/// Desde donde se esta filtrando la biblioteca.
///
/// POR QUE EXISTE: la pantalla de la biblioteca y el selector con el que se
/// anade un ejercicio a un bloque tenian **el mismo** estado de filtro, asi que
/// buscar "sent" en el selector dejaba la biblioteca ensenando solo la
/// sentadilla, sin nada escrito en su buscador que lo explicara. Son dos
/// busquedas distintas del mismo usuario y no tienen por que arrastrarse.
/// Cada pantalla que filtra la biblioteca tiene el suyo, **tambien las dos que
/// sirven para lo mismo**: el panel y el formulario pueden verse en el mismo
/// recorrido, y que uno herede el filtro del otro se lee como que la pantalla
/// esta rota, no como una comodidad.
enum AmbitoDeFiltro {
  /// La pantalla de biblioteca (CU-02 a CU-04).
  biblioteca,

  /// El panel lateral de la planificacion.
  panelPlanning,

  /// El formulario de anadir o editar un ejercicio de un bloque (CU-08, CU-12).
  formularioBloque,

  /// El formulario de anadir un ejercicio a un pack (RF-25.1). Tiene el suyo
  /// porque ademas llega **restringido al tipo del pack**, y arrastrar esa
  /// restriccion a la biblioteca seria desconcertante.
  formularioPack,
}

/// Los filtros principales de la pantalla de biblioteca, excluyentes entre si:
/// Todos, uno por tipo y Dados de baja.
///
/// No es un campo mas del filtro: se **deduce** de `tipo` y `soloEliminados`
/// (ver [FiltroEjercicios.pestana]), para que no puedan contradecirse.
enum PestanaBiblioteca {
  todos('Todos'),
  fuerza('Fuerza'),
  cardio('Cardio'),
  fortalecimiento('Fortalecimiento'),
  dadosDeBaja('Dados de baja');

  const PestanaBiblioteca(this.etiqueta);

  final String etiqueta;

  /// El tipo que filtra esta pestana, si filtra alguno.
  TipoEjercicio? get tipo => switch (this) {
    PestanaBiblioteca.fuerza => TipoEjercicio.fuerza,
    PestanaBiblioteca.cardio => TipoEjercicio.cardio,
    PestanaBiblioteca.fortalecimiento => TipoEjercicio.fortalecimiento,
    PestanaBiblioteca.todos || PestanaBiblioteca.dadosDeBaja => null,
  };

  /// Solo Fuerza y Fortalecimiento ofrecen el filtro muscular, y lo
  /// **comparten**: "pecho" sigue puesto al pasar de una a otra. En las demas
  /// los musculos no se ven, y un filtro que no se ve no puede seguir
  /// recortando la lista.
  bool get filtraPorMusculo =>
      this == PestanaBiblioteca.fuerza ||
      this == PestanaBiblioteca.fortalecimiento;

  static PestanaBiblioteca deTipo(TipoEjercicio tipo) => switch (tipo) {
    TipoEjercicio.fuerza => PestanaBiblioteca.fuerza,
    TipoEjercicio.cardio => PestanaBiblioteca.cardio,
    TipoEjercicio.fortalecimiento => PestanaBiblioteca.fortalecimiento,
  };
}

/// Criterios de busqueda del listado de la biblioteca.
///
/// El filtro muscular tiene dos niveles, [grupo] y [musculo], como la propia
/// taxonomia: se elige "Pierna" y, dentro, "Glúteo".
///
/// El buscador mira **solo el nombre**, y perdonando la ortografia: ignora
/// mayusculas, tildes y espacios de sobra, para que "press frances" encuentre
/// "Press francés". Lo demas se filtra con los chips, que para eso estan.
///
/// Los **secundarios cuentan**: filtrar por gluteo encuentra tambien la
/// sentadilla, donde es secundario. Si no contaran, declararlos solo serviria
/// para mirar la ficha. Lo que si cambia es el orden: primero los que lo tienen
/// como principal (ver [aplicar]), porque "ejercicios de glúteo" y "ejercicios
/// que ademas usan el glúteo" no son lo mismo y el entrenador necesita
/// distinguirlos.
///
/// `soloEliminados` y `soloSinClasificar` son "solo", no "incluir": son
/// pestanas para revisar un conjunto concreto, y mezclarlo con el resto no deja
/// ver cuales son.
class FiltroEjercicios {
  const FiltroEjercicios({
    this.texto = '',
    this.tipo,
    this.grupo,
    this.musculo,
    this.soloEliminados = false,
    this.soloSinClasificar = false,
  });

  /// Busca en nombre, equipamiento y nombres de la taxonomia.
  final String texto;
  final TipoEjercicio? tipo;
  final GrupoMuscular? grupo;
  final Musculo? musculo;
  final bool soloEliminados;

  /// Los que no tienen ni grupo ni musculos: lo que quedo por reclasificar al
  /// pasar del texto libre a la taxonomia.
  final bool soloSinClasificar;

  String get textoNormalizado => normalizarParaBuscar(texto);

  /// La pestana principal que corresponde a este filtro.
  PestanaBiblioteca get pestana {
    if (soloEliminados) return PestanaBiblioteca.dadosDeBaja;
    if (tipo case final tipo?) return PestanaBiblioteca.deTipo(tipo);
    return PestanaBiblioteca.todos;
  }

  bool get estaVacio =>
      textoNormalizado.isEmpty &&
      tipo == null &&
      grupo == null &&
      musculo == null &&
      !soloEliminados &&
      !soloSinClasificar;

  /// Para quitar el filtro de `tipo`, `grupo` o `musculo` no sirve este metodo
  /// (un `null` aqui significa "no cambiar"): se construye el filtro entero,
  /// como hace `FiltroBiblioteca`.
  FiltroEjercicios copiarCon({
    String? texto,
    TipoEjercicio? tipo,
    GrupoMuscular? grupo,
    Musculo? musculo,
    bool? soloEliminados,
    bool? soloSinClasificar,
  }) => FiltroEjercicios(
    texto: texto ?? this.texto,
    tipo: tipo ?? this.tipo,
    grupo: grupo ?? this.grupo,
    musculo: musculo ?? this.musculo,
    soloEliminados: soloEliminados ?? this.soloEliminados,
    soloSinClasificar: soloSinClasificar ?? this.soloSinClasificar,
  );

  /// Aplica el filtro en memoria.
  ///
  /// El listado completo se trae de una vez (la biblioteca de un solo entrenador
  /// no crece lo suficiente para justificar paginacion ni ida y vuelta al
  /// servidor por cada tecla), asi que filtrar aqui da respuesta inmediata al
  /// escribir y mantiene el repositorio con una sola consulta.
  bool aceptar(Ejercicio ejercicio) {
    // El filtro de estado es excluyente en los dos sentidos: con el chip puesto
    // se ven las bajas y nada mas; sin el, solo los activos.
    if (soloEliminados != !ejercicio.estado.esActivo) return false;
    if (soloSinClasificar && ejercicio.estaClasificado) return false;
    if (tipo != null && ejercicio.tipo != tipo) return false;
    if (grupo != null && !ejercicio.grupos.contains(grupo)) return false;
    if (musculo != null && !ejercicio.trabaja(musculo!)) return false;
    if (textoNormalizado.isEmpty) return true;

    // Solo el nombre. Buscar tambien en equipamiento y en los nombres de la
    // taxonomia daba resultados que nadie entendia: escribir "pecho" sacaba
    // ejercicios de espalda porque el pectoral era uno de sus secundarios. Para
    // los musculos estan los chips, que ademas dicen por que esta filtrado.
    return normalizarParaBuscar(ejercicio.nombre).contains(textoNormalizado);
  }

  /// Lo filtrado y en el orden en que se presenta.
  ///
  /// Sin filtro muscular se respeta el orden que trae el repositorio (por
  /// nombre). Con filtro muscular, delante los que lo tienen como **principal**
  /// y detras los que solo lo usan de secundario.
  List<Ejercicio> aplicar(List<Ejercicio> todos) {
    final aceptados = todos.where(aceptar).toList();
    if (musculo == null && grupo == null) return aceptados;

    aceptados.sort((a, b) {
      final prioridad = _prioridad(a).compareTo(_prioridad(b));
      if (prioridad != 0) return prioridad;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return aceptados;
  }

  /// 0 si lo trabaja como principal, 1 si solo como secundario.
  int _prioridad(Ejercicio ejercicio) {
    if (musculo != null) return ejercicio.musculoPrincipal == musculo ? 0 : 1;
    return ejercicio.musculoPrincipal?.grupo == grupo ? 0 : 1;
  }

  @override
  bool operator ==(Object other) =>
      other is FiltroEjercicios &&
      other.texto == texto &&
      other.tipo == tipo &&
      other.grupo == grupo &&
      other.musculo == musculo &&
      other.soloEliminados == soloEliminados &&
      other.soloSinClasificar == soloSinClasificar;

  @override
  int get hashCode => Object.hash(
    texto,
    tipo,
    grupo,
    musculo,
    soloEliminados,
    soloSinClasificar,
  );
}

/// Deja un texto listo para comparar: sin espacios de sobra, en minusculas y
/// **sin tildes ni dieresis**.
///
/// POR QUE: nadie escribe "press francés" con tilde en el buscador del gimnasio,
/// y quedarse sin resultados por eso parece que el ejercicio no existe. Se
/// normalizan los dos lados, el texto escrito y el nombre guardado, asi que
/// funciona en los dos sentidos.
///
/// La `n` tambien pierde la virgulilla a proposito: "espanol" encuentra
/// "español". Son letras distintas en castellano, pero aqui solo se trata de
/// encontrar, no de escribir bien.
String normalizarParaBuscar(String texto) {
  final limpio = texto.trim().toLowerCase();
  final letras = StringBuffer();
  for (final letra in limpio.split('')) {
    letras.write(_sinTilde[letra] ?? letra);
  }
  return letras.toString();
}

const Map<String, String> _sinTilde = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};
