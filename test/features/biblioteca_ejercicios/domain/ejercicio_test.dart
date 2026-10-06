import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

DatosEjercicio _datos({
  String nombre = 'Press banca',
  String descripcion = 'Tumbado en banco plano, baja la barra al pecho.',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
  String? grupoMuscular,
  String? equipamiento,
  String? video,
}) => DatosEjercicio(
  nombre: nombre,
  descripcion: descripcion,
  tipo: tipo,
  grupoMuscular: grupoMuscular,
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
    test('es obligatoria: la columna es not null', () {
      expect(DatosEjercicio.validarDescripcion('  ')?.campo, 'descripcion');
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
        grupoMuscular: '   ',
        equipamiento: '',
        video: '  ',
      );

      expect(datos.nombreNormalizado, 'Sentadilla');
      expect(datos.grupoMuscularNormalizado, isNull);
      expect(datos.equipamientoNormalizado, isNull);
      expect(datos.videoEjemploUrlNormalizada, isNull);
    });

    test('recorta los opcionales con contenido', () {
      final datos = _datos(grupoMuscular: '  Pecho ', equipamiento: ' Barra ');

      expect(datos.grupoMuscularNormalizado, 'Pecho');
      expect(datos.equipamientoNormalizado, 'Barra');
    });

    test('el JSON de escritura usa snake_case y el nombre del enum', () {
      final json = _datos(
        tipo: TipoEjercicio.cardio,
        grupoMuscular: 'Piernas',
      ).aJsonDeEscritura();

      expect(json['tipo'], 'cardio');
      expect(json['grupo_muscular'], 'Piernas');
      expect(json['video_ejemplo_url'], isNull);
      expect(json.containsKey('estado'), isFalse);
      expect(json.containsKey('id'), isFalse);
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
  });

  group('TipoEjercicio', () {
    test('los nombres coinciden con el enum de Postgres', () {
      expect(TipoEjercicio.values.map((t) => t.name), ['fuerza', 'cardio']);
    });

    test('fuerza y cardio se planifican distinto (regla de la fase 4)', () {
      expect(TipoEjercicio.fuerza.esFuerza, isTrue);
      expect(TipoEjercicio.fuerza.esCardio, isFalse);
      expect(
        TipoEjercicio.fuerza.descripcionPlanificacion,
        isNot(TipoEjercicio.cardio.descripcionPlanificacion),
      );
    });
  });
}
