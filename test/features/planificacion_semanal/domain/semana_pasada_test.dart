import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';

import '../ayudas_planificacion.dart';

/// POR QUE ESTE TEST: "lo pasado no se toca" es una regla de dominio, y el
/// interruptor del que cuelga toda la interfaz es `esEditable`. Si alguien lo
/// simplifica a `estado.esActivo` otra vez, el editor volvería a dejar cambiar
/// semanas terminadas y solo lo cazaría el trigger, con un error en pantalla.
///
/// Las fechas se **calculan** desde `Semana.deHoy()` a propósito: fijarlas
/// haría que estos tests cambiaran de resultado según el día.
void main() {
  final actual = Semana.deHoy();

  group('Semana.esPasada', () {
    test('la semana en curso no es pasada, ni siquiera el domingo', () {
      expect(actual.esPasada, isFalse);
    });

    test('la anterior sí y la siguiente no', () {
      expect(actual.anterior.esPasada, isTrue);
      expect(actual.siguiente.esPasada, isFalse);
    });
  });

  group('PlanningSemanal.esEditable', () {
    test('la semana en curso y las futuras se editan', () {
      expect(planningDePrueba(fechaInicio: actual.lunes).esEditable, isTrue);
      expect(
        planningDePrueba(fechaInicio: actual.siguiente.lunes).esEditable,
        isTrue,
      );
    });

    test('una semana que ya pasó, no', () {
      expect(
        planningDePrueba(fechaInicio: actual.anterior.lunes).esEditable,
        isFalse,
      );
    });

    // La regla no sustituye a la de archivar: siguen siendo dos motivos
    // distintos para lo mismo.
    test('archivado tampoco se edita, aunque sea de esta semana', () {
      expect(
        planningDePrueba(
          fechaInicio: actual.lunes,
          estado: EstadoPlanning.archivado,
        ).esEditable,
        isFalse,
      );
    });
  });
}
