import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/widgets/tarjeta_sesion.dart';

import '../../planificacion_semanal/ayudas_planificacion.dart';

class RepositorioFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: la foto del ejercicio se anadio a la entidad, pero en la
/// planificacion seguia saliendo el hueco gris. No era que la imagen no cargara:
/// es que aquella pantalla ni siquiera pedia su URL, porque tenia su propia
/// copia del icono. Lo que se comprueba aqui es justo eso, que la pide; que el
/// `Image.network` pinte no se puede ver en un test, porque en los tests no hay
/// red (y por eso existe el `errorBuilder`).
void main() {
  late RepositorioFalso repositorio;

  Ejercicio ejercicio({String? imagenRuta}) => Ejercicio(
    id: 'ej-1',
    nombre: 'Press banca',
    descripcion: 'x',
    tipo: TipoEjercicio.fuerza,
    estado: EstadoEjercicio.activo,
    creadoEn: DateTime.utc(2026),
    imagenRuta: imagenRuta,
  );

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.urlPublicaDeImagen(any()))
        .thenReturn('http://localhost/imagen.png');
  });

  Future<void> montar(WidgetTester tester, Widget hijo) => tester.pumpWidget(
    ProviderScope(
      overrides: [ejercicioRepositorioProvider.overrideWithValue(repositorio)],
      child: MaterialApp(home: Scaffold(body: hijo)),
    ),
  );

  testWidgets('con foto, pide su URL publica', (tester) async {
    await montar(
      tester,
      MiniaturaEjercicio(ejercicio: ejercicio(imagenRuta: 'ej-1.png')),
    );

    verify(() => repositorio.urlPublicaDeImagen('ej-1.png')).called(1);
  });

  testWidgets('sin foto, ni se molesta en preguntar', (tester) async {
    await montar(tester, MiniaturaEjercicio(ejercicio: ejercicio()));

    verifyNever(() => repositorio.urlPublicaDeImagen(any()));
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });

  testWidgets('sin ficha del ejercicio tampoco se rompe', (tester) async {
    await montar(tester, const MiniaturaEjercicio(ejercicio: null));

    // Sin ficha se asume fuerza: es lo que hay en la biblioteca casi siempre.
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });

  testWidgets('la sesión planificada pinta la foto de cada ejercicio', (
    tester,
  ) async {
    final sesion = sesionDePrueba(
      bloques: [
        bloqueDePrueba(
          ejercicios: [
            ejercicioPlanificadoDePrueba(
              id: 'ep-1',
              ejercicio: ejercicio(imagenRuta: 'ej-1.png'),
            ),
          ],
        ),
      ],
    );

    await montar(
      tester,
      TarjetaSesion(
        sesion: sesion,
        planning: planningDePrueba(sesiones: [sesion]),
        puedeEditar: true,
        onAnadirBloque: () {},
        onEditarSesion: () {},
        onEliminarSesion: () {},
        onEditarBloque: (_) {},
        onEliminarBloque: (_) {},
        onAnadirEjercicio: (_) {},
        onEditarEjercicio: (_, _) {},
        onEliminarEjercicio: (_) {},
      ),
    );

    expect(find.byType(MiniaturaEjercicio), findsOneWidget);
    verify(() => repositorio.urlPublicaDeImagen('ej-1.png')).called(1);
  });
}
