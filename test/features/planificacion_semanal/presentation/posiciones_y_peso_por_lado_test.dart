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
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
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

/// POR QUE ESTE TEST: dos fallos vistos en produccion el 2026-10-21.
///
/// 1. Aimar quito el 6.o de 7 ejercicios de un bloque y ya no pudo anadir
///    ninguno: quitar no renumera, quedaban las posiciones 1-5 y 7, y la app
///    proponia "cuantos hay + 1" = 7, que seguia ocupada.
/// 2. En movil, la pastilla "Kg por lado" iba al lado del nombre y lo dejaba sin
///    sitio. Tiene que ir debajo; en escritorio, donde sobra, sigue al lado.
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

  /// Un bloque con las posiciones que tenia el de Aimar: 1-5 y 7.
  PlanningSemanal conHueco({bool pesoPorLado = false}) => planningDePrueba(
    sesiones: [
      sesionDePrueba(
        orden: 1,
        nombre: 'Día 1',
        bloques: [
          bloqueDePrueba(
            ejercicios: [
              for (final orden in const [1, 2, 3, 4, 5, 7])
                ejercicioPlanificadoDePrueba(
                  id: 'ep-$orden',
                  orden: orden,
                  ejercicio: ejercicioDePrueba(
                    id: 'ej-$orden',
                    nombre: 'Ejercicio $orden',
                  ).copyWith(pesoPorLado: pesoPorLado && orden == 1),
                  series: [serieDePrueba(id: 'sp-$orden')],
                ),
            ],
          ),
        ],
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(
      const DatosEjercicioPlanificado(
        bloqueId: 'b-1',
        ejercicioId: 'ej-1',
        tipoEjercicio: TipoEjercicio.fuerza,
        orden: 1,
      ),
    );
  });

  setUp(() {
    clientes = ClientesFalso();
    plannings = PlanningFalso();
    ejercicios = EjerciciosFalso();
    planning = conHueco();
    when(() => clientes.listar()).thenAnswer((_) async => Success([cliente]));
    when(() => ejercicios.listar()).thenAnswer(
      (_) async => Success([ejercicioDePrueba(id: 'ej-nuevo', nombre: 'Remo')]),
    );
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([planning]));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((_) async => Success(planning));
  });

  Future<void> montar(WidgetTester tester, {required Size tamano}) async {
    tester.view.physicalSize = tamano;
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
          referenciasDeSesionProvider(
            'p-1',
            1,
          ).overrideWith((ref) async => const {}),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: const PantallaPlanificacionEntrenador(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('con un hueco, el ejercicio nuevo va detrás del último', (
    tester,
  ) async {
    when(() => plannings.crearEjercicioPlanificado(any()))
        .thenAnswer((_) async => Success(ejercicioPlanificadoDePrueba()));

    await montar(tester, tamano: const Size(1400, 1600));
    await tester.tap(find.byKey(const Key('anadir_biblioteca_ej-nuevo')));
    await tester.pumpAndSettle();

    final datos =
        verify(() => plannings.crearEjercicioPlanificado(captureAny()))
                .captured
                .single
            as DatosEjercicioPlanificado;
    // 8 y no 7: el 7 sigue ocupado aunque solo haya 6 ejercicios.
    expect(datos.orden, 8);
  });

  group('la pastilla de kg por lado', () {
    setUp(() => planning = conHueco(pesoPorLado: true));

    testWidgets('en móvil va debajo del nombre', (tester) async {
      // Por debajo de `anchoEscritorio` (1000), pero no tan estrecho como un
      // telefono: a 400 px, con la fuente de los tests (mas ancha que la real),
      // la fila de selector de cliente y semana desborda, y eso es otro asunto
      // que ya estaba antes (bitacora del 2026-10-19).
      await montar(tester, tamano: const Size(800, 1600));

      expect(find.byKey(const Key('kg_por_lado_debajo')), findsOneWidget);
      expect(find.text('KG POR LADO'), findsOneWidget);
    });

    testWidgets('en escritorio sigue al lado', (tester) async {
      await montar(tester, tamano: const Size(1400, 1600));

      expect(find.byKey(const Key('kg_por_lado_debajo')), findsNothing);
      expect(find.text('KG POR LADO'), findsOneWidget);
    });
  });
}
