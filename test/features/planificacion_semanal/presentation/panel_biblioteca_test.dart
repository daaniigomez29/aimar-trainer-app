import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_planificacion_entrenador.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../ayudas_planificacion.dart';

class ClientesFalso extends Mock implements ClienteRepositorio {}

class PlanningFalso extends Mock implements PlanningRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: el panel de biblioteca tenía el filtro y la lista en un
/// `Column`, y el filtro crece al abrir grupos. Con dos abiertos ya no cabía y
/// la pantalla salía con el rayado de "BOTTOM OVERFLOWED BY 14 PIXELS". Es un
/// fallo de reparto de alto, así que solo se ve con un viewport estrecho: por
/// eso el test fija uno pequeño a propósito.
void main() {
  late ClientesFalso clientes;
  late PlanningFalso plannings;
  late EjerciciosFalso ejercicios;
  late PlanningSemanal planning;

  final cliente = Cliente(
    id: 'c-1',
    nombre: 'Cliente de prueba',
    correo: 'cliente@local.test',
    diaControlPreferido: DiaSemana.domingo,
    estado: EstadoCliente.activo,
    fechaAlta: DateTime.utc(2026),
  );

  /// Uno por grupo, para que el filtro tenga los seis que ensanchan el panel.
  List<Ejercicio> bibliotecaCompleta() => [
    for (final (indice, musculo) in const [
      Musculo.cuadriceps,
      Musculo.porcionEsternoCostal,
      Musculo.dorsalAncho,
      Musculo.deltoidesLateral,
      Musculo.biceps,
      Musculo.oblicuos,
    ].indexed)
      ejercicioDePrueba(
        id: 'ej-$indice',
        nombre: 'Ejercicio $indice',
      ).copyWith(musculoPrincipal: musculo),
  ];

  setUpAll(() {
    registerFallbackValue(
      const DatosSesion(planningId: 'p-1', orden: 1, nombre: 'x'),
    );
  });

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar())
        .thenAnswer((_) async => Success(bibliotecaCompleta()));
    // Con planning en la semana en curso: asi se pinta el editor y, con el, el
    // panel lateral. Sin el, la pantalla ensena el boton de crear la semana, y
    // ese desborda a lo ancho por la fuente de los tests (mas ancha que la
    // real), que no es lo que se quiere medir aqui.
    //
    // Mutable: al crear una sesion el controlador invalida el planning y la
    // pantalla lo vuelve a pedir, asi que la segunda lectura tiene que traer
    // ya la sesion nueva, como haria la base de datos.
    planning = planningDePrueba(
      sesiones: [sesionDePrueba(orden: 1, nombre: 'Día 1')],
    );
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((_) async => Success(planning));
  });

  Future<void> montar(WidgetTester tester) async {
    // Estrecho y bajo: escritorio (para que el panel sea fijo, no modal) pero
    // sin alto de sobra, que es donde el reparto se rompía.
    tester.view.physicalSize = const Size(1400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          clienteRepositorioProvider.overrideWithValue(clientes),
          planningRepositorioProvider.overrideWithValue(plannings),
          ejercicioRepositorioProvider.overrideWithValue(ejercicios),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaPlanificacionEntrenador()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('abrir dos grupos del filtro no desborda el panel', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('filtro_muscular')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const PageStorageKey('grupo_plegable_pecho')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const PageStorageKey('grupo_plegable_espalda')),
    );
    await tester.pumpAndSettle();

    // Un `RenderFlex overflowed` llega aquí como excepción del test.
    expect(tester.takeException(), isNull);
  });

  // El entrenador añade el Día 2 porque va a montarlo, no para seguir mirando
  // el Día 1. Antes se quedaba donde estaba y había que buscar la pestaña.
  testWidgets('crear un día abre ese día', (tester) async {
    final creada = sesionDePrueba(id: 's-2', orden: 2, nombre: 'Día 2');
    when(() => plannings.crearSesion(any()))
        .thenAnswer((_) async => Success(creada));

    await montar(tester);
    expect(find.text('Día 1 · Día 1'), findsOneWidget);

    // A partir de aquí el planning ya tiene las dos sesiones.
    planning = planningDePrueba(
      sesiones: [
        sesionDePrueba(orden: 1, nombre: 'Día 1'),
        creada,
      ],
    );

    await tester.tap(find.byKey(const Key('boton_anadir_sesion')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campo_nombre_sesion')),
      'Día 2',
    );
    await tester.tap(find.byKey(const Key('boton_guardar_sesion')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Día 2 · Día 2'), findsOneWidget);
  });
}
