import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/modo_planificacion.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

DatosEjercicio _datos({
  String nombre = 'Press banca',
  String descripcion = 'Tumbado en banco plano, baja la barra al pecho.',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
  GrupoMuscular? grupoDeclarado,
  Musculo? musculoPrincipal,
  List<Musculo> musculosSecundarios = const [],
  String? equipamiento,
  String? video,
}) => DatosEjercicio(
  nombre: nombre,
  descripcion: descripcion,
  tipo: tipo,
  grupoDeclarado: grupoDeclarado,
  musculoPrincipal: musculoPrincipal,
  musculosSecundarios: musculosSecundarios,
  equipamiento: equipamiento,
  videoEjemploUrl: video,
);

void main() {
  group('DatosEjercicio.validarNombre (CU-02, paso 4)', () {
    test('rechaza el nombre vacío o solo espacios', () {
      expect(DatosEjercicio.validarNombre('')?.campo, 'nombre');
      expect(DatosEjercicio.validarNombre('   ')?.campo, 'nombre');
    });

    test('rechaza un nombre mas largo que el máximo', () {
      final largo = 'a' * (DatosEjercicio.longitudMaximaNombre + 1);

      expect(DatosEjercicio.validarNombre(largo)?.campo, 'nombre');
    });

    test('acepta el nombre justo en el máximo', () {
      final justo = 'a' * DatosEjercicio.longitudMaximaNombre;

      expect(DatosEjercicio.validarNombre(justo), isNull);
    });
  });

  group('DatosEjercicio.validarDescripcion', () {
    // Hay ejercicios que se explican solos, y obligar a escribir algo solo
    // conseguia rellenos. Vacia se guarda como cadena vacia, que la columna
    // `not null` admite.
    test('es opcional', () {
      expect(DatosEjercicio.validarDescripcion(''), isNull);
      expect(DatosEjercicio.validarDescripcion('  '), isNull);
    });

    test('acepta una descripción normal', () {
      expect(DatosEjercicio.validarDescripcion('Baja controlado.'), isNull);
    });
  });

  group('DatosEjercicio.validarVideo', () {
    test('es opcional', () {
      expect(DatosEjercicio.validarVideo(null), isNull);
      expect(DatosEjercicio.validarVideo(''), isNull);
      expect(DatosEjercicio.validarVideo('   '), isNull);
    });

    test('acepta http y https', () {
      expect(DatosEjercicio.validarVideo('https://ejemplo.com/v'), isNull);
      expect(DatosEjercicio.validarVideo('http://ejemplo.com/v'), isNull);
    });

    test('rechaza lo que no sea una URL http(s)', () {
      for (final invalida in [
        'ejemplo.com/video',
        'ftp://ejemplo.com/v',
        'javascript:alert(1)',
        'https://',
      ]) {
        expect(
          DatosEjercicio.validarVideo(invalida)?.campo,
          'videoEjemploUrl',
          reason: 'deberia rechazar "$invalida"',
        );
      }
    });
  });

  group('DatosEjercicio: normalizacion', () {
    test('recorta el nombre y deja en null los opcionales vacios', () {
      final datos = _datos(
        nombre: '  Sentadilla  ',
        equipamiento: '',
        video: '  ',
      );

      expect(datos.nombreNormalizado, 'Sentadilla');
      expect(datos.equipamientoNormalizado, isNull);
      expect(datos.videoEjemploUrlNormalizada, isNull);
    });

    test('recorta los opcionales con contenido', () {
      final datos = _datos(equipamiento: ' Barra ');

      expect(datos.equipamientoNormalizado, 'Barra');
    });

    // El grupo se deriva del musculo principal, asi que guardar los dos
    // permitiria estados incoherentes; la base de datos tambien lo rechaza
    // (`grupo_solo_sin_musculo_principal`).
    test('el grupo no viaja si hay musculo principal', () {
      final conPrincipal = _datos(
        grupoDeclarado: GrupoMuscular.pierna,
        musculoPrincipal: Musculo.cuadriceps,
      );
      final sinPrincipal = _datos(grupoDeclarado: GrupoMuscular.pierna);

      expect(conPrincipal.grupoNormalizado, isNull);
      expect(sinPrincipal.grupoNormalizado, GrupoMuscular.pierna);
    });

    test('los secundarios pierden duplicados y al principal', () {
      final datos = _datos(
        musculoPrincipal: Musculo.cuadriceps,
        musculosSecundarios: const [
          Musculo.gluteo,
          Musculo.gluteo,
          Musculo.cuadriceps,
        ],
      );

      expect(datos.secundariosNormalizados, [Musculo.gluteo]);
    });

    test('el JSON de escritura usa snake_case y el nombre del enum', () {
      final json = _datos(
        tipo: TipoEjercicio.cardio,
        grupoDeclarado: GrupoMuscular.pierna,
      ).aJsonDeEscritura();

      expect(json['tipo'], 'cardio');
      expect(json['grupo_muscular'], 'pierna');
      expect(json['musculo_principal'], isNull);
      expect(json['musculos_secundarios'], isEmpty);
      expect(json['video_ejemplo_url'], isNull);
      expect(json.containsKey('estado'), isFalse);
      expect(json.containsKey('id'), isFalse);
    });

    test('el JSON lleva los musculos con el valor del enum de Postgres', () {
      final json = _datos(
        musculoPrincipal: Musculo.porcionEsternoCostal,
        musculosSecundarios: const [Musculo.triceps, Musculo.deltoidesAnterior],
      ).aJsonDeEscritura();

      expect(json['musculo_principal'], 'porcion_esterno_costal');
      expect(json['musculos_secundarios'], ['triceps', 'deltoides_anterior']);
      expect(json['grupo_muscular'], isNull);
    });
  });

  group('DatosEjercicio.validar', () {
    test('devuelve el primer error, empezando por el nombre', () {
      final datos = _datos(nombre: '', descripcion: '', video: 'mal');

      expect(datos.validar()?.campo, 'nombre');
    });

    test('devuelve null con datos completos', () {
      expect(_datos(video: 'https://ejemplo.com/v').validar(), isNull);
    });

    test('rechaza el principal repetido en los secundarios', () {
      final datos = _datos(
        musculoPrincipal: Musculo.gluteo,
        musculosSecundarios: const [Musculo.gluteo],
      );

      expect(datos.validar()?.campo, 'musculos');
    });
  });

  group('TipoEjercicio', () {
    test('los nombres coinciden con el enum de Postgres', () {
      expect(TipoEjercicio.values.map((t) => t.name), [
        'fuerza',
        'cardio',
        'fortalecimiento',
      ]);
    });

    // La regla no es "Fuerza contra Cardio", es series contra minutos:
    // Fortalecimiento va por series. Esto es lo que evita que un tipo nuevo se
    // cuele como Fuerza sin que nadie lo decida.
    test('el modo de planificacion sale del tipo', () {
      expect(TipoEjercicio.fuerza.modo, ModoPlanificacion.series);
      expect(TipoEjercicio.fortalecimiento.modo, ModoPlanificacion.series);
      expect(TipoEjercicio.cardio.modo, ModoPlanificacion.minutos);

      expect(TipoEjercicio.fortalecimiento.vaPorSeries, isTrue);
      expect(TipoEjercicio.fortalecimiento.vaPorMinutos, isFalse);
    });

    test('cada tipo explica como se planifica, sin repetir texto', () {
      final descripciones = TipoEjercicio.values
          .map((t) => t.descripcionPlanificacion)
          .toSet();

      expect(descripciones, hasLength(TipoEjercicio.values.length));
    });
  });

  group('Musculo y GrupoMuscular', () {
    test('los valores coinciden con los enums de Postgres', () {
      expect(GrupoMuscular.values, hasLength(6));
      expect(Musculo.values, hasLength(21));
      expect(GrupoMuscular.pierna.valorJson, 'pierna');
      expect(
        Musculo.porcionEsternoClavicular.valorJson,
        'porcion_esterno_clavicular',
      );
    });

    test('cada musculo sabe su grupo, y el grupo sus musculos', () {
      expect(Musculo.gluteo.grupo, GrupoMuscular.pierna);
      expect(Musculo.delGrupo(GrupoMuscular.pecho), [
        Musculo.porcionEsternoClavicular,
        Musculo.porcionEsternoCostal,
      ]);
    });

    // Un valor que la app no conozca (una migracion que anada un musculo antes
    // de que se despliegue) no puede tumbar el parseo de la biblioteca entera.
    test('un valor desconocido se descarta en lugar de lanzar', () {
      expect(Musculo.porValorJson('biceps_femoral'), isNull);
      expect(const ConversorMusculos().fromJson(['gluteo', 'inventado']), [
        Musculo.gluteo,
      ]);
    });
  });

  group('Ejercicio: taxonomia', () {
    Ejercicio ejercicio({
      String id = '1',
      String nombre = 'Sentadilla',
      TipoEjercicio tipo = TipoEjercicio.fuerza,
      GrupoMuscular? grupoDeclarado,
      Musculo? musculoPrincipal,
      List<Musculo> musculosSecundarios = const [],
    }) => Ejercicio(
      id: id,
      nombre: nombre,
      descripcion: '',
      tipo: tipo,
      estado: EstadoEjercicio.activo,
      creadoEn: DateTime.utc(2026),
      grupoDeclarado: grupoDeclarado,
      musculoPrincipal: musculoPrincipal,
      musculosSecundarios: musculosSecundarios,
    );

    final sentadilla = ejercicio(
      musculoPrincipal: Musculo.cuadriceps,
      musculosSecundarios: const [Musculo.gluteo, Musculo.lumbar],
    );

    test('el grupo se deriva del musculo principal', () {
      expect(sentadilla.grupo, GrupoMuscular.pierna);
      expect(sentadilla.resumenMuscular, 'Pierna · Cuádriceps');
    });

    test('los grupos incluyen los de los secundarios', () {
      expect(sentadilla.grupos, {GrupoMuscular.pierna, GrupoMuscular.espalda});
      expect(sentadilla.trabaja(Musculo.gluteo), isTrue);
      expect(sentadilla.trabaja(Musculo.biceps), isFalse);
    });

    test('sin principal vale el grupo declarado', () {
      final cinta = ejercicio(
        id: '2',
        nombre: 'Cinta de correr',
        tipo: TipoEjercicio.cardio,
        grupoDeclarado: GrupoMuscular.pierna,
      );

      expect(cinta.grupo, GrupoMuscular.pierna);
      expect(cinta.resumenMuscular, 'Pierna');
      expect(cinta.estaClasificado, isTrue);
    });

    test('sin nada queda sin clasificar', () {
      final suelto = ejercicio(id: '3', nombre: 'Suelto');

      expect(suelto.estaClasificado, isFalse);
      expect(suelto.resumenMuscular, isNull);
    });
  });

  group('peso por lado', () {
    // Es una **etiqueta**: el peso se guarda tal cual y nunca se multiplica. Si
    // se multiplicara, el historico dejaria de ser comparable con todo lo ya
    // registrado y la grafica ensenaria un salto que nunca ocurrio.
    test('viaja en el JSON que se guarda', () {
      const datos = DatosEjercicio(
        nombre: 'Press banca',
        descripcion: 'Tumbado.',
        tipo: TipoEjercicio.fuerza,
        pesoPorLado: true,
      );

      expect(datos.aJsonDeEscritura()['peso_por_lado'], isTrue);
    });

    test('por defecto no está marcado', () {
      const datos = DatosEjercicio(
        nombre: 'Press banca',
        descripcion: 'Tumbado.',
        tipo: TipoEjercicio.fuerza,
      );

      expect(datos.pesoPorLado, isFalse);
      expect(datos.aJsonDeEscritura()['peso_por_lado'], isFalse);
    });

    test('un ejercicio de la base sin la columna no revienta', () {
      // La columna es `not null default false`, pero el modelo tampoco debe
      // depender de que venga: `fromJson` la da por falsa si falta.
      final ejercicio = Ejercicio.fromJson({
        'id': 'id-1',
        'nombre': 'Press banca',
        'descripcion': 'Tumbado.',
        'tipo': 'fuerza',
        'estado': 'activo',
        'creado_en': '2026-10-14T00:00:00.000Z',
      });

      expect(ejercicio.pesoPorLado, isFalse);
    });
  });
}
