import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';

import '../../../ayudas/sesion_falsa.dart';

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

class ClientesFalso extends Mock implements ClienteRepositorio {}

/// POR QUE ESTE TEST: para ver un control pasado el entrenador tenia que buscar
/// en un calendario un dia que no sabia si tenia algo. Y, peor, en solo lectura
/// **nunca podia ver el check-in**: estaba en un segundo paso al que solo se
/// llegaba guardando. Va contra el enrutador de verdad, porque atras tiene que
/// devolverle a la lista en el mes en que estaba.
void main() {
  late ProgresoFalso progreso;
  late ClientesFalso clientes;

  RegistroMedidas medidas(DateTime fecha, {double pecho = 100}) =>
      RegistroMedidas(
        id: 'm-${fecha.month}-${fecha.day}',
        clienteId: 'c-1',
        fecha: fecha,
        pesoKg: 80,
        pechoCm: pecho,
      );

  CheckinRecuperacion checkin(DateTime fecha) => CheckinRecuperacion(
    id: 'k-${fecha.month}-${fecha.day}',
    clienteId: 'c-1',
    fecha: fecha,
    horasSueno: 7.5,
    estres: 3,
    agujetas: 4,
    fatiga: 2,
    notas: 'Semana de viaje',
  );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    progreso = ProgresoFalso();
    clientes = ClientesFalso();
  });

  /// Monta el enrutador real y va a la lista de controles del cliente.
  Future<GoRouter> montar(
    WidgetTester tester, {
    List<RegistroMedidas> conMedidas = const [],
    List<CheckinRecuperacion> conCheckins = const [],
  }) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => progreso.listarMedidas(clienteId: any(named: 'clienteId')))
        .thenAnswer((_) async => Success(conMedidas));
    when(() => progreso.listarCheckins(clienteId: any(named: 'clienteId')))
        .thenAnswer((_) async => Success(conCheckins));
    when(
      () => progreso.medidasDelDia(
        clienteId: any(named: 'clienteId'),
        fecha: any(named: 'fecha'),
      ),
    ).thenAnswer((invocacion) async {
      final fecha = invocacion.namedArguments[#fecha] as DateTime;
      return Success(conMedidas.where((m) => m.fecha == fecha).firstOrNull);
    });
    when(
      () => progreso.checkinDelDia(
        clienteId: any(named: 'clienteId'),
        fecha: any(named: 'fecha'),
      ),
    ).thenAnswer((invocacion) async {
      final fecha = invocacion.namedArguments[#fecha] as DateTime;
      return Success(conCheckins.where((c) => c.fecha == fecha).firstOrNull);
    });
    when(() => clientes.listar()).thenAnswer((_) async => const Success([]));

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          progresoRepositorioProvider.overrideWithValue(progreso),
          clienteRepositorioProvider.overrideWithValue(clientes),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    final router = contenedor.read(enrutadorProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp.router(
          theme: TemaApp.oscuro(),
          routerConfig: router,
        ),
      ),
    );
    router.go(Rutas.controlDeCliente('c-1'));
    await tester.pumpAndSettle();
    return router;
  }

  String mesActual(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('mes_actual'))).data!;

  bool activa(WidgetTester tester, String clave) =>
      tester.widget<IconButton>(find.byKey(Key(clave))).onPressed != null;

  testWidgets('abre en el mes del último control, con sus días', (
    tester,
  ) async {
    await montar(
      tester,
      conMedidas: [medidas(DateTime(2026, 10, 25))],
      conCheckins: [
        checkin(DateTime(2026, 10, 25)),
        checkin(DateTime(2026, 10, 18)),
        checkin(DateTime(2026, 9, 6)),
      ],
    );

    expect(mesActual(tester), 'Octubre de 2026');
    expect(find.byKey(const Key('control_2026-10-25')), findsOneWidget);
    expect(find.byKey(const Key('control_2026-10-18')), findsOneWidget);
    // El de septiembre no: la lista va por meses.
    expect(find.byKey(const Key('control_2026-09-06')), findsNothing);
  });

  testWidgets('se viaja de un mes a otro, hasta donde hay controles', (
    tester,
  ) async {
    await montar(
      tester,
      conCheckins: [
        checkin(DateTime(2026, 10, 18)),
        checkin(DateTime(2026, 8, 2)),
      ],
    );

    expect(activa(tester, 'mes_siguiente'), isFalse);

    // Septiembre esta entre medias y no tiene ninguno: se dice, no se salta.
    await tester.tap(find.byKey(const Key('mes_anterior')));
    await tester.pumpAndSettle();
    expect(mesActual(tester), 'Septiembre de 2026');
    expect(find.text('Ningún control este mes.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mes_anterior')));
    await tester.pumpAndSettle();
    expect(mesActual(tester), 'Agosto de 2026');
    expect(find.byKey(const Key('control_2026-08-02')), findsOneWidget);
    expect(activa(tester, 'mes_anterior'), isFalse);
    expect(activa(tester, 'mes_siguiente'), isTrue);
  });

  testWidgets('un día con solo medidas también sale, y dice lo que falta', (
    tester,
  ) async {
    await montar(tester, conMedidas: [medidas(DateTime(2026, 10, 25))]);

    expect(find.textContaining('Sin check-in'), findsOneWidget);
  });

  testWidgets('el detalle enseña las medidas y el check-in', (tester) async {
    await montar(
      tester,
      conMedidas: [medidas(DateTime(2026, 10, 18))],
      conCheckins: [checkin(DateTime(2026, 10, 18))],
    );

    await tester.tap(find.byKey(const Key('control_2026-10-18')));
    await tester.pumpAndSettle();

    expect(find.text('Domingo 18/10/2026'), findsOneWidget);
    expect(find.text('80 kg'), findsOneWidget);
    expect(find.text('100 cm'), findsOneWidget);
    // Lo que antes nunca llegaba a verse.
    expect(find.text('7.5 h'), findsOneWidget);
    expect(find.text('3 / 10'), findsOneWidget);
    expect(find.text('Semana de viaje'), findsOneWidget);
    // Solo se consulta: ni campos ni botones de guardar.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('en el detalle no salen los perímetros que no se midió', (
    tester,
  ) async {
    await montar(
      tester,
      conMedidas: [
        RegistroMedidas(
          id: 'm-1',
          clienteId: 'c-1',
          fecha: DateTime(2026, 10, 18),
          pesoKg: 80,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('control_2026-10-18')));
    await tester.pumpAndSettle();

    expect(find.text('Pecho'), findsNothing);
    expect(find.text('Ese día no hizo el check-in.'), findsOneWidget);
  });

  testWidgets('atrás desde un control vuelve a la lista, en el mismo mes', (
    tester,
  ) async {
    await montar(
      tester,
      conCheckins: [
        checkin(DateTime(2026, 10, 18)),
        checkin(DateTime(2026, 9, 6)),
      ],
    );

    await tester.tap(find.byKey(const Key('mes_anterior')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('control_2026-09-06')));
    await tester.pumpAndSettle();
    expect(find.text('Domingo 06/09/2026'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(mesActual(tester), 'Septiembre de 2026');
    expect(find.byKey(const Key('control_2026-09-06')), findsOneWidget);
  });

  testWidgets('sin ningún control, lo dice', (tester) async {
    await montar(tester);

    expect(
      find.text('Este cliente todavía no ha hecho ningún control.'),
      findsOneWidget,
    );
  });
}
