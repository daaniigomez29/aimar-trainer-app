/// Region muscular de la biblioteca. Se corresponde 1:1 con el enum
/// `grupo_muscular` de Postgres.
///
/// Es el primer nivel de la taxonomia; el segundo son los [Musculo] de cada
/// grupo. En un ejercicio **no se guarda normalmente**: se deriva de su musculo
/// principal (`Ejercicio.grupo`). Solo se guarda a mano cuando no hay musculo
/// principal, que es el caso del cardio: la cinta de correr es de Pierna, pero
/// decir que es "de cuadriceps" seria inventarse el dato.
///
/// El valor que viaja a la base de datos es [valorJson], escrito a mano y no
/// generado: estos enums se serializan con los conversores de `musculo.dart`,
/// para que un valor desconocido no tumbe el parseo de la biblioteca entera.
enum GrupoMuscular {
  pierna('pierna', 'Pierna'),
  pecho('pecho', 'Pecho'),
  espalda('espalda', 'Espalda'),
  hombro('hombro', 'Hombro'),
  brazo('brazo', 'Brazo'),
  core('core', 'Core');

  const GrupoMuscular(this.valorJson, this.etiqueta);

  final String valorJson;

  /// Etiqueta para la interfaz.
  final String etiqueta;

  static GrupoMuscular? porValorJson(String? valor) {
    if (valor == null) return null;
    for (final grupo in GrupoMuscular.values) {
      if (grupo.valorJson == valor) return grupo;
    }
    return null;
  }
}
