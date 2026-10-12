import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/credenciales.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/widgets/solicitud_de_enlace.dart';

/// Pantalla para fijar la contrasena. Sirve a dos flujos:
///
/// - CU-17: el cliente acaba de aceptar su invitacion y elige su primera
///   contrasena. Es obligatorio: si entrara sin fijarla, no podria volver a
///   entrar nunca (su cuenta se crea sin contrasena).
/// - CU-24: recuperacion, segunda mitad.
///
/// Solo cambian los textos; el formulario y la validacion son los mismos.
///
/// Y un tercer caso, **sin sesion**: se ha llegado aqui con un enlace que ya no
/// vale, porque los del correo son de un solo uso y caducan. Entonces no se
/// pinta el formulario —no habria donde guardar la contrasena— sino la forma de
/// pedir otro enlace. Es alcanzable sin sesion a proposito (`Rutas.publicas`):
/// un cliente invitado al que se mande al login se queda sin salida, porque
/// alli no tiene ninguna contrasena que escribir.
class PantallaRestablecerContrasena extends ConsumerStatefulWidget {
  const PantallaRestablecerContrasena({super.key});

  @override
  ConsumerState<PantallaRestablecerContrasena> createState() =>
      _EstadoPantallaRestablecerContrasena();
}

class _EstadoPantallaRestablecerContrasena
    extends ConsumerState<PantallaRestablecerContrasena> {
  final _contrasena = TextEditingController();
  final _repeticion = TextEditingController();

  @override
  void dispose() {
    _contrasena.dispose();
    _repeticion.dispose();
    super.dispose();
  }

  Future<void> _enviar() => ref
      .read(controladorRestablecerContrasenaProvider.notifier)
      .establecerContrasena(
        contrasena: _contrasena.text,
        repeticion: _repeticion.text,
      );

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(controladorSesionProvider);

    final motivo = switch (sesion) {
      SesionEnlaceInvalido(:final error) => error,
      // Sin sesion y sin motivo conocido: el enlace tampoco ha servido, solo
      // que nadie ha dicho por que.
      SesionCerrada() => const ErrorEnlaceCaducado(),
      _ => null,
    };
    if (motivo != null) return _PedirOtroEnlace(motivo: motivo.mensaje);

    // El enlace se canjea antes del primer fotograma, asi que esto dura lo que
    // tarde en llegar el primer evento de Auth.
    if (sesion is SesionDesconocida) return const PantallaCargando();

    final estado = ref.watch(controladorRestablecerContrasenaProvider);
    final controlador = ref.read(
      controladorRestablecerContrasenaProvider.notifier,
    );
    final esPrimeraVez = sesion is SesionDebeFijarContrasena;

    // Al completarse, Auth emite `userUpdated`: `ControladorSesion` resuelve el
    // perfil y el enrutador lleva a la pantalla principal del rol.
    if (estado.completada) {
      return FormularioCentrado(
        titulo: esPrimeraVez ? 'Cuenta activada' : 'Contraseña actualizada',
        hijos: [
          AvisoEnLinea(
            esError: false,
            mensaje: esPrimeraVez
                ? 'Ya tienes acceso. Entrando...'
                : 'Ya puedes usar tu contraseña nueva.',
          ),
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return FormularioCentrado(
      titulo: esPrimeraVez ? 'Elige tu contraseña' : 'Nueva contraseña',
      subtitulo: esPrimeraVez
          ? 'Tu entrenador te ha dado de alta. Elige una contraseña para '
                'entrar: debe tener al menos '
                '${Credenciales.longitudMinimaContrasena} caracteres.'
          : 'Debe tener al menos '
                '${Credenciales.longitudMinimaContrasena} caracteres.',
      hijos: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('campo_contrasena'),
          controller: _contrasena,
          enabled: !estado.enCurso,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            errorText: estado.errorDelCampo('contrasena'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_repeticion'),
          controller: _repeticion,
          enabled: !estado.enCurso,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onChanged: (_) => controlador.limpiarError(),
          onSubmitted: (_) => _enviar(),
          decoration: InputDecoration(
            labelText: 'Repite la contraseña',
            errorText: estado.errorDelCampo('repeticion'),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_guardar_contrasena'),
          onPressed: estado.enCurso ? null : _enviar,
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(esPrimeraVez ? 'Activar mi cuenta' : 'Guardar contraseña'),
        ),
        const SizedBox(height: 8),
        // En el flujo de invitacion no se ofrece salir: sin contrasena fijada, el
        // cliente no podria volver a entrar.
        if (!esPrimeraVez)
          TextButton(
            onPressed: estado.enCurso ? null : () => context.go(Rutas.login),
            child: const Text('Volver al acceso'),
          ),
      ],
    );
  }
}

/// Lo que se ve cuando el enlace del correo ya no sirve.
///
/// El cliente puede pedir otro **las veces que quiera**: el enlace sigue siendo
/// de un solo uso (es la credencial de su cuenta y viaja en su buzon), lo que
/// no tiene limite es pedir uno nuevo. Y se pide desde aqui, que es donde ha
/// aterrizado, sin tener que saber que existe una pantalla de recuperacion.
class _PedirOtroEnlace extends ConsumerWidget {
  const _PedirOtroEnlace({required this.motivo});

  final String motivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorSolicitudRecuperacionProvider);

    if (estado.completada) {
      return const FormularioCentrado(
        titulo: 'Revisa tu correo',
        hijos: [AvisoEnLinea(esError: false, mensaje: mensajeEnlaceEnviado)],
      );
    }

    return FormularioCentrado(
      titulo: 'Este enlace ya no vale',
      subtitulo: motivo,
      hijos: [
        Text(
          'Los enlaces del correo se usan una sola vez. Escribe tu correo y te '
          'enviamos uno nuevo para elegir tu contraseña.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        const SolicitudDeEnlace(etiquetaBoton: 'Enviarme un enlace nuevo'),
      ],
    );
  }
}
