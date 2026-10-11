import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';

/// Las opciones de filtrado que **tienen sentido ofrecer** ahora mismo, sacadas
/// de la biblioteca real.
///
/// La taxonomia completa son 6 grupos y 21 musculos, pero un chip que no
/// devuelve nada al pulsarlo es ruido: aqui solo estan los que tienen al menos
/// un ejercicio. Descubrir la taxonomia entera es cosa del formulario, que es
/// donde se clasifica; el filtro refleja lo que hay.
class FacetasBiblioteca {
  const FacetasBiblioteca({
    required this.ejerciciosPorGrupo,
    required this.musculosConEjercicios,
    required this.haySinClasificar,
  });

  static const FacetasBiblioteca vacias = FacetasBiblioteca(
    ejerciciosPorGrupo: {},
    musculosConEjercicios: {},
    haySinClasificar: false,
  );

  /// Cuantos ejercicios toca cada grupo. Solo estan los grupos con alguno, asi
  /// que la clave sirve tambien de "este grupo existe en la biblioteca".
  ///
  /// Un ejercicio cuenta en todos los grupos que toca, no solo en el de su
  /// musculo principal: la sentadilla suma en Pierna y en Espalda, porque el
  /// lumbar es uno de sus secundarios. Es la misma regla con la que filtra
  /// `FiltroEjercicios`, y si no coincidieran el contador mentiria.
  final Map<GrupoMuscular, int> ejerciciosPorGrupo;

  final Set<Musculo> musculosConEjercicios;

  /// Si existe algun ejercicio sin clasificar, para ofrecer su pestana.
  final bool haySinClasificar;

  /// Grupos con algun ejercicio, en el orden de la taxonomia (no en el de
  /// aparicion en la biblioteca).
  List<GrupoMuscular> get grupos =>
      GrupoMuscular.values.where(ejerciciosPorGrupo.containsKey).toList();

  /// Musculos de ese grupo con algun ejercicio, en el orden de la taxonomia.
  List<Musculo> musculosDe(GrupoMuscular grupo) =>
      Musculo.delGrupo(grupo).where(musculosConEjercicios.contains).toList();

  int cuentaDe(GrupoMuscular grupo) => ejerciciosPorGrupo[grupo] ?? 0;

  /// "4 ejercicios", para la linea de debajo del nombre del grupo.
  String resumenDe(GrupoMuscular grupo) {
    final cuantos = cuentaDe(grupo);
    return '$cuantos ${cuantos == 1 ? 'ejercicio' : 'ejercicios'}';
  }
}
