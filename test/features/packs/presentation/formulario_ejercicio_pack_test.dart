import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/packs/data/pack_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack_repositorio.dart';
import 'package:aimar_trainer_app/features/packs/presentation/pantalla_formulario_ejercicio_pack.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../../planificacion_semanal/ayudas_planificacion.dart';

class PackFalso extends Mock implements PackRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: desde el 2026-10-27 las etiquetas del pack son solo
/// descriptivas y un pack puede mezclar tipos. Antes el formulario se abria
/// restringido al tipo del pack y decidia series o minutos por el pack; ahora
/// tiene que dejar elegir cualquier ejercicio y decidirlo por **el ejercicio**.
void main() {
  late PackFalso repositorio;
  late EjerciciosFalso ejercicios;

  // Etiquetado solo como Fuerza, para comprobar que eso no limita nada.
  final pack = Pack(
    id: 'p-1',
    nombre: 'Torso A',
    tipos: const [TipoEjercicio.fuerza],
    creadoEn: DateTime.utc(2026, 10, 27),
  );

  setUpAll(() {
    registerFallbackValue(
      const DatosPackEjercicio(
        packId: 'p-1',
        ejercicioId: 'x',
        tipo: TipoEjercicio.fuerza,
        orden: 1,
      ),
    );
  });

  setUp(() {
    repositorio = PackFalso();
    ejercicios = EjerciciosFalso();
    when(() => ejercicios.listar()).thenAnswer(
      (_) async => Success([
        ejercicioDePrueba(id: 'ej-f', nombre: 'Press banca'),
        ejercicioDePrueba(
          id: 'ej-c',
          nombre: 'Cinta',
          tipo: TipoEjercicio.cardio,
        ),
      ]),
    );
    when(
      () => repositorio.guardarEjercicio(
        datos: any(named: 'datos'),
        id: any(named: 'id'),
      ),
    ).thenAnswer((_) async => const Success('pe-nuevo'));
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          packRepositorioProvider.overrideWithValue(repositorio),
          ejercicioRepositorioProvider.overrideWithValue(ejercicios),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: PantallaFormularioEjercicioPack(pack: pack),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('se ofrecen ejercicios de cualquier tipo', (tester) async {
    await montar(tester);

    expect(find.byKey(const Key('elegir_para_pack_ej-f')), findsOneWidget);
    expect(find.byKey(const Key('elegir_para_pack_ej-c')), findsOneWidget);
  });

  testWidgets('un cardio en un pack de fuerza pide minutos y se guarda así', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('elegir_para_pack_ej-c')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo_minutos_pack')), findsOneWidget);
    expect(find.byKey(const Key('boton_anadir_serie_pack')), findsNothing);

    await tester.enterText(find.byKey(const Key('campo_minutos_pack')), '20');
    await tester.tap(find.byKey(const Key('boton_guardar_ejercicio_pack')));
    await tester.pumpAndSettle();

    final datos =
        verify(
              () => repositorio.guardarEjercicio(
                datos: captureAny(named: 'datos'),
                id: any(named: 'id'),
              ),
            ).captured.single
            as DatosPackEjercicio;
    expect(datos.tipo, TipoEjercicio.cardio);
    expect(datos.minutosNormalizados, 20);
    expect(datos.seriesNormalizadas, isEmpty);
  });

  testWidgets('cambiar a un ejercicio de fuerza vuelve a las series', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('elegir_para_pack_ej-c')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cambiar_ejercicio_pack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('elegir_para_pack_ej-f')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('boton_anadir_serie_pack')), findsOneWidget);
    expect(find.byKey(const Key('campo_minutos_pack')), findsNothing);
  });
}
