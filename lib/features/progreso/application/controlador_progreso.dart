import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';

part 'controlador_progreso.g.dart';

/// Ejercicios con algo registrado, para el desplegable del filtro (CU-21).
@riverpod
Future<List<EjercicioConRegistro>> ejerciciosConRegistro(
  Ref ref,
  String clienteId,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .ejerciciosConRegistro(clienteId);
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Lo registrado de un ejercicio en un rango de fechas, sin resumir.
///
/// El rango viaja como dos fechas sueltas y no como [RangoFechas] porque los
/// parametros de un provider se comparan por igualdad, y `DateTime` la tiene por
/// valor mientras que una clase propia necesitaria implementarla.
@riverpod
Future<List<RegistroProgreso>> progresoDeEjercicio(
  Ref ref,
  String clienteId,
  String ejercicioId,
  DateTime desde,
  DateTime hasta,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .progresoDeEjercicio(
        clienteId: clienteId,
        ejercicioId: ejercicioId,
        rango: RangoFechas(desde: desde, hasta: hasta),
      );
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Medidas corporales del rango, para la otra mitad de CU-21.
@riverpod
Future<List<RegistroMedidas>> medidasEnRango(
  Ref ref,
  String clienteId,
  DateTime desde,
  DateTime hasta,
) async {
  final resultado = await ref
      .watch(progresoRepositorioProvider)
      .listarMedidas(
        clienteId: clienteId,
        rango: RangoFechas(desde: desde, hasta: hasta),
      );
  return switch (resultado) {
    Success(:final valor) => valor,
    Failure(:final error) => throw error,
  };
}

/// Traduce a texto el error que llega por un provider de progreso.
///
/// Los providers lanzan el [ErrorApp] tal cual, asi que aqui se recupera su
/// mensaje ya redactado en lugar de mostrar el `toString` de una excepcion.
String mensajeDeErrorProgreso(Object error) => switch (error) {
  ErrorApp(:final mensaje) => mensaje,
  _ => 'No se han podido cargar los datos. Vuelve a intentarlo.',
};
