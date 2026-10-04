import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Componentes que se repiten en varias pantallas del diseno
/// (`docs/ui-design.md`, seccion 5).
///
/// Viven aqui y no en una feature porque los usan las dos (cliente y
/// entrenador), y ninguno sabe nada de dominio: reciben datos y callbacks.

/// Tarjeta base: fondo `surface`, borde 1px, radio 16 y la sombra estandar.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    required this.hijo,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.resaltada = false,
    this.color,
    super.key,
  });

  final Widget hijo;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Borde en color de acento, para la tarjeta que tiene el foco de la pantalla.
  final bool resaltada;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final forma = BorderRadius.circular(Tokens.radioTarjeta);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? Tokens.superficie,
        borderRadius: forma,
        border: Border.all(
          color: resaltada ? Tokens.acento : Tokens.borde,
          width: resaltada ? 1.5 : 1,
        ),
        boxShadow: Tokens.sombraTarjeta,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: forma,
        child: InkWell(
          onTap: onTap,
          borderRadius: forma,
          child: Padding(padding: padding, child: hijo),
        ),
      ),
    );
  }
}

/// Chip de filtro. Activo: fondo `accentSoft` y borde de acento.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({
    required this.etiqueta,
    required this.activo,
    required this.onPulsar,
    super.key,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback onPulsar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Material(
      color: activo ? Tokens.acentoSuave : Tokens.superficie2,
      borderRadius: BorderRadius.circular(Tokens.radioPastilla),
      child: InkWell(
        onTap: onPulsar,
        borderRadius: BorderRadius.circular(Tokens.radioPastilla),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radioPastilla),
            border: Border.all(color: activo ? Tokens.acento : Tokens.borde),
          ),
          child: Text(
            etiqueta,
            style: textos.bodyMedium?.copyWith(
              color: activo ? Tokens.acento : Tokens.textoSuave,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// Slider con la etiqueta a la izquierda y el valor a la derecha, como en el
/// check-in de recuperacion.
class SliderConValor extends StatelessWidget {
  const SliderConValor({
    required this.etiqueta,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.onCambio,
    this.divisiones,
    this.sufijo = '',
    this.habilitado = true,
    super.key,
  });

  final String etiqueta;
  final double valor;
  final double minimo;
  final double maximo;
  final ValueChanged<double> onCambio;
  final int? divisiones;
  final String sufijo;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final mostrado = valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(etiqueta, style: textos.titleSmall)),
            Text(
              '$mostrado$sufijo',
              style: textos.titleMedium?.copyWith(color: Tokens.acento),
            ),
          ],
        ),
        Slider(
          value: valor.clamp(minimo, maximo),
          min: minimo,
          max: maximo,
          divisions: divisiones,
          onChanged: habilitado ? onCambio : null,
        ),
      ],
    );
  }
}

/// Fila con interruptor: titulo, explicacion y el `Switch` a la derecha.
class FilaInterruptor extends StatelessWidget {
  const FilaInterruptor({
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.onCambio,
    this.clave,
    super.key,
  });

  final String titulo;
  final String descripcion;
  final bool valor;

  /// `null` deja el interruptor desactivado, sin que parezca un fallo.
  final ValueChanged<bool>? onCambio;
  final Key? clave;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textos.titleMedium),
                const SizedBox(height: 4),
                Text(descripcion, style: textos.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(key: clave, value: valor, onChanged: onCambio),
        ],
      ),
    );
  }
}

/// Boton de accion principal: ancho completo, 52 de alto, fondo de acento.
class BotonCta extends StatelessWidget {
  const BotonCta({
    required this.etiqueta,
    required this.onPulsar,
    this.icono = Icons.arrow_forward,
    this.cargando = false,
    super.key,
  });

  final String etiqueta;
  final VoidCallback? onPulsar;
  final IconData? icono;
  final bool cargando;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Tokens.alturaCta,
    width: double.infinity,
    child: FilledButton(
      onPressed: cargando ? null : onPulsar,
      child: cargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(etiqueta),
                if (icono != null) ...[
                  const SizedBox(width: 8),
                  Icon(icono, size: 18),
                ],
              ],
            ),
    ),
  );
}

/// Etiqueta en pastilla, para el grupo muscular o el tipo de ejercicio.
class Pastilla extends StatelessWidget {
  const Pastilla({required this.texto, this.color = Tokens.acento, super.key});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(Tokens.radioPastilla),
    ),
    child: Text(
      texto.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// Progreso circular con el recuento dentro ("2/5"), para la sesion del dia.
class ProgresoCircular extends StatelessWidget {
  const ProgresoCircular({
    required this.hechos,
    required this.total,
    this.lado = 56,
    super.key,
  });

  final int hechos;
  final int total;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // Una sesion sin ejercicios no tiene progreso que mostrar, y dividir entre
    // cero daria NaN.
    final proporcion = total == 0 ? 0.0 : hechos / total;

    return SizedBox(
      width: lado,
      height: lado,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: proporcion,
              strokeWidth: 4,
              backgroundColor: Tokens.superficie3,
              valueColor: const AlwaysStoppedAnimation(Tokens.acento),
            ),
          ),
          Text(
            '$hechos/$total',
            style: textos.labelMedium?.copyWith(color: Tokens.texto),
          ),
        ],
      ),
    );
  }
}

/// Buscador con el icono de lupa, igual en la biblioteca del cliente y en el
/// panel del entrenador.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({
    required this.controlador,
    required this.onCambio,
    this.pista = 'Buscar ejercicio',
    this.clave,
    super.key,
  });

  final TextEditingController controlador;
  final ValueChanged<String> onCambio;
  final String pista;
  final Key? clave;

  @override
  Widget build(BuildContext context) => TextField(
    key: clave,
    controller: controlador,
    onChanged: onCambio,
    decoration: InputDecoration(
      hintText: pista,
      prefixIcon: const Icon(Icons.search, color: Tokens.textoSuave),
    ),
  );
}
