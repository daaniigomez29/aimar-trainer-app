import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/configuracion/configuracion_app.dart';
import 'package:aimar_trainer_app/core/diagnostico/observador_providers.dart';
import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/presentacion/app.dart';
import 'package:aimar_trainer_app/core/presentacion/pantalla_configuracion_invalida.dart';

void main() => ejecutarConRegistro(_arrancar);

Future<void> _arrancar() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configuracion = ConfiguracionApp.desdeEntorno();
  if (!configuracion.esValida) {
    // Sin SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY no hay nada que arrancar: se
    // muestra el motivo en lugar de fallar con una excepcion opaca.
    // Envuelta en ProviderScope aunque hoy no lea ningun provider: asi no se
    // rompe en tiempo de ejecucion si esta pantalla pasa a consumir uno
    // (riverpod_lint: missing_provider_scope).
    Registro.info(
      'Configuración incompleta: falta SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY.',
    );
    runApp(const ProviderScope(child: PantallaConfiguracionInvalida()));
    return;
  }

  Registro.info('Entorno: ${configuracion.entorno.name}');

  await Supabase.initialize(
    url: configuracion.urlSupabase,
    // `publishableKey` sustituye al parametro `anonKey`, ya obsoleto. Acepta
    // tanto una clave `sb_publishable_...` como la clave anonima heredada.
    publishableKey: configuracion.clavePublicaSupabase,
    authOptions: const FlutterAuthClientOptions(
      // La PWA recibe el enlace de recuperacion como fragmento en la URL; el
      // cliente lo canjea al arrancar y emite `passwordRecovery`.
      detectSessionInUri: true,
    ),
  );

  runApp(
    ProviderScope(
      // Deja en la consola de depuracion los errores que viajan dentro de los
      // providers, que de otro modo solo se verian como un mensaje en pantalla.
      observers: const [ObservadorProviders()],
      child: const AppAimarTrainer(),
    ),
  );
}
