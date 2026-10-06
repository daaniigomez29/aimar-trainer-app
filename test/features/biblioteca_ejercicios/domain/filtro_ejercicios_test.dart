import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

Ejercicio _ejercicio({
  String id = '1',
  String nombre = 'Press banca',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
  EstadoEjercicio estado = EstadoEjercicio.activo,
  String? grupoMuscular = 'Pecho',
  String? equipamiento = 'Barra',
}) => Ejercicio(
  id: id,
  nombre: nombre,
  descripcion: 'Descripción.',
  tipo: tipo,
  estado: estado,
  creadoEn: DateTime.utc(2026),
  grupoMuscular: grupoMuscular,
  equipamiento: equipamiento,
);

void main() {
  group('FiltroEjercicios: estado', () {
    test('por defecto oculta los dados de baja', () {
      const filtro = FiltroEjercicios();

      expect(filtro.aceptar(_ejercicio()), isTrue);
      expect(
        filtro.aceptar(_ejercicio(estado: EstadoEjercicio.eliminado)),
        isFalse,
      );
    });

    // El chip de "Dados de baja" es una pestana para revisar las bajas, no un
    // "además de": mezclarlas con los activos no deja ver cuales son.
    test('con soloEliminados muestra las bajas y SOLO las bajas', () {
      const filtro = FiltroEjercicios(soloEliminados: true);

      expect(
        filtro.aceptar(_ejercicio(estado: EstadoEjercicio.eliminado)),
        isTrue,
      );
      expect(filtro.aceptar(_ejercicio()), isFalse);
    });
  });

  group('FiltroEjercicios: texto', () {
    test('busca en nombre, grupo muscular y equipamiento', () {
      expect(
        const FiltroEjercicios(texto: 'banca').aceptar(_ejercicio()),
        isTrue,
      );
      expect(
        const FiltroEjercicios(texto: 'pecho').aceptar(_ejercicio()),
        isTrue,
      );
      expect(
        const FiltroEjercicios(texto: 'barra').aceptar(_ejercicio()),
        isTrue,
      );
    });

    test('no distingue mayusculas ni espacios alrededor', () {
      expect(
        const FiltroEjercicios(texto: '  PRESS  ').aceptar(_ejercicio()),
        isTrue,
      );
    });

    test('descarta lo que no coincide', () {
      expect(
        const FiltroEjercicios(texto: 'remo').aceptar(_ejercicio()),
        isFalse,
      );
    });

    test('no falla si los campos opcionales son null', () {
      final sinOpcionales = _ejercicio(grupoMuscular: null, equipamiento: null);

      expect(
        const FiltroEjercicios(texto: 'press').aceptar(sinOpcionales),
        isTrue,
      );
      expect(
        const FiltroEjercicios(texto: 'pecho').aceptar(sinOpcionales),
        isFalse,
      );
    });
  });

  group('FiltroEjercicios: tipo y grupo muscular', () {
    test('filtra por tipo', () {
      const soloCardio = FiltroEjercicios(tipo: TipoEjercicio.cardio);

      expect(soloCardio.aceptar(_ejercicio()), isFalse);
      expect(
        soloCardio.aceptar(_ejercicio(tipo: TipoEjercicio.cardio)),
        isTrue,
      );
    });

    test('filtra por grupo muscular', () {
      const soloPierna = FiltroEjercicios(grupoMuscular: 'Piernas');

      expect(soloPierna.aceptar(_ejercicio()), isFalse);
      expect(soloPierna.aceptar(_ejercicio(grupoMuscular: 'Piernas')), isTrue);
    });

    test('los criterios se combinan con AND', () {
      const filtro = FiltroEjercicios(
        texto: 'press',
        tipo: TipoEjercicio.fuerza,
        grupoMuscular: 'Pecho',
      );

      expect(filtro.aceptar(_ejercicio()), isTrue);
      expect(filtro.aceptar(_ejercicio(tipo: TipoEjercicio.cardio)), isFalse);
    });
  });

  group('FiltroEjercicios: estaVacio', () {
    test('un filtro recien creado esta vacío', () {
      expect(const FiltroEjercicios().estaVacio, isTrue);
    });

    test('deja de estarlo con cualquier criterio', () {
      expect(const FiltroEjercicios(texto: 'a').estaVacio, isFalse);
      expect(
        const FiltroEjercicios(tipo: TipoEjercicio.cardio).estaVacio,
        isFalse,
      );
      expect(const FiltroEjercicios(grupoMuscular: 'Pecho').estaVacio, isFalse);
      expect(const FiltroEjercicios(soloEliminados: true).estaVacio, isFalse);
    });
  });
}
