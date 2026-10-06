import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

import '../ayudas_planificacion.dart';

void main() {
  group('DatosEjercicioPlanificado: Fuerza y Cardio se excluyen', () {
    // Es la regla central de la fase. El trigger la garantiza en la base de
    // datos; estas comprobaciones evitan llegar hasta alli.

    test('Cardio exige minutos', () {
      final sinMinutos = datosEjercicio(tipo: TipoEjercicio.cardio);

      expect(sinMinutos.validar()?.campo, 'minutos');
    });

    test('Cardio con minutos es valido', () {
      final datos = datosEjercicio(tipo: TipoEjercicio.cardio, minutos: 30);

      expect(datos.validar(), isNull);
    });

    test('Cardio rechaza series', () {
      final conSeries = datosEjercicio(
        tipo: TipoEjercicio.cardio,
        minutos: 30,
        series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
      );

      expect(conSeries.validar()?.campo, 'series');
    });

    test('Cardio rechaza descanso entre series', () {
      final conDescanso = datosEjercicio(
        tipo: TipoEjercicio.cardio,
        minutos: 30,
        descansoSeg: 90,
      );

      expect(conDescanso.validar()?.campo, 'descansoSeg');
    });

    test('Fuerza exige al menos una serie', () {
      final sinSeries = datosEjercicio(tipo: TipoEjercicio.fuerza);

      expect(sinSeries.validar()?.campo, 'series');
    });

    test('Fuerza rechaza minutos', () {
      final conMinutos = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        minutos: 30,
        series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
      );

      expect(conMinutos.validar()?.campo, 'minutos');
    });

    test('Fuerza con series es valido', () {
      final datos = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        descansoSeg: 90,
        series: [
          const DatosSerie(numeroSerie: 1, repeticiones: 10, peso: 60, rir: 2),
          const DatosSerie(numeroSerie: 2, repeticiones: 8, peso: 65, rir: 1),
        ],
      );

      expect(datos.validar(), isNull);
    });

    test('el JSON pone a null los campos del tipo que no aplica', () {
      // Al editar y cambiar de Cardio a Fuerza, los minutos tienen que limpiarse:
      // si no, el trigger rechazaria la fila por tener ambos.
      final fuerza = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        descansoSeg: 90,
        series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
      ).aJson();
      expect(fuerza['minutos_planificados'], isNull);
      expect(fuerza['descanso_planificado_seg'], 90);

      final cardio = datosEjercicio(
        tipo: TipoEjercicio.cardio,
        minutos: 30,
      ).aJson();
      expect(cardio['descanso_planificado_seg'], isNull);
      expect(cardio['minutos_planificados'], 30);
    });
  });

  group('DatosEjercicioPlanificado: series', () {
    test('rechaza dos series con el mismo número', () {
      final datos = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        series: [
          const DatosSerie(numeroSerie: 1, repeticiones: 10),
          const DatosSerie(numeroSerie: 1, repeticiones: 8),
        ],
      );

      expect(datos.validar()?.campo, 'series');
    });

    test('propaga el error de una serie concreta', () {
      final datos = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        series: [
          const DatosSerie(numeroSerie: 1, repeticiones: 10),
          const DatosSerie(numeroSerie: 2, repeticiones: 0),
        ],
      );

      expect(datos.validar()?.campo, 'repeticiones');
    });

    test('rechaza el orden ya ocupado en el bloque', () {
      final bloque = bloqueDePrueba(
        ejercicios: [ejercicioPlanificadoDePrueba(orden: 1)],
      );
      final datos = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        orden: 1,
        series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
      );

      expect(datos.validar(bloque: bloque)?.campo, 'orden');
    });

    test('al editar, su propio orden no cuenta como ocupado', () {
      final existente = ejercicioPlanificadoDePrueba(id: 'ep-1', orden: 1);
      final bloque = bloqueDePrueba(ejercicios: [existente]);
      final datos = datosEjercicio(
        tipo: TipoEjercicio.fuerza,
        orden: 1,
        series: [const DatosSerie(numeroSerie: 1, repeticiones: 10)],
      );

      expect(datos.validar(bloque: bloque, idQueSeEdita: 'ep-1'), isNull);
    });
  });

  group('DatosSerie: limites', () {
    test('las repeticiones deben ser positivas y razonables', () {
      expect(DatosSerie.validarRepeticiones(0)?.campo, 'repeticiones');
      expect(DatosSerie.validarRepeticiones(1000)?.campo, 'repeticiones');
      expect(DatosSerie.validarRepeticiones(10), isNull);
    });

    test('el peso es opcional pero positivo', () {
      expect(DatosSerie.validarPeso(null), isNull);
      expect(DatosSerie.validarPeso(0)?.campo, 'peso');
      expect(DatosSerie.validarPeso(60.5), isNull);
    });

    test('el RIR va de 0 a 10', () {
      expect(DatosSerie.validarRir(null), isNull);
      expect(DatosSerie.validarRir(0), isNull);
      expect(DatosSerie.validarRir(10), isNull);
      expect(DatosSerie.validarRir(-1)?.campo, 'rir');
      expect(DatosSerie.validarRir(11)?.campo, 'rir');
    });
  });

  group('DatosSesion: la sesión se numera dentro del planning', () {
    final planning = planningDePrueba(fechaInicio: DateTime(2026, 10, 5));

    test('el nombre es obligatorio', () {
      expect(
        const DatosSesion(
          planningId: 'p-1',
          orden: 1,
          nombre: '   ',
        ).validar(planning: planning)?.campo,
        'nombre',
      );
    });

    test('el número de día empieza en 1', () {
      expect(
        DatosSesion.validarOrdenLibre(orden: 0, planning: planning)?.campo,
        'orden',
      );
    });

    test('rechaza un número que ya tiene otra sesión', () {
      final conSesion = planningDePrueba(
        fechaInicio: DateTime(2026, 10, 5),
        sesiones: [sesionDePrueba(id: 's-1', orden: 2)],
      );

      expect(
        DatosSesion.validarOrdenLibre(orden: 2, planning: conSesion)?.campo,
        'orden',
      );
    });

    test('al editar, su propio número no cuenta como ocupado', () {
      final conSesion = planningDePrueba(
        fechaInicio: DateTime(2026, 10, 5),
        sesiones: [sesionDePrueba(id: 's-1', orden: 2)],
      );

      expect(
        DatosSesion.validarOrdenLibre(
          orden: 2,
          planning: conSesion,
          idSesionQueSeEdita: 's-1',
        ),
        isNull,
      );
    });

    test('siguienteOrden propone el número que toca', () {
      final conDos = planningDePrueba(
        sesiones: [
          sesionDePrueba(id: 's-1', orden: 1),
          sesionDePrueba(id: 's-2', orden: 2),
        ],
      );

      expect(conDos.siguienteOrden, 3);
      expect(planningDePrueba().siguienteOrden, 1);
    });

    test('el nombre es obligatorio', () {
      expect(DatosSesion.validarNombre('   ')?.campo, 'nombre');
    });
  });

  group('DatosBloque: orden dentro de la sesión', () {
    test('rechaza un orden ya ocupado', () {
      final sesion = sesionDePrueba(
        bloques: [bloqueDePrueba(id: 'b-1', orden: 1)],
      );

      expect(
        DatosBloque.validarOrdenLibre(orden: 1, sesion: sesion)?.campo,
        'orden',
      );
    });

    test('el orden empieza en 1', () {
      expect(
        DatosBloque.validarOrdenLibre(
          orden: 0,
          sesion: sesionDePrueba(),
        )?.campo,
        'orden',
      );
    });
  });

  group('SemanaDelPlanning', () {
    final planning = planningDePrueba(fechaInicio: DateTime(2026, 10, 5));

    test('son siete días, del inicio al inicio + 6', () {
      expect(planning.dias, hasLength(7));
      expect(planning.dias.first, DateTime(2026, 10, 5));
      expect(planning.dias.last, DateTime(2026, 10, 11));
      expect(planning.fechaFin, DateTime(2026, 10, 11));
    });

    test('no se supone que empiece en lunes', () {
      // El dominio no lo exige: lo decide el entrenador.
      final enMiercoles = planningDePrueba(fechaInicio: DateTime(2026, 10, 7));

      expect(enMiercoles.dias.first.weekday, DateTime.wednesday);
      expect(enMiercoles.contiene(DateTime(2026, 10, 13)), isTrue);
    });

    test('sesionNumero encuentra la sesión por su día', () {
      final conSesion = planningDePrueba(
        sesiones: [sesionDePrueba(id: 's-1', orden: 3)],
      );

      expect(conSesion.sesionNumero(3)?.id, 's-1');
      expect(conSesion.sesionNumero(1), isNull);
    });

    test('siguientePendiente es la primera sin terminar', () {
      final conDos = planningDePrueba(
        sesiones: [
          sesionDePrueba(id: 's-1', orden: 1, resultadoRegistrado: true),
          sesionDePrueba(id: 's-2', orden: 2),
        ],
      );

      expect(conDos.siguientePendiente?.id, 's-2');
    });

    test('un planning archivado no es editable', () {
      expect(planning.esEditable, isTrue);
      expect(
        planningDePrueba(estado: EstadoPlanning.archivado).esEditable,
        isFalse,
      );
    });
  });

  group('enums alineados con Postgres', () {
    test('estado_planning', () {
      expect(EstadoPlanning.values.map((e) => e.name), ['activo', 'archivado']);
    });

    test('tipo_bloque', () {
      expect(TipoBloque.values.map((t) => t.name), [
        'calentamiento',
        'fuerza',
        'cardio',
        'movilidad',
        'otro',
      ]);
    });

    test('estado_registro', () {
      expect(EstadoRegistro.values.map((e) => e.name), [
        'pendiente',
        'registrado',
      ]);
    });

    test('estado_ejercicio sigue alineado', () {
      expect(EstadoEjercicio.values.map((e) => e.name), [
        'activo',
        'eliminado',
      ]);
    });
  });

  group('soloFecha', () {
    test('formato YYYY-MM-DD con ceros', () {
      expect(soloFecha(DateTime(2026, 1, 5)), '2026-01-05');
      expect(soloFecha(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });
}
