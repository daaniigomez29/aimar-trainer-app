import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

/// Criterios de busqueda del listado de la biblioteca.
///
/// `soloEliminados` solo lo usa el entrenador: el cliente nunca ve ejercicios
/// dados de baja en el listado general.
///
/// Es "solo", no "incluir": el chip de "Dados de baja" es una pestaña para
/// revisar las bajas, y mezclarlas con los activos no deja ver cuales son.
class FiltroEjercicios {
  const FiltroEjercicios({
    this.texto = '',
    this.tipo,
    this.grupoMuscular,
    this.soloEliminados = false,
  });

  /// Busca en nombre, grupo muscular y equipamiento.
  final String texto;
  final TipoEjercicio? tipo;
  final String? grupoMuscular;
  final bool soloEliminados;

  String get textoNormalizado => texto.trim().toLowerCase();

  bool get estaVacio =>
      textoNormalizado.isEmpty &&
      tipo == null &&
      grupoMuscular == null &&
      !soloEliminados;

  /// Para quitar el filtro de `tipo` o de `grupoMuscular` no sirve este metodo
  /// (un `null` aqui significa "no cambiar"): se construye el filtro entero, como
  /// hace `FiltroBiblioteca`.
  FiltroEjercicios copiarCon({
    String? texto,
    TipoEjercicio? tipo,
    String? grupoMuscular,
    bool? soloEliminados,
  }) => FiltroEjercicios(
    texto: texto ?? this.texto,
    tipo: tipo ?? this.tipo,
    grupoMuscular: grupoMuscular ?? this.grupoMuscular,
    soloEliminados: soloEliminados ?? this.soloEliminados,
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
    if (tipo != null && ejercicio.tipo != tipo) return false;
    if (grupoMuscular != null && ejercicio.grupoMuscular != grupoMuscular) {
      return false;
    }
    if (textoNormalizado.isEmpty) return true;

    final campos = [
      ejercicio.nombre,
      ejercicio.grupoMuscular ?? '',
      ejercicio.equipamiento ?? '',
    ];
    return campos.any(
      (campo) => campo.toLowerCase().contains(textoNormalizado),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FiltroEjercicios &&
      other.texto == texto &&
      other.tipo == tipo &&
      other.grupoMuscular == grupoMuscular &&
      other.soloEliminados == soloEliminados;

  @override
  int get hashCode => Object.hash(texto, tipo, grupoMuscular, soloEliminados);
}
