import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';

/// Fila del listado de la biblioteca.
///
/// `acciones` llega vacio para el cliente: la vista de solo lectura es la misma
/// pantalla sin botones de edicion ni baja.
class TarjetaEjercicio extends StatelessWidget {
  const TarjetaEjercicio({
    required this.ejercicio,
    this.onTap,
    this.acciones = const [],
    super.key,
  });

  final Ejercicio ejercicio;
  final VoidCallback? onTap;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final eliminado = ejercicio.estado.estaEliminado;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Flexible(
              child: Text(
                ejercicio.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: eliminado ? TextDecoration.lineThrough : null,
                  color: eliminado ? esquema.outline : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Etiqueta(
              texto: ejercicio.tipo.etiqueta,
              color: esquema.primaryContainer,
              colorTexto: esquema.onPrimaryContainer,
            ),
            if (eliminado) ...[
              const SizedBox(width: 4),
              _Etiqueta(
                texto: 'Dado de baja',
                color: esquema.surfaceContainerHighest,
                colorTexto: esquema.onSurfaceVariant,
              ),
            ],
          ],
        ),
        subtitle: Text(
          [?ejercicio.grupoMuscular, ?ejercicio.equipamiento].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: acciones.isEmpty
            ? (ejercicio.videoEjemploUrl != null
                  ? Icon(Icons.play_circle_outline, color: esquema.primary)
                  : null)
            : Row(mainAxisSize: MainAxisSize.min, children: acciones),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.color,
    required this.colorTexto,
  });

  final String texto;
  final Color color;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(texto, style: TextStyle(fontSize: 11, color: colorTexto)),
  );
}
