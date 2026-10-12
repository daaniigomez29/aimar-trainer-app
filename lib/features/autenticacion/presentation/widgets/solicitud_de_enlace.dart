import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';

/// Lo que se responde al pedir un enlace, exista la cuenta o no.
///
/// **Deliberadamente generico**: si dijera "ese correo no está registrado",
/// cualquiera tendria una forma de averiguar quien es cliente de Aimar probando
/// direcciones. El correo solo sale si la cuenta existe, y solo lo recibe quien
/// tenga ese buzon.
const String mensajeEnlaceEnviado =
    'Si ese correo corresponde a una cuenta, recibirás un enlace para fijar '
    'la contraseña. Revisa también la carpeta de spam.';

/// Campo de correo y boton para que Auth envie un enlace nuevo (CU-24, primera
/// mitad).
///
/// Lo comparten los dos sitios desde los que se pide: la pantalla de recuperar
/// contrasena, a la que se llega desde el login, y la de fijarla, cuando el
/// enlace del correo ya no vale. Es el mismo gesto, la misma llamada y el mismo
/// mensaje; lo unico que cambia es la etiqueta del boton.
///
/// Quien lo use se encarga del caso `completada`: las dos pantallas lo
/// presentan con su propio marco.
class SolicitudDeEnlace extends ConsumerStatefulWidget {
  const SolicitudDeEnlace({this.etiquetaBoton = 'Enviar enlace', super.key});

  final String etiquetaBoton;

  @override
  ConsumerState<SolicitudDeEnlace> createState() => _SolicitudDeEnlaceState();
}

class _SolicitudDeEnlaceState extends ConsumerState<SolicitudDeEnlace> {
  final _correo = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorSolicitudRecuperacionProvider);
    final controlador = ref.read(
      controladorSolicitudRecuperacionProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('campo_correo'),
          controller: _correo,
          enabled: !estado.enCurso,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => controlador.limpiarError(),
          onSubmitted: (_) => controlador.solicitarEnlace(_correo.text),
          decoration: InputDecoration(
            labelText: 'Correo',
            errorText: estado.errorDelCampo('correo'),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_enviar_enlace'),
          onPressed: estado.enCurso
              ? null
              : () => controlador.solicitarEnlace(_correo.text),
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.etiquetaBoton),
        ),
      ],
    );
  }
}
