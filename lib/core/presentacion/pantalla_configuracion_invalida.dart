import 'package:flutter/material.dart';

/// Se muestra cuando el build no recibio `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY`
/// por `--dart-define`.
class PantallaConfiguracionInvalida extends StatelessWidget {
  const PantallaConfiguracionInvalida({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  'Configuracion incompleta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Falta SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY. Compila con '
                  '--dart-define=SUPABASE_URL=... '
                  '--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
