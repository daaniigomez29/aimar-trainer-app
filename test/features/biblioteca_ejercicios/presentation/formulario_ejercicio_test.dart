import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_formulario_ejercicio.dart';

import '../../../ayudas/sesion_falsa.dart';

class RepositorioFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: el formulario no tenia ninguno, y con el tema nuevo la
/// pantalla se quedaba **en negro** al abrirlo. La causa era de layout, no de
/// datos: el tema ponia `minimumSize: Size.fromHeight(48)` a los
/// `OutlinedButton`, que es ancho **infinito**, y el boton de elegir imagen vive
/// dentro de una `Row`. Un test que solo monte la pantalla lo habria cazado.
void main() {
  late RepositorioFalso repositorio;

  Ejercicio ejercicio({
    String? imagenRuta,
    String? video,
    List<Musculo> secundarios = const [],
  }) => Ejercicio(
    id: 'id-1',
    nombre: 'Press banca',
    descripcion: 'Tumbado en banco plano.',
    tipo: TipoEjercicio.fuerza,
    estado: EstadoEjercicio.activo,
    creadoEn: DateTime.utc(2026),
    musculoPrincipal: Musculo.porcionEsternoCostal,
    musculosSecundarios: secundarios,
    imagenRuta: imagenRuta,
    videoEjemploUrl: video,
  );

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.listar())
        .thenAnswer((_) async => const Success(<Ejercicio>[]));
    when(() => repositorio.urlPublicaDeImagen(any()))
        .thenReturn('http://localhost/imagen.png');
  });

  Future<void> montar(WidgetTester tester, {Ejercicio? aEditar}) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Con sesion: la pantalla lleva barra de navegacion y necesita el rol.
    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          ejercicioRepositorioProvider.overrideWithValue(repositorio),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: PantallaFormularioEjercicio(ejercicio: aEditar),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el formulario de alta se pinta', (tester) async {
    await montar(tester);

    expect(find.text('Nuevo ejercicio'), findsOneWidget);
    expect(find.byKey(const Key('boton_elegir_imagen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el formulario de edicion se pinta con sus datos', (
    tester,
  ) async {
    await montar(tester, aEditar: ejercicio());

    expect(find.text('Editar ejercicio'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Press banca'), findsOneWidget);
    // La clasificacion muscular ya no es texto libre: se precarga en los dos
    // desplegables, y el grupo sale del musculo principal.
    expect(find.text('Pecho'), findsWidgets);
    expect(find.text('Porción esterno-costal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // Los 21 musculos repartidos en seis grupos alargaban el formulario aunque
  // no se fuera a poner ningun secundario, que es el caso mas comun.
  testWidgets('los músculos secundarios nacen plegados', (tester) async {
    await montar(tester);

    expect(find.byKey(const Key('secundarios')), findsOneWidget);
    // Ni los grupos ni sus musculos estan a la vista.
    expect(find.text('Pierna'), findsNothing);
    expect(find.text('Cuádriceps'), findsNothing);

    await tester.tap(find.text('Músculos secundarios'));
    await tester.pumpAndSettle();

    expect(find.text('Pierna'), findsOneWidget);
  });

  testWidgets('al editar uno que ya tiene secundarios, se abre solo', (
    tester,
  ) async {
    await montar(
      tester,
      aEditar: ejercicio(secundarios: const [Musculo.triceps]),
    );

    expect(find.text('Brazo'), findsOneWidget);
    expect(find.textContaining('Tríceps'), findsWidgets);
  });

  testWidgets('un ejercicio con imagen ofrece cambiarla y quitarla', (
    tester,
  ) async {
    await montar(tester, aEditar: ejercicio(imagenRuta: '123.png'));

    expect(find.text('Cambiar imagen'), findsOneWidget);
    expect(find.byKey(const Key('boton_quitar_imagen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin imagen no ofrece quitar nada', (tester) async {
    await montar(tester, aEditar: ejercicio());

    expect(find.text('Elegir imagen'), findsOneWidget);
    expect(find.byKey(const Key('boton_quitar_imagen')), findsNothing);
  });
}
