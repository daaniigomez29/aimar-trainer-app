import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';

/// Puerto de dominio de los packs de entrenamiento.
///
/// Como en la planificacion, el **borrado es fisico**: un pack es una plantilla
/// del entrenador, no tiene historico que conservar. La baja logica se reserva a
/// clientes y ejercicios.
///
/// Todo pasa por RLS con las politicas `es_entrenador()`: ningun metodo necesita
/// `service_role`, y un cliente que forzara la interfaz recibiria un 403.
abstract interface class PackRepositorio {
  /// Todos los packs con sus ejercicios. Son pocos y la lista necesita saber
  /// cuantos ejercicios tiene cada uno, asi que se traen de una vez.
  Future<Result<List<Pack>>> listar();

  /// Un pack con sus ejercicios, cada uno con su ficha de la biblioteca y sus
  /// series. De una sola consulta.
  Future<Result<Pack>> obtener(String id);

  Future<Result<Pack>> crear(DatosPack datos);

  Future<Result<Pack>> editar({required String id, required DatosPack datos});

  /// Borrado fisico. Arrastra sus ejercicios y las series de estos.
  Future<Result<void>> eliminar(String id);

  /// Crea o edita un ejercicio del pack **con sus series**, en una sola
  /// transaccion: o entra todo, o no entra nada.
  Future<Result<String>> guardarEjercicio({
    required DatosPackEjercicio datos,
    String? id,
  });

  Future<Result<void>> eliminarEjercicio(String id);

  /// Renumera los ejercicios del pack en el orden recibido.
  ///
  /// La lista tiene que traer **todos** los del pack y cada uno una sola vez:
  /// renumera del 1 al N, no mueve uno suelto. Va en una sola transaccion
  /// porque el indice unico de `(pack_id, orden)` no admite estados intermedios
  /// con dos ejercicios en la misma posicion.
  Future<Result<void>> reordenarEjercicios({
    required String packId,
    required List<String> idsEnOrden,
  });

  /// Copia los ejercicios del pack **al final** del bloque, con lo que tuvieran
  /// preparado. Los dados de baja se quedan fuera y se informa de cuantos.
  ///
  /// Lo copiado pasa a ser del planning: editar el pack despues no lo cambia.
  Future<Result<ResultadoAplicarPack>> aplicarABloque({
    required String packId,
    required String bloqueId,
  });
}
