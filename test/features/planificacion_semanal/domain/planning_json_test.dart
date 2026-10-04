import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Respuesta real de PostgREST a la consulta de `obtenerPlanningCompleto`,
/// capturada contra Supabase local y recortada a lo imprescindible.
///
/// POR QUE ESTE TEST: los recursos incrustados llegan con el **nombre de la
/// tabla** (`sesiones_entrenamiento`), no con el del campo de la entidad
/// (`sesiones`). A `PlanningSemanal.sesiones` le faltaba su `@JsonKey`, asi que
/// `@Default([])` la dejaba vacia **en silencio**: el planning se veia como una
/// semana entera de descanso y la pantalla ofrecia crear una sesion en un dia que
/// ya tenia una. Ni el script de la API ni los tests de widget podian verlo,
/// porque los primeros no pasan por las entidades y los segundos las construyen a
/// mano. Solo se ve parseando la forma de verdad.
const Map<String, dynamic> _respuestaReal = {
  'id': '9a1720f5-8d4c-4f1c-980b-40b04b91bad0',
  'cliente_id': '186175f6-9fd8-415d-9b49-d2717edea0e5',
  'fecha_inicio': '2026-11-23',
  'nombre_objetivo': 'Fixture',
  'estado': 'activo',
  'creado_en': '2026-10-03T11:07:24.561792+00:00',
  'sesiones_entrenamiento': [
    {
      'id': '1dd3eb64-2091-4577-b1d4-0f98a436329a',
      'orden': 1,
      'fecha_realizada': '2026-11-26',
      'nombre': 'Empuje',
      'planning_id': '9a1720f5-8d4c-4f1c-980b-40b04b91bad0',
      'resultado_registrado': true,
      'bloques_ejercicio': [
        {
          'id': 'a5463599-87b6-4b87-a55c-f3ca3a4d3da2',
          'tipo': 'fuerza',
          'notas': null,
          'orden': 1,
          'sesion_id': '1dd3eb64-2091-4577-b1d4-0f98a436329a',
          'ejercicios_planificados': [
            {
              'id': 'ca3c2661-69ee-40ff-bb9c-ffce96a25326',
              'orden': 1,
              'bloque_id': 'a5463599-87b6-4b87-a55c-f3ca3a4d3da2',
              'ejercicio_id': '41cebec2-8fcf-4a27-a31e-8991072a8e51',
              'estado_registro': 'registrado',
              'minutos_planificados': null,
              'minutos_realizados': null,
              'descanso_planificado_seg': 90,
              'ejercicios': {
                'id': '41cebec2-8fcf-4a27-a31e-8991072a8e51',
                'tipo': 'fuerza',
                'estado': 'activo',
                'nombre': 'JSON Fixture',
                'creado_en': '2026-10-03T11:07:24.560209+00:00',
                'descripcion': 'x',
                'equipamiento': null,
                'grupo_muscular': null,
                'video_ejemplo_url': null,
              },
              'series_planificadas': [
                {
                  'id': '3713502e-bd77-4d0e-9a82-95c2e8e11fa1',
                  'numero_serie': 1,
                  'rir_planificado': 2,
                  'peso_planificado': 60.0,
                  'repeticiones_planificadas': 10,
                  'ejercicio_planificado_id':
                      'ca3c2661-69ee-40ff-bb9c-ffce96a25326',
                },
              ],
              'series_realizadas': [
                {
                  'id': '0746ad41-ce69-4ee1-ab14-391ad336113f',
                  'rir_real': 1,
                  'peso_real': 60.0,
                  'numero_serie': 1,
                  'repeticiones_realizadas': 9,
                  'fecha_hora_registro': '2026-10-03T11:07:24.561792+00:00',
                  'ejercicio_planificado_id':
                      'ca3c2661-69ee-40ff-bb9c-ffce96a25326',
                },
              ],
            },
          ],
        },
      ],
    },
  ],
};

void main() {
  group('PlanningSemanal.fromJson con la respuesta de PostgREST', () {
    final planning = PlanningSemanal.fromJson(_respuestaReal);

    test('las sesiones llegan, no una lista vacia', () {
      expect(planning.sesiones, hasLength(1));
      expect(planning.sesiones.single.nombre, 'Empuje');
      expect(planning.sesiones.single.orden, 1);
    });

    test('la fecha que llega es la de realizacion, no una planificada', () {
      expect(planning.sesiones.single.fechaRealizada, DateTime(2026, 11, 26));
      expect(planning.sesionNumero(1), isNotNull);
      expect(planning.sesionNumero(2), isNull);
    });

    test('los bloques y sus ejercicios tambien', () {
      final bloque = planning.sesiones.single.bloques.single;

      expect(bloque.tipo, TipoBloque.fuerza);
      expect(bloque.ejercicios, hasLength(1));
      expect(bloque.ejercicios.single.ejercicio?.nombre, 'JSON Fixture');
      expect(bloque.ejercicios.single.ejercicio?.tipo, TipoEjercicio.fuerza);
    });

    test('las series planificadas y las realizadas son independientes', () {
      final ejercicio =
          planning.sesiones.single.bloques.single.ejercicios.single;

      expect(ejercicio.series.single.repeticionesPlanificadas, 10);
      expect(ejercicio.seriesRealizadas.single.repeticionesRealizadas, 9);
      expect(ejercicio.estadoRegistro, EstadoRegistro.registrado);
    });

    test('un planning sin sesiones no revienta', () {
      final vacio = PlanningSemanal.fromJson({
        ..._respuestaReal,
        'sesiones_entrenamiento': <dynamic>[],
      });

      expect(vacio.sesiones, isEmpty);
    });
  });
}
