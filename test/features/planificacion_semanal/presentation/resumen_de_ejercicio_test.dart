import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mi_planning.dart';

import '../ayudas_planificacion.dart';

/// Es la línea que el cliente lee de cada ejercicio en su día: "4 series · 60 kg
/// por lado", "30 min". Se mira **por el tipo** y no por si hay minutos,
/// porque desde el 2026-10-19 un cardio puede quedarse sin ellos (al aplicar un
/// pack que no los traía) y entonces caía en la rama de las series diciendo
/// "Sin series planificadas".
void main() {
  test('un cardio con minutos los dice', () {
    final cardio = ejercicioPlanificadoDePrueba(
      ejercicio: ejercicioDePrueba(id: 'ej-c', tipo: TipoEjercicio.cardio),
      minutosPlanificados: 30,
    );

    expect(resumenDeEjercicio(cardio), '30 min');
  });

  test('un cardio sin minutos dice que faltan, no habla de series', () {
    final cardio = ejercicioPlanificadoDePrueba(
      ejercicio: ejercicioDePrueba(id: 'ej-c', tipo: TipoEjercicio.cardio),
    );

    expect(resumenDeEjercicio(cardio), 'Sin minutos planificados');
  });

  test('una fuerza sin series lo dice', () {
    expect(
      resumenDeEjercicio(ejercicioPlanificadoDePrueba()),
      'Sin series planificadas',
    );
  });

  test('una fuerza con series resume cuántas y el rango de peso', () {
    final fuerza = ejercicioPlanificadoDePrueba(
      series: [
        serieDePrueba(numeroSerie: 1, peso: 60),
        serieDePrueba(id: 'sp-2', numeroSerie: 2, peso: 65),
      ],
    );

    expect(resumenDeEjercicio(fuerza), '2 series · 60-65 kg');
  });

  test('con el peso por lado, lo dice', () {
    final fuerza = ejercicioPlanificadoDePrueba(
      ejercicio: ejercicioDePrueba().copyWith(pesoPorLado: true),
      series: [serieDePrueba(peso: 7.5)],
    );

    expect(resumenDeEjercicio(fuerza), '1 serie · 7.5 kg por lado');
  });
}
