import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/filtro_de_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';

/// Buscador, filtro y lista para **elegir un ejercicio de la biblioteca**.
///
/// Lo comparten el formulario de un ejercicio del bloque (CU-08) y el del pack
/// (RF-25.1), que tenian cada uno su copia.
///
/// Se pinta de dos formas:
/// - **En movil**, entre los campos del formulario: la lista va acotada, porque
///   dentro de algo que ya se desplaza, una lista sin limite empuja los demas
///   campos fuera de la pantalla.
/// - **En el panel lateral de escritorio** ([enPanel]), con sitio: dos columnas
///   con su propio desplazamiento. Filtros siempre a la vista, a un clic, y al
///   filtrar los ejercicios salen arriba, sin bajar hasta ellos.
/// - **En el mismo panel, si es estrecho**: una columna con el filtro muscular
///   abierto, y filtro y lista se desplazan juntos, para no repartir el alto
///   entre los dos (el desborde del panel del planning).
class ElegirDeBiblioteca extends ConsumerWidget {
  const ElegirDeBiblioteca({
    required this.ambito,
    required this.prefijoClave,
    required this.habilitado,
    required this.onElegir,
    this.enPanel = false,
    this.elegido,
    super.key,
  });

  /// De quien es el filtro: cada formulario tiene el suyo.
  final AmbitoDeFiltro ambito;

  /// Clave de cada fila: `<prefijoClave>_<id del ejercicio>`.
  final String prefijoClave;
  final bool habilitado;
  final ValueChanged<Ejercicio> onElegir;
  final bool enPanel;

  /// Lo que ya esta elegido, para marcarlo: en el panel la lista sigue a la
  /// vista despues de elegir, y asi se puede cambiar de un toque.
  final Ejercicio? elegido;

  static const double _altoMaximoLista = 260;

  /// Ancho del panel a partir del cual filtros y lista van en dos columnas.
  static const double _anchoParaColumnas = 640;

  /// Ancho minimo de una fila de ejercicio, del que salen las columnas de la
  /// lista cuando hay pantalla de sobra.
  static const double _anchoDeFila = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final filtrados = ref.watch(ejerciciosFiltradosProvider(ambito));
    final filtroActual = ref.watch(filtroBibliotecaProvider(ambito));
    // Al abrir el panel para anadir, no al editar: ahi se viene a tocar el
    // resto de campos.
    final conCursor = enPanel && elegido == null;
    final filtro = FiltroDeEjercicios(
      ambito: ambito,
      habilitado: habilitado,
      musculosAbiertos: enPanel,
      autofocus: conCursor,
    );

    Widget fila(Ejercicio ejercicio) {
      final esElElegido = elegido?.id == ejercicio.id;
      return Tarjeta(
        key: Key('${prefijoClave}_${ejercicio.id}'),
        padding: const EdgeInsets.all(10),
        onTap: habilitado ? () => onElegir(ejercicio) : null,
        hijo: Row(
          children: [
            MiniaturaEjercicio(ejercicio: ejercicio, lado: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ejercicio.nombre, style: textos.titleSmall),
                  // Con el tipo: decide si se le preparan series o minutos.
                  Text(
                    [
                      ?ejercicio.resumenMuscular,
                      ejercicio.tipo.etiqueta,
                    ].join(' · '),
                    style: textos.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              esElElegido ? Icons.check_circle : Icons.chevron_right,
              size: 18,
              color: esElElegido ? Tokens.acento : Tokens.textoTenue,
            ),
          ],
        ),
      );
    }

    Widget sinResultados() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Ningún ejercicio coincide con la búsqueda.',
        style: textos.bodySmall,
      ),
    );

    /// La lista de la columna derecha, en tantas columnas como quepan.
    Widget listaEnColumnas(List<Ejercicio> lista, double ancho) {
      final columnas = ((ancho - 2 * Tokens.margenPantalla) / _anchoDeFila)
          .floor()
          .clamp(1, 3);
      return ListView.builder(
        // Clave por filtro: cada filtro nuevo vuelve a empezar arriba, que es
        // el motivo de separar las columnas.
        key: ValueKey(
          Object.hash(
            filtroActual.texto,
            filtroActual.tipo,
            filtroActual.grupo,
            filtroActual.musculo,
          ),
        ),
        padding: const EdgeInsets.all(Tokens.margenPantalla),
        itemCount: (lista.length / columnas).ceil(),
        itemBuilder: (context, indice) {
          final tramo = lista.skip(indice * columnas).take(columnas).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Las filas de una misma altura, aunque un nombre ocupe dos lineas.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columnas; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: i < tramo.length
                          ? fila(tramo[i])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    if (enPanel) {
      return LayoutBuilder(
        builder: (context, limites) {
          if (limites.maxWidth >= _anchoParaColumnas) {
            final anchoFiltros = (limites.maxWidth * 0.36).clamp(300.0, 420.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: anchoFiltros,
                  child: SingleChildScrollView(
                    key: const Key('columna_filtros'),
                    padding: const EdgeInsets.all(Tokens.margenPantalla),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biblioteca de ejercicios',
                          style: textos.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        FiltroDeEjercicios(
                          ambito: ambito,
                          habilitado: habilitado,
                          musculosALaVista: true,
                          autofocus: conCursor,
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Tokens.borde),
                Expanded(
                  key: const Key('columna_ejercicios'),
                  child: filtrados.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(Tokens.margenPantalla),
                      child: AvisoEnLinea(mensaje: mensajeDeError(error)),
                    ),
                    data: (lista) => lista.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(
                              Tokens.margenPantalla,
                            ),
                            child: sinResultados(),
                          )
                        : listaEnColumnas(
                            lista,
                            limites.maxWidth - anchoFiltros,
                          ),
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Tokens.margenPantalla),
            children: [
              Text('Biblioteca de ejercicios', style: textos.titleMedium),
              const SizedBox(height: 12),
              filtro,
              const SizedBox(height: 8),
              ...filtrados.when(
                loading: () => const [
                  Center(child: CircularProgressIndicator()),
                ],
                error: (error, _) => [
                  AvisoEnLinea(mensaje: mensajeDeError(error)),
                ],
                data: (lista) => lista.isEmpty
                    ? [sinResultados()]
                    : [
                        for (final ejercicio in lista) ...[
                          fila(ejercicio),
                          const SizedBox(height: 8),
                        ],
                      ],
              ),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filtro,
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _altoMaximoLista),
          child: filtrados.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AvisoEnLinea(mensaje: mensajeDeError(error)),
            data: (lista) => lista.isEmpty
                ? sinResultados()
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, indice) => fila(lista[indice]),
                  ),
          ),
        ),
      ],
    );
  }
}
