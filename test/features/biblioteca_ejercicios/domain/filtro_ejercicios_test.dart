import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

Ejercicio _ejercicio({
  String id = '1',
  String nombre = 'Press banca',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
  EstadoEjercicio estado = EstadoEjercicio.activo,
  GrupoMuscular? grupoDeclarado,
  Musculo? musculoPrincipal = Musculo.porcionEsternoCostal,
  List<Musculo> musculosSecundarios = const [Musculo.triceps],
  String? equipamiento = 'Barra',
}) => Ejercicio(
  id: id,
  nombre: nombre,
  descripcion: 'Descripción.',
  tipo: tipo,
  estado: estado,
  creadoEn: DateTime.utc(2026),
  grupoDeclarado: grupoDeclarado,
  musculoPrincipal: musculoPrincipal,
  musculosSecundarios: musculosSecundarios,
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
    test('busca en nombre, equipamiento y nombres de la taxonomía', () {
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
      // Por el nombre del musculo, principal o secundario.
      expect(
        const FiltroEjercicios(texto: 'esterno').aceptar(_ejercicio()),
        isTrue,
      );
      expect(
        const FiltroEjercicios(texto: 'tríceps').aceptar(_ejercicio()),
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
      final sinOpcionales = _ejercicio(
        musculoPrincipal: null,
        musculosSecundarios: const [],
        equipamiento: null,
      );

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

  group('FiltroEjercicios: tipo y taxonomía muscular', () {
    test('filtra por tipo', () {
      const soloCardio = FiltroEjercicios(tipo: TipoEjercicio.cardio);

      expect(soloCardio.aceptar(_ejercicio()), isFalse);
      expect(
        soloCardio.aceptar(_ejercicio(tipo: TipoEjercicio.cardio)),
        isTrue,
      );
    });

    test('filtra por grupo, derivándolo del músculo principal', () {
      const soloPierna = FiltroEjercicios(grupo: GrupoMuscular.pierna);

      expect(soloPierna.aceptar(_ejercicio()), isFalse);
      expect(
        soloPierna.aceptar(_ejercicio(musculoPrincipal: Musculo.cuadriceps)),
        isTrue,
      );
    });

    test('el grupo guardado a mano vale cuando no hay principal', () {
      const soloPierna = FiltroEjercicios(grupo: GrupoMuscular.pierna);

      expect(
        soloPierna.aceptar(
          _ejercicio(
            musculoPrincipal: null,
            musculosSecundarios: const [],
            grupoDeclarado: GrupoMuscular.pierna,
          ),
        ),
        isTrue,
      );
    });

    // Lo que hace util declarar secundarios: si no contaran, solo servirian
    // para mirar la ficha.
    test('los secundarios cuentan, en el grupo y en el músculo', () {
      final sentadilla = _ejercicio(
        nombre: 'Sentadilla',
        musculoPrincipal: Musculo.cuadriceps,
        musculosSecundarios: const [Musculo.gluteo, Musculo.lumbar],
      );

      expect(
        const FiltroEjercicios(musculo: Musculo.gluteo).aceptar(sentadilla),
        isTrue,
      );
      // El lumbar es de Espalda, asi que la sentadilla sale tambien al filtrar
      // por ese grupo.
      expect(
        const FiltroEjercicios(grupo: GrupoMuscular.espalda)
            .aceptar(sentadilla),
        isTrue,
      );
      expect(
        const FiltroEjercicios(musculo: Musculo.biceps).aceptar(sentadilla),
        isFalse,
      );
    });

    test('con el principal delante y los secundarios detrás', () {
      final hipThrust = _ejercicio(
        id: '2',
        nombre: 'Hip thrust',
        musculoPrincipal: Musculo.gluteo,
        musculosSecundarios: const [],
      );
      final sentadilla = _ejercicio(
        nombre: 'Sentadilla',
        musculoPrincipal: Musculo.cuadriceps,
        musculosSecundarios: const [Musculo.gluteo],
      );

      final orden = const FiltroEjercicios(musculo: Musculo.gluteo)
          .aplicar([sentadilla, hipThrust]);

      expect(orden.map((e) => e.nombre), ['Hip thrust', 'Sentadilla']);
    });

    test('la pestaña de sin clasificar muestra solo esos', () {
      const soloSin = FiltroEjercicios(soloSinClasificar: true);

      expect(soloSin.aceptar(_ejercicio()), isFalse);
      expect(
        soloSin.aceptar(
          _ejercicio(musculoPrincipal: null, musculosSecundarios: const []),
        ),
        isTrue,
      );
    });

    test('los criterios se combinan con AND', () {
      const filtro = FiltroEjercicios(
        texto: 'press',
        tipo: TipoEjercicio.fuerza,
        grupo: GrupoMuscular.pecho,
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
      expect(
        const FiltroEjercicios(grupo: GrupoMuscular.pecho).estaVacio,
        isFalse,
      );
      expect(
        const FiltroEjercicios(musculo: Musculo.gluteo).estaVacio,
        isFalse,
      );
      expect(const FiltroEjercicios(soloEliminados: true).estaVacio, isFalse);
      expect(
        const FiltroEjercicios(soloSinClasificar: true).estaVacio,
        isFalse,
      );
    });
  });
}
