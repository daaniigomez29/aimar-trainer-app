import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/packs/data/pack_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

class PackFalso extends Mock implements PackRepositorio {}

/// POR QUE ESTE TEST: el "+" de un pack tiene que llevarlo **al bloque que se
/// elija**, igual que un ejercicio suelto; antes de preguntar, un ejercicio caía
/// siempre en el primero, que con calentamiento y fuerza nunca era lo que se
/// quería. Y tras aplicarlo hay que **recargar el planning**: el controlador de
/// packs no sabe de plannings, así que si la pantalla no lo pide, el pack entra
/// en la base de datos y no se ve.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;
  late EjerciciosFalso ejercicios;
  late PackFalso packs;
  late PlanningSemanal planning;

  final cliente = Cliente(
    id: 'c-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );

  Pack pack({String id = 'pk-1', String nombre = 'Torso A', int cuantos = 2}) =>
      Pack(
        id: id,
        nombre: nombre,
        tipos: const [TipoEjercicio.fuerza],
        creadoEn: DateTime.utc(2026, 10, 19),
        ejercicios: [
          for (var i = 1; i <= cuantos; i++)
            PackEjercicio(
              id: '$id-pe-$i',
              packId: id,
              ejercicioId: 'ej-$i',
              orden: i,
              ejercicio: ejercicioDePrueba(id: 'ej-$i', nombre: 'Ejercicio $i'),
            ),
        ],
      );

  PlanningSemanal conBloques(int cuantos) => planningDePrueba(
    sesiones: [
      sesionDePrueba(
        orden: 1,
        nombre: 'Día 1',
        bloques: [
          for (var i = 1; i <= cuantos; i++)
            bloqueDePrueba(id: 'b-$i', orden: i),
        ],
      ),
    ],
  );

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    packs = PackFalso();
    planning = conBloques(1);
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar()).thenAnswer((_) async => const Success([]));
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((_) async => Success(planning));
  });

  Future<void> montar(WidgetTester tester, {required List<Pack> lista}) async {
    // Escritorio: el panel es fijo y no hace falta abrir el modal.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => packs.listar()).thenAnswer((_) async => Success(lista));

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          clienteRepositorioProvider.overrideWithValue(clientes),
          planningRepositorioProvider.overrideWithValue(plannings),
          ejercicioRepositorioProvider.overrideWithValue(ejercicios),
          packRepositorioProvider.overrideWithValue(packs),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        // Con el tema de verdad: sin el, los fallos de ancho de los botones
        // del tema no se reproducen (pasó con la pantalla de Packs).
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: const PantallaPlanificacionEntrenador(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pestana_packs')));
    await tester.pumpAndSettle();
  }

  void aplicarDevuelve(Result<ResultadoAplicarPack> resultado) => when(
    () => packs.aplicarABloque(
      packId: any(named: 'packId'),
      bloqueId: any(named: 'bloqueId'),
    ),
  ).thenAnswer((_) async => resultado);

  IconButton botonDe(WidgetTester tester, String packId) =>
      tester.widget<IconButton>(find.byKey(Key('aplicar_pack_$packId')));

  testWidgets('la pestaña Packs enseña los packs y apaga los vacíos', (
    tester,
  ) async {
    await montar(
      tester,
      lista: [
        pack(),
        pack(id: 'pk-2', nombre: 'Vacío', cuantos: 0),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Torso A'), findsOneWidget);
    expect(find.text('2 ejercicios · Fuerza'), findsOneWidget);
    expect(find.text('Sin ejercicios'), findsOneWidget);
    expect(botonDe(tester, 'pk-1').onPressed, isNotNull);
    // La función de Postgres rechaza un pack vacío: mejor no ofrecerlo.
    expect(botonDe(tester, 'pk-2').onPressed, isNull);
  });

  testWidgets('sin packs, dice dónde se crean', (tester) async {
    await montar(tester, lista: const []);

    expect(
      find.text('Todavía no hay packs. Se crean en la pantalla de Packs.'),
      findsOneWidget,
    );
  });

  testWidgets('con un bloque, lo aplica ahí sin preguntar y recarga', (
    tester,
  ) async {
    aplicarDevuelve(
      const Success(
        ResultadoAplicarPack(ejerciciosAnadidos: 2, ejerciciosOmitidos: 0),
      ),
    );
    await montar(tester, lista: [pack()]);
    clearInteractions(plannings);

    await tester.tap(find.byKey(const Key('aplicar_pack_pk-1')));
    await tester.pumpAndSettle();

    expect(find.byType(SimpleDialog), findsNothing);
    verify(() => packs.aplicarABloque(packId: 'pk-1', bloqueId: 'b-1'))
        .called(1);
    verify(() => plannings.obtenerPlanningCompleto('p-1')).called(1);
    expect(find.text('Torso A añadido: 2 ejercicios.'), findsOneWidget);
  });

  testWidgets('con varios bloques, pregunta a cuál', (tester) async {
    planning = conBloques(2);
    aplicarDevuelve(
      const Success(
        ResultadoAplicarPack(ejerciciosAnadidos: 2, ejerciciosOmitidos: 0),
      ),
    );
    await montar(tester, lista: [pack()]);

    await tester.tap(find.byKey(const Key('aplicar_pack_pk-1')));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué bloque va Torso A?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elegir_bloque_b-2')));
    await tester.pumpAndSettle();

    verify(() => packs.aplicarABloque(packId: 'pk-1', bloqueId: 'b-2'))
        .called(1);
  });

  testWidgets('cancelar la elección no aplica nada', (tester) async {
    planning = conBloques(2);
    await montar(tester, lista: [pack()]);

    await tester.tap(find.byKey(const Key('aplicar_pack_pk-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => packs.aplicarABloque(
        packId: any(named: 'packId'),
        bloqueId: any(named: 'bloqueId'),
      ),
    );
  });

  testWidgets('sin bloques, avisa en vez de aplicar', (tester) async {
    planning = conBloques(0);
    await montar(tester, lista: [pack()]);

    await tester.tap(find.byKey(const Key('aplicar_pack_pk-1')));
    await tester.pumpAndSettle();

    expect(
      find.text('Añade antes un bloque: los ejercicios van dentro de uno.'),
      findsOneWidget,
    );
    verifyNever(
      () => packs.aplicarABloque(
        packId: any(named: 'packId'),
        bloqueId: any(named: 'bloqueId'),
      ),
    );
  });

  testWidgets('si falla, enseña el error y no recarga', (tester) async {
    aplicarDevuelve(const Failure(ErrorNoEncontrado('Ese pack ya no existe')));
    await montar(tester, lista: [pack()]);
    clearInteractions(plannings);

    await tester.tap(find.byKey(const Key('aplicar_pack_pk-1')));
    await tester.pumpAndSettle();

    expect(find.text('Ese pack ya no existe'), findsOneWidget);
    verifyNever(() => plannings.obtenerPlanningCompleto(any()));
  });

  group('el aviso tras aplicar', () {
    String aviso(int anadidos, int omitidos) => mensajeDePackAplicado(
      'Torso A',
      ResultadoAplicarPack(
        ejerciciosAnadidos: anadidos,
        ejerciciosOmitidos: omitidos,
      ),
    );

    test('dice cuántos entraron', () {
      expect(aviso(1, 0), 'Torso A añadido: 1 ejercicio.');
    });

    // Si no se dice, el bloque sale con menos ejercicios que el pack y no hay
    // forma de saber por qué.
    test('dice cuántos se quedaron fuera por estar de baja', () {
      expect(
        aviso(2, 1),
        'Torso A añadido: 2 ejercicios. '
        'Uno se ha quedado fuera porque está dado de baja.',
      );
      expect(
        aviso(1, 3),
        'Torso A añadido: 1 ejercicio. '
        '3 se han quedado fuera porque están dados de baja.',
      );
    });

    test('si no entró ninguno, no dice "añadido"', () {
      expect(
        aviso(0, 2),
        'No se ha añadido nada de Torso A: todos sus ejercicios están '
        'dados de baja.',
      );
    });
  });
}
