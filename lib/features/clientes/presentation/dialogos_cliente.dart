import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/clientes/application/controlador_ficha_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';

/// CU-18 Dar de baja cliente: confirmacion, aviso si tiene planning activo y
/// baja logica con bloqueo de acceso.
///
/// El notifier se lee despues de cada dialogo, nunca se guarda antes: el provider
/// es autoDispose y entre dialogos puede desecharse.
Future<void> confirmarBajaCliente({
  required BuildContext context,
  required WidgetRef ref,
  required Cliente cliente,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: const Text('Dar de baja al cliente'),
      content: Text(
        'Se dará de baja a ${cliente.nombre}.\n\n'
        'No se borra nada: su historico se conserva completo y seguiras '
        'pudiendo consultarlo. Lo que ocurre es que pierde el acceso a la '
        'aplicación y no recibira plannings nuevos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('boton_confirmar_baja_cliente'),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: const Text('Dar de baja'),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return;

  // CU-18, excepcion: si tiene un planning activo en curso, aviso y confirmacion
  // explicita adicional.
  final plannings = await ref
      .read(controladorBajaClienteProvider.notifier)
      .comprobarPlanningsActivos(cliente.id);
  if (!context.mounted) return;

  if (plannings == null || plannings > 0) {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.warning_amber_outlined),
        title: Text(
          plannings == null
              ? 'No se ha podido comprobar sus plannings'
              : 'Tiene un planning activo en curso',
        ),
        content: Text(
          plannings == null
              ? 'No se ha podido comprobar si ${cliente.nombre} tiene algún '
                    'planning activo. Puedes continuar de todas formas.'
              : '${cliente.nombre} tiene $plannings '
                    '${plannings == 1 ? "planning activo" : "plannings activos"} '
                    'en curso. Al darle de baja perderá el acceso y no podrá '
                    'registrar los resultados que falten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('boton_confirmar_aviso_cliente'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Dar de baja igualmente'),
          ),
        ],
      ),
    );
    if (seguir != true || !context.mounted) return;
  }

  final resultado = await ref
      .read(controladorBajaClienteProvider.notifier)
      .darDeBaja(cliente.id);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Avisos.duracion,
      content: Text(
        resultado.esExito
            ? '${cliente.nombre} está de baja y ya no puede acceder.'
            : resultado.errorONulo?.mensaje ?? 'No se ha podido dar de baja.',
      ),
    ),
  );
}
