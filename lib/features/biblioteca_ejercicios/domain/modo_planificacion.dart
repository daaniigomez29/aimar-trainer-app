/// Como se planifica y se registra un ejercicio: con series o con minutos.
///
/// POR QUE EXISTE: hasta la llegada de `fortalecimiento` el tipo era binario y
/// todo el codigo preguntaba `esCardio ? minutos : series`. Un tercer tipo
/// convierte ese ternario en una mentira silenciosa —compila igual y trata
/// Fortalecimiento como Fuerza sin que nadie lo decida—, asi que la pregunta
/// pasa a ser **el modo**, que es lo que de verdad cambia el comportamiento.
/// El mismo razonamiento esta en `planifica_con_minutos()` en la base de datos.
///
/// Los dos modos son excluyentes: un ejercicio planificado tiene series o
/// minutos, nunca ambos (lo garantiza el trigger
/// `comprobar_tipo_ejercicio_planificado`).
enum ModoPlanificacion {
  /// Series, repeticiones, peso y RIR. El peso y el RIR son opcionales.
  series,

  /// Minutos planificados y realizados.
  minutos;

  bool get esSeries => this == ModoPlanificacion.series;
  bool get esMinutos => this == ModoPlanificacion.minutos;
}
