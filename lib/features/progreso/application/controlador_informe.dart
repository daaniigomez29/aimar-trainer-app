import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/data/descargador_pdf.dart';
import 'package:aimar_trainer_app/features/progreso/domain/informe_progresion.dart';

part 'controlador_informe.g.dart';

/// Informe de progresion de los plannings [idsPlannings], separados por comas.
///
/// POR QUE UN TEXTO y no una lista: los parametros de un provider se comparan
/// por igualdad, y dos `List` con los mismos ids no son iguales para Dart. Con
/// una lista, cada repintado de la pantalla pediria el informe de nuevo.
/// Quien lo llama los ordena antes de unirlos: [clavePlannings].
@riverpod
Future<InformeProgresion> informeProgresion(
  Ref ref,
  String idsPlannings,
) async {
  final ids = idsPlannings.split(',').where((id) => id.isNotEmpty).toList();
  if (ids.isEmpty) return calcularInforme(const []);

  final repositorio = ref.watch(planningRepositorioProvider);
  final resultados = await Future.wait(
    ids.map(repositorio.obtenerPlanningCompleto),
  );
  final plannings = <PlanningSemanal>[];
  for (final resultado in resultados) {
    switch (resultado) {
      case Success(:final valor):
        plannings.add(valor);
      case Failure(:final error):
        throw error;
    }
  }
  return calcularInforme(plannings);
}

/// La clave de [informeProgresionProvider] para esos plannings, en cualquier
/// orden.
String clavePlannings(Iterable<String> ids) => (ids.toList()..sort()).join(',');

/// Quien entrega el PDF al usuario. Va tras una interfaz porque es codigo de
/// plataforma (en la web, una descarga del navegador), y en los tests se
/// sustituye.
@riverpod
DescargadorPdf descargadorPdf(Ref ref) => const DescargadorPdfPrinting();
