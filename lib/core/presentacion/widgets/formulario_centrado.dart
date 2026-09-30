import 'package:flutter/material.dart';

/// Contenedor de ancho limitado y centrado para los formularios de acceso.
///
/// Evita que en pantalla ancha (la PWA se usa tambien en escritorio) los campos
/// se estiren de lado a lado.
class FormularioCentrado extends StatelessWidget {
  const FormularioCentrado({
    required this.titulo,
    required this.hijos,
    this.subtitulo,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(titulo, style: textos.headlineSmall),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitulo!, style: textos.bodyMedium),
                  ],
                  const SizedBox(height: 24),
                  ...hijos,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso en linea para errores generales y confirmaciones.
class AvisoEnLinea extends StatelessWidget {
  const AvisoEnLinea({required this.mensaje, this.esError = true, super.key});

  final String mensaje;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fondo = esError ? esquema.errorContainer : esquema.secondaryContainer;
    final texto = esError
        ? esquema.onErrorContainer
        : esquema.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.check_circle_outline,
            color: texto,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: texto)),
          ),
        ],
      ),
    );
  }
}
