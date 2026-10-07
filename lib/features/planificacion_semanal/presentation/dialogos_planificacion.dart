import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Confirmaciones de borrado de CU-13 a CU-16.
///
/// Todas avisan de la cascada: al contrario que clientes y ejercicios, aqui el
/// borrado es fisico y se lleva por delante lo que cuelga debajo.

/// CU-13: eliminar planning.
Future<bool> confirmarEliminarPlanning({
  required BuildContext context,
  required WidgetRef ref,
  required PlanningSemanal planning,
}) async {
  final sesiones = planning.sesiones.length;
  final ejercicios = planning.sesiones
      .expand((s) => s.bloques)
      .expand((b) => b.ejercicios)
      .length;

  final confirmado = await _confirmar(
    context: context,
    titulo: 'Eliminar el planning',
    mensaje: sesiones == 0
        ? 'Este planning está vacío. Se eliminará definitivamente.'
        : 'Se eliminará el planning completo: $sesiones '
              '${sesiones == 1 ? "sesion" : "sesiones"} y $ejercicios '
              '${ejercicios == 1 ? "ejercicio" : "ejercicios"} planificados.\n\n'
              'Esto no se puede deshacer. Si solo quieres conservarlo como '
              'histórico, archívalo en lugar de eliminarlo.',
    textoBoton: 'Eliminar',
  );
  if (!confirmado || !context.mounted) return false;

  final resultado = await ref
      .read(controladorPlanificacionProvider.notifier)
      .eliminarPlanning(planning.id);
  if (!context.mounted) return resultado.esExito;

  _avisar(
    context,
    resultado,
    exito: 'Planning eliminado.',
    fallo: 'No se ha podido eliminar el planning.',
  );
  return resultado.esExito;
}

/// CU-14: eliminar sesion.
Future<bool> confirmarEliminarSesion({
  required BuildContext context,
  required WidgetRef ref,
  required SesionEntrenamiento sesion,
  required String planningId,
}) async {
  final ejercicios = sesion.bloques.expand((b) => b.ejercicios).length;

  final confirmado = await _confirmar(
    context: context,
    titulo: 'Eliminar la sesión',
    mensaje: sesion.bloques.isEmpty
        ? 'Se eliminará la sesión "${sesion.nombre}".'
        : 'Se eliminará "${sesion.nombre}" con sus '
              '${sesion.bloques.length} '
              '${sesion.bloques.length == 1 ? "bloque" : "bloques"} y '
              '$ejercicios ${ejercicios == 1 ? "ejercicio" : "ejercicios"}.',
    textoBoton: 'Eliminar',
  );
  if (!confirmado || !context.mounted) return false;

  final resultado = await ref
      .read(controladorPlanificacionProvider.notifier)
      .eliminarSesion(id: sesion.id, planningId: planningId);
  if (!context.mounted) return resultado.esExito;

  _avisar(
    context,
    resultado,
    exito: 'Sesión eliminada.',
    fallo: 'No se ha podido eliminar la sesión.',
  );
  return resultado.esExito;
}

/// CU-15: eliminar bloque.
Future<bool> confirmarEliminarBloque({
  required BuildContext context,
  required WidgetRef ref,
  required BloqueEjercicio bloque,
  required String planningId,
}) async {
  final confirmado = await _confirmar(
    context: context,
    titulo: 'Eliminar el bloque',
    mensaje: bloque.ejercicios.isEmpty
        ? 'Se eliminará el bloque de ${bloque.tipo.etiqueta}.'
        : 'Se eliminará el bloque de ${bloque.tipo.etiqueta} con sus '
              '${bloque.ejercicios.length} '
              '${bloque.ejercicios.length == 1 ? "ejercicio" : "ejercicios"}.',
    textoBoton: 'Eliminar',
  );
  if (!confirmado || !context.mounted) return false;

  final resultado = await ref
      .read(controladorPlanificacionProvider.notifier)
      .eliminarBloque(id: bloque.id, planningId: planningId);
  if (!context.mounted) return resultado.esExito;

  _avisar(
    context,
    resultado,
    exito: 'Bloque eliminado.',
    fallo: 'No se ha podido eliminar el bloque.',
  );
  return resultado.esExito;
}

/// CU-16: quitar un ejercicio del bloque. No toca la biblioteca.
Future<bool> confirmarEliminarEjercicio({
  required BuildContext context,
  required WidgetRef ref,
  required EjercicioPlanificado ejercicio,
  required String planningId,
}) async {
  final nombre = ejercicio.ejercicio?.nombre ?? 'este ejercicio';

  final confirmado = await _confirmar(
    context: context,
    titulo: 'Quitar el ejercicio',
    mensaje:
        'Se quitará "$nombre" de este bloque, con sus series planificadas.\n\n'
        'El ejercicio sigue en la biblioteca: esto solo lo saca de aquí.',
    textoBoton: 'Quitar',
  );
  if (!confirmado || !context.mounted) return false;

  final resultado = await ref
      .read(controladorPlanificacionProvider.notifier)
      .eliminarEjercicio(id: ejercicio.id, planningId: planningId);
  if (!context.mounted) return resultado.esExito;

  _avisar(
    context,
    resultado,
    exito: 'Ejercicio quitado del bloque.',
    fallo: 'No se ha podido quitar el ejercicio.',
  );
  return resultado.esExito;
}

/// Archivar / reactivar un planning. Alternativa no destructiva a eliminarlo.
Future<void> alternarArchivadoPlanning({
  required BuildContext context,
  required WidgetRef ref,
  required PlanningSemanal planning,
}) async {
  final controlador = ref.read(controladorPlanificacionProvider.notifier);
  final archivar = planning.estado.esActivo;

  if (archivar) {
    final confirmado = await _confirmar(
      context: context,
      titulo: 'Archivar el planning',
      mensaje:
          'Un planning archivado se conserva completo para consulta, pero deja '
          'de admitir cambios y el cliente no podrá registrar resultados en él.',
      textoBoton: 'Archivar',
    );
    if (!confirmado || !context.mounted) return;
  }

  final resultado = archivar
      ? await controlador.archivarPlanning(planning.id)
      : await controlador.reactivarPlanning(planning.id);
  if (!context.mounted) return;

  _avisar(
    context,
    resultado,
    exito: archivar ? 'Planning archivado.' : 'Planning reactivado.',
    fallo: 'No se ha podido cambiar el estado del planning.',
  );
}

/// CU-11: mover un bloque dentro de su sesion arrastrandolo.
///
/// No pide confirmacion ni avisa cuando sale bien: el resultado se ve, y un
/// cartel por cada arrastre seria ruido. Solo se habla si falla, y entonces hay
/// que decirlo, porque la lista se habra recolocado sola al recargar.
Future<bool> moverBloque({
  required BuildContext context,
  required WidgetRef ref,
  required SesionEntrenamiento sesion,
  required String planningId,
  required int desde,
  required int hasta,
}) async {
  final resultado = await ref
      .read(controladorPlanificacionProvider.notifier)
      .reordenarBloques(
        sesion: sesion,
        idsEnOrden: [
          for (final bloque in reordenarLista(sesion.bloques, desde, hasta))
            bloque.id,
        ],
        planningId: planningId,
      );
  if (context.mounted && resultado.esFallo) {
    _avisar(
      context,
      resultado,
      exito: '',
      fallo: 'No se ha podido mover el bloque.',
    );
  }
  return resultado.esExito;
}

/// CU-12: mover un ejercicio dentro de su bloque arrastrandolo.
Future<bool> moverEjercicio({
  required BuildContext context,
  required WidgetRef ref,
  required BloqueEjercicio bloque,
  required String planningId,
  required int desde,
  required int hasta,
}) async {
  final resultado = await ref
      .read(controladorPlanificacionProvider.notifier)
      .reordenarEjercicios(
        bloque: bloque,
        idsEnOrden: [
          for (final ejercicio in reordenarLista(
            bloque.ejercicios,
            desde,
            hasta,
          ))
            ejercicio.id,
        ],
        planningId: planningId,
      );
  if (context.mounted && resultado.esFallo) {
    _avisar(
      context,
      resultado,
      exito: '',
      fallo: 'No se ha podido mover el ejercicio.',
    );
  }
  return resultado.esExito;
}

Future<bool> _confirmar({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  required String textoBoton,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      icon: const Icon(Icons.warning_amber_outlined),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_confirmar_planificacion'),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: Text(textoBoton),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

void _avisar(
  BuildContext context,
  Result<void> resultado, {
  required String exito,
  required String fallo,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Avisos.duracion,
      content: Text(
        resultado.esExito ? exito : (resultado.errorONulo?.mensaje ?? fallo),
      ),
    ),
  );
}
