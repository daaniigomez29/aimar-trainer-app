import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
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
        'Se dará de baja "${ejercicio.nombre}".\n\n'
        'No se borra: seguirá visible en los plannings que ya lo usaban, pero '
        'no podrá añadirse a bloques nuevos.',
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
          'No se ha podido comprobar si "${ejercicio.nombre}" está en algún '
          'planning activo. Puedes continuar de todas formas.',
      textoBoton: 'Dar de baja igualmente',
    );
    if (seguir != true || !context.mounted) return;
  } else if (usos > 0) {
    final seguir = await _confirmarAviso(
      context: context,
      titulo: 'El ejercicio está en uso',
      mensaje:
          '"${ejercicio.nombre}" aparece en $usos '
          '${usos == 1 ? 'bloque' : 'bloques'} de plannings activos. Esos '
          'plannings lo conservarán, pero no podrás añadirlo a bloques nuevos.',
      textoBoton: 'Dar de baja igualmente',
    );
    if (seguir != true || !context.mounted) return;
  }

  // Se capturan con la pantalla aún viva: después de `darDeBaja` puede haberse
  // cerrado.
  final messenger = ScaffoldMessenger.of(context);
  final contenedor = ProviderScope.containerOf(context, listen: false);

  final resultado = await ref
      .read(controladorBajaEjercicioProvider.notifier)
      .darDeBaja(ejercicio.id);

  // El "Deshacer" se pulsa cuando esta pantalla puede haberse cerrado ya (dar de
  // baja desde la ficha hace `pop`). Por eso el aviso no se queda con el
  // `context` ni con el `ref` de aqui, que morirían con ella, sino con el
  // messenger del `MaterialApp` y el contenedor de Riverpod, que viven mientras
  // viva la aplicación. Antes comprobaba `context.mounted` y, si no lo estaba,
  // no hacía nada: el botón aparecía y no respondía.
  _avisar(
    messenger: messenger,
    resultado: resultado,
    mensajeExito: '"${ejercicio.nombre}" dado de baja.',
    mensajeFalloGenerico: 'No se ha podido dar de baja.',
    deshacer: () => _reactivarDesdeElAviso(
      messenger: messenger,
      contenedor: contenedor,
      ejercicio: ejercicio,
    ),
  );
}

/// Reactivación lanzada desde el "Deshacer" de un aviso.
///
/// No recibe `context` ni `ref` a propósito: ver el comentario de arriba.
Future<void> _reactivarDesdeElAviso({
  required ScaffoldMessengerState messenger,
  required ProviderContainer contenedor,
  required Ejercicio ejercicio,
}) async {
  final resultado = await contenedor
      .read(controladorBajaEjercicioProvider.notifier)
      .reactivar(ejercicio.id);

  _avisar(
    messenger: messenger,
    resultado: resultado,
    mensajeExito: '"${ejercicio.nombre}" vuelve a estar activo.',
    mensajeFalloGenerico: 'No se ha podido reactivar.',
  );
}

/// Reactiva un ejercicio dado de baja.
Future<void> reactivarEjercicio({
  required BuildContext context,
  required WidgetRef ref,
  required Ejercicio ejercicio,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final resultado = await ref
      .read(controladorBajaEjercicioProvider.notifier)
      .reactivar(ejercicio.id);

  _avisar(
    messenger: messenger,
    resultado: resultado,
    mensajeExito: '"${ejercicio.nombre}" vuelve a estar activo.',
    mensajeFalloGenerico: 'No se ha podido reactivar.',
  );
}

/// Aviso del resultado. Se usa el `Result` devuelto, no el estado del provider,
/// que puede haberse reiniciado al desecharse.
void _avisar({
  required ScaffoldMessengerState messenger,
  required Result<Ejercicio> resultado,
  required String mensajeExito,
  required String mensajeFalloGenerico,
  VoidCallback? deshacer,
}) {
  final exito = resultado.esExito;
  Avisos.mostrarEn(
    messenger,
    exito
        ? mensajeExito
        : (resultado.errorONulo?.mensaje ?? mensajeFalloGenerico),
    accion: exito && deshacer != null
        ? SnackBarAction(label: 'Deshacer', onPressed: deshacer)
        : null,
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
