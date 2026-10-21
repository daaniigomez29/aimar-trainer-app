import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';

/// POR QUE ESTE TEST: el arrastre es facil de dejar "casi bien". Mover un
/// elemento una posicion hacia abajo y que se quede donde estaba es el fallo
/// clasico de `ReorderableListView`, y no se ve en una captura: se ve al soltar.
void main() {
  // Quitar no renumera, asi que puede haber huecos: "cuantos hay + 1" choca
  // con una posicion ocupada (le paso a Aimar el 2026-10-21).
  group('siguientePosicion', () {
    test('sin nada, empieza en 1', () {
      expect(siguientePosicion(const []), 1);
    });

    test('sin huecos, coincide con cuantos hay + 1', () {
      expect(siguientePosicion(const [1, 2, 3]), 4);
    });

    test('con un hueco, va detras del mas alto', () {
      expect(siguientePosicion(const [1, 2, 3, 4, 5, 7]), 8);
    });

    test('da igual el orden en que lleguen', () {
      expect(siguientePosicion(const [7, 1, 3]), 8);
    });
  });

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
