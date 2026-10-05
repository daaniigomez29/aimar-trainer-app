import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';

/// Puerto de dominio del progreso: lo que registra el cliente (CU-20, medidas y
/// check-in) y lo que se consulta despues (CU-21).
///
/// Ninguna operacion recibe el rol: lo que cada quien puede ver o escribir lo
/// decide RLS. El entrenador puede leer lo de sus clientes y el administrador no
/// puede leer nada de aqui, sin que este codigo tenga que saberlo.
abstract interface class ProgresoRepositorio {
  // --- CU-20: resultado de la sesion ---

  /// Guarda el resultado de un ejercicio: sus series si es Fuerza, sus minutos si
  /// es Cardio. Va por la funcion `registrar_resultado_ejercicio`, que lo deja
  /// todo en una sola transaccion.
  ///
  /// Es incremental: volver a llamar con mas series anade las nuevas y corrige
  /// las que ya estaban.
  Future<Result<void>> registrarResultado(DatosResultadoEjercicio datos);

  // --- Medidas corporales ---

  /// Registros de medidas del cliente, del mas reciente al mas antiguo.
  Future<Result<List<RegistroMedidas>>> listarMedidas({
    required String clienteId,
    RangoFechas? rango,
  });

  /// El registro de un dia concreto, o `null` si ese dia no tiene ninguno.
  Future<Result<RegistroMedidas?>> medidasDelDia({
    required String clienteId,
    required DateTime fecha,
  });

  /// Crea el registro de ese dia o corrige el que ya hubiera: hay un indice unico
  /// por cliente y fecha, asi que guardar dos veces el mismo dia no duplica.
  Future<Result<RegistroMedidas>> guardarMedidas(DatosRegistroMedidas datos);

  // --- Check-in de recuperacion ---

  Future<Result<List<CheckinRecuperacion>>> listarCheckins({
    required String clienteId,
    RangoFechas? rango,
  });

  Future<Result<CheckinRecuperacion?>> checkinDelDia({
    required String clienteId,
    required DateTime fecha,
  });

  Future<Result<CheckinRecuperacion>> guardarCheckin(DatosCheckin datos);

  // --- Fotos de progreso ---

  /// Sube la imagen al bucket privado y deja su ruta en `fotos_progreso`. Si la
  /// fila no se puede crear, el fichero subido se borra: no debe quedar un objeto
  /// huerfano en el bucket.
  Future<Result<FotoProgreso>> subirFoto({
    required String clienteId,
    required String registroMedidasId,
    required ImagenParaSubir imagen,
  });

  /// Borra la fila y el fichero del bucket.
  Future<Result<void>> eliminarFoto(FotoProgreso foto);

  /// URL firmada y caducable para mostrar la foto. El bucket es privado: no hay
  /// URL permanente.
  Future<Result<Uri>> urlFirmadaDe(FotoProgreso foto);

  // --- CU-21: consulta de progreso ---

  /// Ejercicios de los que ese cliente tiene algo registrado, para el filtro.
  Future<Result<List<EjercicioConRegistro>>> ejerciciosConRegistro(
    String clienteId,
  );

  /// Lo registrado de un ejercicio dentro del rango, sin resumir: la metrica se
  /// aplica en el dominio, no en la consulta.
  Future<Result<List<RegistroProgreso>>> progresoDeEjercicio({
    required String clienteId,
    required String ejercicioId,
    required RangoFechas rango,
  });

  /// Lo registrado de varios ejercicios antes de [antesDe], lo mas reciente
  /// primero. Lo usa la planificacion para ensenar al entrenador como le fue al
  /// cliente la ultima vez, sin pedir un viaje por ejercicio.
  ///
  /// Trae filas sueltas, sin agrupar: quedarse con la ultima vez de cada
  /// ejercicio es cosa de quien llama.
  Future<Result<List<RegistroProgreso>>> ultimoDeCadaEjercicio({
    required String clienteId,
    required List<String> ejercicioIds,
    required DateTime antesDe,
  });
}
