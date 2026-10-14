import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/semana.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mi_planning.dart';

import '../ayudas_planificacion.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class PlanningsFalso extends Mock implements PlanningRepositorio {}

class ClientesFalso extends Mock implements ClienteRepositorio {}

/// El cliente también navega por semanas, no solo el entrenador: antes solo veía
/// la de hoy y el histórico quedaba en otra pantalla.
void main() {
  late AutenticacionFalsa autenticacion;
  late PlanningsFalso plannings;
  late ClientesFalso clientes;

  final estaSemana = Semana.deHoy();

  setUp(() {
    autenticacion = AutenticacionFalsa();
    plannings = PlanningsFalso();
    clientes = ClientesFalso();

    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn('cli-1');
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(
          id: 'cli-1',
          rol: RolUsuario.cliente,
          creadoEn: DateTime.utc(2026),
        ),
      ),
    );
    when(() => clientes.obtenerPorId(any())).thenAnswer(
      (_) async => Success(
        Cliente(
          id: 'cli-1',
          nombre: 'Ana Demo',
          correo: 'ana@local.test',
          diaControlPreferido: DiaSemana.domingo,
          estado: EstadoCliente.activo,
          fechaAlta: DateTime.utc(2026),
        ),
      ),
    );
    when(() => clientes.listar()).thenAnswer((_) async => const Success([]));
    // Sin eventos de realtime: lo que se prueba aquí es la navegación.
    when(() => plannings.cambiosEnPlanningsDeCliente(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  /// Un planning con una sesión, para que la semana tenga algo que enseñar.
  PlanningSemanal deLaSemana(Semana semana, {required String id}) =>
      planningDePrueba(
        id: id,
        fechaInicio: semana.lunes,
        nombreObjetivo: 'Objetivo $id',
        // El nombre de la sesion es lo que identifica a cada planning en
        // pantalla: el objetivo no se pinta en la vista del cliente.
        sesiones: [sesionDePrueba(planningId: id, nombre: 'Sesion de $id')],
      );

  Future<void> montar(
    WidgetTester tester, {
    required List<PlanningSemanal> lista,
  }) async {
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success(lista));
    when(() => plannings.obtenerPlanningCompleto(any()))
        .thenAnswer((invocacion) async {
          final id = invocacion.positionalArguments.first as String;
          final encontrado = lista.where((p) => p.id == id).firstOrNull;
          return encontrado == null
              ? const Failure(ErrorNoEncontrado())
              : Success(encontrado);
        });

    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        planningRepositorioProvider.overrideWithValue(plannings),
        clienteRepositorioProvider.overrideWithValue(clientes),
      ],
    );
    addTearDown(contenedor.dispose);
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaMiPlanning()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('entra por la semana de hoy', (tester) async {
    await montar(tester, lista: [deLaSemana(estaSemana, id: 'p-hoy')]);

    expect(find.text('Semana del ${estaSemana.etiqueta}'), findsOneWidget);
  });

  testWidgets('la flecha de atrás lleva al planning de la semana anterior', (
    tester,
  ) async {
    final anterior = estaSemana.anterior;
    await montar(
      tester,
      lista: [
        deLaSemana(estaSemana, id: 'p-hoy'),
        deLaSemana(anterior, id: 'p-anterior'),
      ],
    );

    await tester.tap(find.byKey(const Key('semana_anterior')));
    await tester.pumpAndSettle();

    expect(find.text('Semana del ${anterior.etiqueta}'), findsOneWidget);
    expect(find.text('Sesion de p-anterior'), findsOneWidget);
  });

  testWidgets('una semana sin planning lo dice y deja volver', (tester) async {
    await montar(tester, lista: [deLaSemana(estaSemana, id: 'p-hoy')]);

    await tester.tap(find.byKey(const Key('semana_siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Semana sin planning'), findsOneWidget);

    // La clave: el navegador sigue ahí, así que no es un callejón sin salida.
    await tester.tap(find.byKey(const Key('semana_anterior')));
    await tester.pumpAndSettle();

    expect(find.text('Semana del ${estaSemana.etiqueta}'), findsOneWidget);
    expect(find.text('Sesion de p-hoy'), findsOneWidget);
  });

  testWidgets('sin ningún planning, no habla de una semana concreta', (
    tester,
  ) async {
    await montar(tester, lista: const []);

    expect(find.text('Todavía no tienes ninguna semana'), findsOneWidget);
  });

  // El fallo: el cliente abria la app y aparecia en la semana que viene, porque
  // sin planning de hoy se cogia el mas reciente de la lista, que llega
  // ordenada de mas nueva a mas vieja.
  testWidgets('con la semana que viene ya montada, se entra por la de hoy', (
    tester,
  ) async {
    final siguiente = estaSemana.siguiente;
    await montar(tester, lista: [deLaSemana(siguiente, id: 'p-siguiente')]);

    expect(find.text('Semana del ${estaSemana.etiqueta}'), findsOneWidget);
    expect(find.text('Semana sin planning'), findsOneWidget);
    expect(find.text('Sesion de p-siguiente'), findsNothing);
  });

  testWidgets('tampoco se cuela la semana pasada', (tester) async {
    await montar(
      tester,
      lista: [deLaSemana(estaSemana.anterior, id: 'p-ayer')],
    );

    expect(find.text('Semana del ${estaSemana.etiqueta}'), findsOneWidget);
    expect(find.text('Semana sin planning'), findsOneWidget);
  });

  testWidgets('y la que viene sigue estando a una flecha', (tester) async {
    final siguiente = estaSemana.siguiente;
    await montar(tester, lista: [deLaSemana(siguiente, id: 'p-siguiente')]);

    await tester.tap(find.byKey(const Key('semana_siguiente')));
    await tester.pumpAndSettle();

    expect(find.text('Sesion de p-siguiente'), findsOneWidget);
  });

  group('el botón del día dice por dónde va', () {
    /// Una semana con un dia de dos ejercicios, registrados los que se diga.
    PlanningSemanal conRegistrados(int cuantos) => planningDePrueba(
      id: 'p-hoy',
      fechaInicio: estaSemana.lunes,
      sesiones: [
        sesionDePrueba(
          planningId: 'p-hoy',
          nombre: 'Sesion de hoy',
          bloques: [
            bloqueDePrueba(
              ejercicios: [
                for (var i = 1; i <= 2; i++)
                  ejercicioPlanificadoDePrueba(
                    id: 'ep-$i',
                    orden: i,
                    estadoRegistro: i <= cuantos
                        ? EstadoRegistro.registrado
                        : EstadoRegistro.pendiente,
                  ),
              ],
            ),
          ],
        ),
      ],
    );

    /// El boton esta al final de la pantalla: con el alto por defecto no se
    /// construye y los finders dirian que no existe.
    Future<void> montarEntero(WidgetTester tester, PlanningSemanal semana) {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return montar(tester, lista: [semana]);
    }

    // "Continuar" en un dia que no ha empezado era mentira, y de las que
    // desaniman: parece que te has dejado algo a medias sin haber tocado nada.
    testWidgets('sin nada registrado, invita a comenzar', (tester) async {
      await montarEntero(tester, conRegistrados(0));

      expect(find.text('Comenzar entrenamiento'), findsOneWidget);
    });

    testWidgets('con algo registrado, invita a continuar', (tester) async {
      await montarEntero(tester, conRegistrados(1));

      expect(find.text('Continuar entrenamiento'), findsOneWidget);
    });

    testWidgets('con todo registrado, ofrece repasar', (tester) async {
      await montarEntero(tester, conRegistrados(2));

      expect(find.text('Revisar la sesión'), findsOneWidget);
    });
  });

  // El entrenamiento se piensa por bloques —calentar, luego fuerza— y de
  // corrido era una lista plana en la que no se veía dónde acababa uno.
  testWidgets('el día del cliente va separado por bloques', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await montar(
      tester,
      lista: [
        planningDePrueba(
          id: 'p-hoy',
          fechaInicio: estaSemana.lunes,
          sesiones: [
            sesionDePrueba(
              planningId: 'p-hoy',
              nombre: 'Sesion de hoy',
              bloques: [
                bloqueDePrueba(
                  id: 'b-1',
                  orden: 1,
                  tipo: TipoBloque.calentamiento,
                  notas: 'Sin prisa.',
                  ejercicios: [ejercicioPlanificadoDePrueba(id: 'ep-1')],
                ),
                bloqueDePrueba(
                  id: 'b-2',
                  orden: 2,
                  ejercicios: [
                    ejercicioPlanificadoDePrueba(id: 'ep-2', bloqueId: 'b-2'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(find.text('BLOQUE 1 · CALENTAMIENTO'), findsOneWidget);
    expect(find.text('BLOQUE 2 · FUERZA'), findsOneWidget);
    // La nota del bloque deja de estar escondida dentro de cada ejercicio.
    expect(find.text('Sin prisa.'), findsOneWidget);
  });
}
