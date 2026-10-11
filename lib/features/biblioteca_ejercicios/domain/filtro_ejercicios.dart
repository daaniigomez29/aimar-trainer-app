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
}

/// Criterios de busqueda del listado de la biblioteca.
///
/// El filtro muscular tiene dos niveles, [grupo] y [musculo], como la propia
/// taxonomia: se elige "Pierna" y, dentro, "Glúteo".
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

  String get textoNormalizado => texto.trim().toLowerCase();

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

    final campos = [
      ejercicio.nombre,
      ejercicio.equipamiento ?? '',
      ejercicio.grupo?.etiqueta ?? '',
      for (final musculo in ejercicio.musculos) ...[
        musculo.etiqueta,
        musculo.etiquetaCompleta,
      ],
    ];
    return campos.any(
      (campo) => campo.toLowerCase().contains(textoNormalizado),
    );
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
