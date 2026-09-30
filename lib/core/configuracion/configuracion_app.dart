/// Configuracion inyectada en tiempo de compilacion con `--dart-define`.
///
/// Nunca debe contener secretos de servidor (`SUPABASE_SERVICE_ROLE_KEY`,
/// `RESEND_API_KEY`): todo lo que llega por `--dart-define` acaba en el bundle
/// publico de la PWA.
enum EntornoApp {
  desarrollo,
  produccion;

  static EntornoApp desdeNombre(String valor) => switch (valor) {
    'production' || 'produccion' => EntornoApp.produccion,
    _ => EntornoApp.desarrollo,
  };
}

class ConfiguracionApp {
  const ConfiguracionApp({
    required this.urlSupabase,
    required this.clavePublicaSupabase,
    required this.entorno,
  });

  /// Lee los `--dart-define` del build. Ver `AGENTS.md` (comando `flutter build web`).
  factory ConfiguracionApp.desdeEntorno() => ConfiguracionApp(
    urlSupabase: const String.fromEnvironment('SUPABASE_URL'),
    clavePublicaSupabase: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    entorno: EntornoApp.desdeNombre(
      const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    ),
  );

  final String urlSupabase;
  final String clavePublicaSupabase;
  final EntornoApp entorno;

  bool get esValida =>
      urlSupabase.isNotEmpty && clavePublicaSupabase.isNotEmpty;

  /// URL a la que Supabase redirige el enlace de restablecimiento de contrasena.
  Uri get urlRedireccionRestablecerContrasena => Uri.base.replace(
    fragment: '/restablecer-contrasena',
    queryParameters: null,
  );
}
