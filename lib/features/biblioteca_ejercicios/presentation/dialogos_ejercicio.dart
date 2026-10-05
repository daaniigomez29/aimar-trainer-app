import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_baja_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';

/// CU-04 Eliminar ejercicio: confirmacion, comprobacion de uso y baja logica.
///
/// La secuencia del caso de uso es: confirmar -> comprobar uso en bloques
/// activos -> si esta en uso, aviso explicito y confirmacion adicional -> baja.
///
/// El notifier se lee de nuevo despues de cada dialogo, nunca se guarda en una
/// variable al principio: `controladorBajaEjercicioProvider` es autoDispose y
/// mientras un dialogo espera respuesta puede desecharse, dejando el notifier
/// guardado inservible. Las pantallas que llaman aqui tambien lo observan, para
/// que siga vivo durante todo el flujo.
Future<void> confirmarBajaEjercicio({
  required BuildContext context,
  required WidgetRef ref,
  required Ejercicio ejercicio,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: const Text('Dar de baja el ejercicio'),
      content: Text(
        'Se dara de baja "${ejercicio.nombre}".\n\n'
        'No se borra: seguira visible en los plannings que ya lo usaban, pero '
        'no podra anadirse a bloques nuevos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_confirmar_baja'),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: const Text('Dar de baja'),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return;

  final usos = await ref
      .read(controladorBajaEjercicioProvider.notifier)
      .comprobarUsos(ejercicio.id);
  if (!context.mounted) return;

  if (usos == null) {
    final seguir = await _confirmarAviso(
      context: context,
      titulo: 'No se ha podido comprobar el uso',
      mensaje:
          'No se ha podido comprobar si "${ejercicio.nombre}" esta en algun '
          'planning activo. Puedes continuar de todas formas.',
      textoBoton: 'Dar de baja igualmente',
    );
    if (seguir != true || !context.mounted) return;
  } else if (usos > 0) {
    final seguir = await _confirmarAviso(
      context: context,
      titulo: 'El ejercicio esta en uso',
      mensaje:
          '"${ejercicio.nombre}" aparece en $usos '
          '${usos == 1 ? 'bloque' : 'bloques'} de plannings activos. Esos '
          'plannings lo conservaran, pero no podras anadirlo a bloques nuevos.',
      textoBoton: 'Dar de baja igualmente',
    );
    if (seguir != true || !context.mounted) return;
  }

  final resultado = await ref
      .read(controladorBajaEjercicioProvider.notifier)
      .darDeBaja(ejercicio.id);
  if (!context.mounted) return;

  _avisar(
    context: context,
    resultado: resultado,
    mensajeExito: '"${ejercicio.nombre}" dado de baja.',
    mensajeFalloGenerico: 'No se ha podido dar de baja.',
    deshacer: () =>
        reactivarEjercicio(context: context, ref: ref, ejercicio: ejercicio),
  );
}

/// Reactiva un ejercicio dado de baja.
Future<void> reactivarEjercicio({
  required BuildContext context,
  required WidgetRef ref,
  required Ejercicio ejercicio,
}) async {
  // Puede llegar desde el "Deshacer" de un aviso cuando la pantalla que lo lanzo
  // ya se ha cerrado (el detalle hace pop tras dar de baja). Usar su `ref`
  // entonces lanza, asi que se comprueba antes.
  if (!context.mounted) return;

  final resultado = await ref
      .read(controladorBajaEjercicioProvider.notifier)
      .reactivar(ejercicio.id);
  if (!context.mounted) return;

  _avisar(
    context: context,
    resultado: resultado,
    mensajeExito: '"${ejercicio.nombre}" vuelve a estar activo.',
    mensajeFalloGenerico: 'No se ha podido reactivar.',
  );
}

/// Aviso del resultado. Se usa el `Result` devuelto, no el estado del provider,
/// que puede haberse reiniciado al desecharse.
void _avisar({
  required BuildContext context,
  required Result<Ejercicio> resultado,
  required String mensajeExito,
  required String mensajeFalloGenerico,
  VoidCallback? deshacer,
}) {
  final exito = resultado.esExito;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        exito
            ? mensajeExito
            : (resultado.errorONulo?.mensaje ?? mensajeFalloGenerico),
      ),
      action: exito && deshacer != null
          ? SnackBarAction(label: 'Deshacer', onPressed: deshacer)
          : null,
    ),
  );
}

Future<bool?> _confirmarAviso({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  required String textoBoton,
}) => showDialog<bool>(
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
        key: const Key('boton_confirmar_aviso'),
        onPressed: () => Navigator.of(contexto).pop(true),
        child: Text(textoBoton),
      ),
    ],
  ),
);
