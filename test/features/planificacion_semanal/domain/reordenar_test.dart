import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';

/// POR QUE ESTE TEST: el arrastre es facil de dejar "casi bien". Mover un
/// elemento una posicion hacia abajo y que se quede donde estaba es el fallo
/// clasico de `ReorderableListView`, y no se ve en una captura: se ve al soltar.
void main() {
  group('reordenarLista', () {
    final lista = ['a', 'b', 'c', 'd'];

    test('mover el primero al final', () {
      expect(reordenarLista(lista, 0, 3), ['b', 'c', 'd', 'a']);
    });

    test('mover el último al principio', () {
      expect(reordenarLista(lista, 3, 0), ['d', 'a', 'b', 'c']);
    });

    test('bajar una sola posición mueve de verdad', () {
      expect(reordenarLista(lista, 0, 1), ['b', 'a', 'c', 'd']);
    });

    test('subir una sola posición', () {
      expect(reordenarLista(lista, 2, 1), ['a', 'c', 'b', 'd']);
    });

    test('dejarlo donde estaba no cambia nada', () {
      expect(reordenarLista(lista, 2, 2), lista);
    });

    test('no toca la lista original', () {
      reordenarLista(lista, 0, 3);
      expect(lista, ['a', 'b', 'c', 'd']);
    });

    test('un índice imposible se ignora en vez de reventar', () {
      expect(reordenarLista(lista, 9, 0), lista);
      expect(reordenarLista(lista, 0, 99), ['b', 'c', 'd', 'a']);
    });
  });

  group('validarReordenacion', () {
    test('una permutacion completa vale', () {
      expect(
        validarReordenacion(
          idsEnOrden: ['c', 'a', 'b'],
          idsActuales: ['a', 'b', 'c'],
        ),
        isNull,
      );
    });

    test('faltan elementos', () {
      expect(
        validarReordenacion(
          idsEnOrden: ['a', 'b'],
          idsActuales: ['a', 'b', 'c'],
        ),
        isNotNull,
      );
    });

    test('hay repetidos', () {
      expect(
        validarReordenacion(
          idsEnOrden: ['a', 'a', 'b'],
          idsActuales: ['a', 'b', 'c'],
        ),
        isNotNull,
      );
    });

    test('aparece uno que no estaba', () {
      expect(
        validarReordenacion(
          idsEnOrden: ['a', 'b', 'z'],
          idsActuales: ['a', 'b', 'c'],
        ),
        isNotNull,
      );
    });
  });
}
