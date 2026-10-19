import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/data/progreso_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_ejercicio.dart';

import '../../../ayudas/sesion_falsa.dart';

import '../../../ayudas/app_con_rutas.dart';
import '../../planificacion_semanal/ayudas_planificacion.dart';

class ProgresoFalso extends Mock implements ProgresoRepositorio {}

class _DatosFalsos extends Fake implements DatosResultadoEjercicio {}

void main() {
  late ProgresoFalso repositorio;

  setUpAll(() {
    registerFallbackValue(_DatosFalsos());
    registerFallbackValue(
      RangoFechas(desde: DateTime(2026), hasta: DateTime(2026)),
    );
  });

  setUp(() {
    repositorio = ProgresoFalso();
    when(() => repositorio.registrarResultado(any()))
        .thenAnswer((_) async => const Success(null));
    when(
      () => repositorio.progresoDeEjercicio(
        clienteId: any(named: 'clienteId'),
        ejercicioId: any(named: 'ejercicioId'),
        rango: any(named: 'rango'),
      ),
    ).thenAnswer((_) async => const Success(<RegistroProgreso>[]));
  });

  Future<void> montar(
    WidgetTester tester,
    EjercicioPlanificado ejercicio, {
    String rutaInicial = '/registro',
    SesionEntrenamiento? sesion,
  }) async {
    // La pantalla muestra todas las series a la vez: con los 600 px por defecto
    // no caben y los finders no las encontrarian.
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Con sesion de cliente: la pantalla lleva su barra de navegacion.
    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(rol: RolUsuario.cliente),
          ),
          progresoRepositorioProvider.overrideWithValue(repositorio),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        // Con rutas de verdad: al terminar el ultimo ejercicio la pantalla
        // navega al planning del cliente, y eso necesita un GoRouter.
        child: appConRutas(
          rutaInicial: rutaInicial,
          tema: TemaApp.oscuro(),
          rutas: [
            GoRoute(
              path: Rutas.inicioCliente,
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    const Text('mi planning'),
                    Text(
                      'dia=${state.uri.queryParameters[Rutas.paramDia] ?? '-'}',
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/registro',
              builder: (context, state) => PantallaRegistroEjercicio(
                ejercicio: ejercicio,
                planningId: 'p-1',
                clienteId: 'cli-1',
                sesion: sesion,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  EjercicioPlanificado deFuerza({List<SerieRealizada> realizadas = const []}) =>
      ejercicioPlanificadoDePrueba(
        ejercicio: ejercicioDePrueba(),
        series: [
          serieDePrueba(numeroSerie: 1, repeticiones: 10, peso: 60),
          serieDePrueba(id: 'sp-2', numeroSerie: 2, repeticiones: 8, peso: 65),
        ],
      ).copyWith(seriesRealizadas: realizadas);

  DatosResultadoEjercicio ultimoEnviado() =>
      verify(() => repositorio.registrarResultado(captureAny())).captured.last
          as DatosResultadoEjercicio;

  testWidgets('cada serie llega con lo planificado puesto', (tester) async {
    await montar(tester, deFuerza());

    // Serie 1: 60 kg x 10. Serie 2: 65 kg x 8.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('peso_serie_1')))
          .controller
          ?.text,
      '60',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('reps_serie_2')))
          .controller
          ?.text,
      '8',
    );
  });

  testWidgets('confirmar una serie la registra', (tester) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('confirmar_serie_1')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.series.length, 1);
    expect(enviado.series.single.numeroSerie, 1);
    expect(enviado.series.single.repeticiones, 10);
    expect(enviado.minutos, isNull);
  });

  testWidgets('la segunda confirmación reenvia también la primera serie', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('confirmar_serie_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar_serie_2')));
    await tester.pumpAndSettle();

    expect(ultimoEnviado().series.map((s) => s.numeroSerie).toList(), [1, 2]);
  });

  testWidgets('se puede añadir y registrar una serie de mas', (tester) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_serie_extra')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirmar_serie_3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmar_serie_3')));
    await tester.pumpAndSettle();

    expect(ultimoEnviado().series.single.numeroSerie, 3);
  });

  // Pulsar "Añadir una serie de más" sin querer tiene que poder deshacerse.
  testWidgets('la serie de más se puede quitar mientras no esté confirmada', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    // Las planificadas no se pueden quitar: las pone el entrenador.
    expect(find.byKey(const Key('quitar_serie_1')), findsNothing);
    expect(find.byKey(const Key('quitar_serie_2')), findsNothing);

    await tester.tap(find.byKey(const Key('boton_serie_extra')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quitar_serie_3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quitar_serie_3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirmar_serie_3')), findsNothing);
    verifyNever(() => repositorio.registrarResultado(any()));
  });

  // Una vez registrada ya no: `series_realizadas` no tiene `delete`, asi que
  // ofrecerlo seria prometer algo que la base de datos no deja hacer.
  testWidgets('una serie de más ya confirmada no se puede quitar', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_serie_extra')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar_serie_3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quitar_serie_3')), findsNothing);
  });

  // El check verde no puede ser la unica forma de guardar: el cliente rellena,
  // pulsa el boton de abajo y da por hecho que con eso vale.
  testWidgets('"Guardar y siguiente" guarda lo escrito sin pulsar el check', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.enterText(find.byKey(const Key('reps_serie_1')), '12');
    await tester.enterText(find.byKey(const Key('peso_serie_1')), '62.5');
    await tester.tap(find.byKey(const Key('boton_siguiente_ejercicio')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.series.map((s) => s.numeroSerie).toList(), [1, 2]);
    expect(enviado.series.first.repeticiones, 12);
    expect(enviado.series.first.peso, 62.5);
  });

  testWidgets('sin nada escrito no guarda nada y pasa de largo', (
    tester,
  ) async {
    await montar(
      tester,
      ejercicioPlanificadoDePrueba(
        ejercicio: ejercicioDePrueba(),
        series: [serieDePrueba(numeroSerie: 1, repeticiones: 10)],
      ).copyWith(seriesRealizadas: const []),
    );

    // La serie planificada precarga sus repeticiones, asi que para que no haya
    // nada que guardar hay que vaciarlas: es el caso de saltarse el ejercicio.
    await tester.enterText(find.byKey(const Key('reps_serie_1')), '');
    await tester.tap(find.byKey(const Key('boton_siguiente_ejercicio')));
    await tester.pumpAndSettle();

    verifyNever(() => repositorio.registrarResultado(any()));
  });

  /// Monta la pantalla dejando que el ejercicio **cambie sin cambiar el sitio
  /// del arbol**, que es justo lo que hace `context.go` al encadenar
  /// ejercicios: Flutter reutiliza el `State` de la pantalla.
  ///
  /// A proposito **sin `key`**: el enrutador le pone una por ejercicio, pero lo
  /// que se quiere comprobar aqui es que la pantalla es correcta por si misma.
  Future<ValueNotifier<EjercicioPlanificado>> montarEncadenado(
    WidgetTester tester,
    EjercicioPlanificado primero,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final actual = ValueNotifier<EjercicioPlanificado>(primero);
    addTearDown(actual.dispose);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(rol: RolUsuario.cliente),
          ),
          progresoRepositorioProvider.overrideWithValue(repositorio),
        ],
      ),
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: appConRutas(
          rutaInicial: '/registro',
          tema: TemaApp.oscuro(),
          rutas: [
            GoRoute(
              path: Rutas.inicioCliente,
              builder: (context, state) =>
                  const Scaffold(body: Text('mi planning')),
            ),
            GoRoute(
              path: '/registro',
              builder: (context, state) =>
                  ValueListenableBuilder<EjercicioPlanificado>(
                    valueListenable: actual,
                    builder: (context, ejercicio, _) =>
                        PantallaRegistroEjercicio(
                          ejercicio: ejercicio,
                          planningId: 'p-1',
                          clienteId: 'cli-1',
                        ),
                  ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return actual;
  }

  // El fallo que se veia: el siguiente ejercicio salia con las series del
  // anterior y el plan del nuevo, una mezcla de los dos.
  testWidgets('al encadenar, el siguiente ejercicio no hereda las series', (
    tester,
  ) async {
    final actual = await montarEncadenado(tester, deFuerza());
    expect(find.byKey(const Key('reps_serie_2')), findsOneWidget);

    actual.value = ejercicioPlanificadoDePrueba(
      id: 'ep-2',
      ejercicio: ejercicioDePrueba(id: 'ej-2', nombre: 'Press militar'),
      series: [serieDePrueba(numeroSerie: 1, repeticiones: 9)],
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('reps_serie_1')), findsOneWidget);
    expect(find.byKey(const Key('reps_serie_2')), findsNothing);
    // Y con lo planificado del nuevo, no con lo tecleado en el anterior.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('reps_serie_1')))
          .controller
          ?.text,
      '9',
    );
  });

  // El caso que rompia la pantalla: un cardio no crea ninguna serie, asi que
  // al pasar al siguiente la pantalla pedia una que no existia y saltaba
  // "Unexpected null value" encima del entrenamiento.
  testWidgets('de un cardio al siguiente ejercicio no revienta', (
    tester,
  ) async {
    final actual = await montarEncadenado(
      tester,
      ejercicioPlanificadoDePrueba(
        id: 'ep-cardio',
        ejercicio: ejercicioDePrueba(
          id: 'ej-cardio',
          nombre: 'Remo ergómetro',
          tipo: TipoEjercicio.cardio,
        ),
        minutosPlanificados: 20,
      ),
    );
    expect(find.byKey(const Key('campo_minutos')), findsOneWidget);

    actual.value = deFuerza();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('campo_minutos')), findsNothing);
    expect(find.byKey(const Key('reps_serie_1')), findsOneWidget);
    expect(find.byKey(const Key('reps_serie_2')), findsOneWidget);
  });

  testWidgets('lo ya registrado se carga para poder corregirlo', (
    tester,
  ) async {
    await montar(
      tester,
      deFuerza(
        realizadas: [
          SerieRealizada(
            id: 'sr-1',
            ejercicioPlanificadoId: 'ep-1',
            numeroSerie: 1,
            repeticionesRealizadas: 7,
            pesoReal: 55,
            fechaHoraRegistro: DateTime(2026, 10, 3),
          ),
        ],
      ),
    );

    // La serie 1 llega con lo registrado, no con lo planificado.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('reps_serie_1')))
          .controller
          ?.text,
      '7',
    );

    await tester.tap(find.byKey(const Key('confirmar_serie_2')));
    await tester.pumpAndSettle();

    // Y al guardar, la serie 1 viaja con lo que ya tenia: no se pierde.
    final enviado = ultimoEnviado();
    expect(enviado.series.first.repeticiones, 7);
    expect(enviado.series.first.peso, 55);
  });

  testWidgets('un Cardio registra minutos y ninguna serie', (tester) async {
    final cardio = ejercicioPlanificadoDePrueba(
      ejercicio: ejercicioDePrueba(
        id: 'ej-cardio',
        nombre: 'Cinta',
        tipo: TipoEjercicio.cardio,
      ),
      minutosPlanificados: 30,
    );
    await montar(tester, cardio);

    expect(find.byKey(const Key('confirmar_serie_1')), findsNothing);
    await tester.tap(find.byKey(const Key('boton_guardar_cardio')));
    await tester.pumpAndSettle();

    final enviado = ultimoEnviado();
    expect(enviado.esCardio, isTrue);
    expect(enviado.minutos, 30);
    expect(enviado.series, isEmpty);
  });

  // Al acabar el ultimo ejercicio el cliente quiere ver como queda su semana,
  // no volver a la lista de lo que acaba de terminar.
  testWidgets('terminar el último ejercicio devuelve al planning', (
    tester,
  ) async {
    await montar(tester, deFuerza());

    await tester.tap(find.byKey(const Key('boton_siguiente_ejercicio')));
    await tester.pumpAndSettle();

    expect(find.text('mi planning'), findsOneWidget);
  });

  // El fallo: al terminar, el inicio abre por la primera sesion sin terminar,
  // que a esas alturas es la SIGUIENTE. Al cliente le desaparecia de la vista
  // el dia que acababa de hacer y se encontraba el de despues.
  testWidgets('terminar deja al cliente en el día que acaba de hacer', (
    tester,
  ) async {
    final ejercicio = deFuerza();
    await montar(
      tester,
      ejercicio,
      sesion: sesionDePrueba(
        orden: 2,
        nombre: 'Día 2',
        bloques: [
          bloqueDePrueba(ejercicios: [ejercicio]),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('boton_siguiente_ejercicio')));
    await tester.pumpAndSettle();

    expect(find.text('mi planning'), findsOneWidget);
    expect(find.text('dia=2'), findsOneWidget);
  });

  // El fallo: entrando al ejercicio desde el inicio del cliente, la flecha de
  // atras llevaba a la pantalla de registrar sesion, que es el padre de la ruta
  // pero no el sitio del que venia.
  testWidgets('la flecha de atrás vuelve de donde se vino', (tester) async {
    await montar(
      tester,
      deFuerza(),
      rutaInicial: '/registro?${Rutas.paramVolver}=${Rutas.inicioCliente}',
    );

    await tester.tap(find.byKey(const Key('boton_atras')));
    await tester.pumpAndSettle();

    expect(find.text('mi planning'), findsOneWidget);
  });

  group('el check se apaga al corregir', () {
    /// El check es un `Material` verde alrededor del boton: es lo que ve el
    /// cliente, asi que es lo que se mira.
    bool confirmada(WidgetTester tester, int numero) =>
        tester
            .widget<Material>(
              find
                  .ancestor(
                    of: find.byKey(Key('confirmar_serie_$numero')),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color ==
        Tokens.exito;

    // El fallo: confirmaba, corregia el peso y el check seguia verde. La
    // pantalla decia que lo que se ve es lo que esta guardado, y ya no lo era.
    testWidgets('tocar una serie confirmada la desmarca', (tester) async {
      await montar(tester, deFuerza());
      await tester.tap(find.byKey(const Key('confirmar_serie_1')));
      await tester.pumpAndSettle();
      expect(confirmada(tester, 1), isTrue);

      await tester.enterText(find.byKey(const Key('peso_serie_1')), '65');
      await tester.pumpAndSettle();

      expect(confirmada(tester, 1), isFalse);
    });

    testWidgets('solo se desmarca la que se toca', (tester) async {
      await montar(tester, deFuerza());
      await tester.tap(find.byKey(const Key('confirmar_serie_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar_serie_2')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reps_serie_2')), '12');
      await tester.pumpAndSettle();

      expect(confirmada(tester, 1), isTrue);
      expect(confirmada(tester, 2), isFalse);
    });

    testWidgets('al volver a confirmar se envía el valor corregido', (
      tester,
    ) async {
      await montar(tester, deFuerza());
      await tester.tap(find.byKey(const Key('confirmar_serie_1')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reps_serie_1')), '7');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar_serie_1')));
      await tester.pumpAndSettle();

      expect(confirmada(tester, 1), isTrue);
      expect(ultimoEnviado().series.single.repeticiones, 7);
    });

    // Una serie de mas ya registrada no se puede quitar aunque se le apague el
    // check: `series_realizadas` no tiene `delete`, asi que quitarla de la
    // pantalla la dejaria guardada y sin verse.
    testWidgets('una serie de más ya guardada no se puede quitar', (
      tester,
    ) async {
      await montar(tester, deFuerza());
      await tester.tap(find.byKey(const Key('boton_serie_extra')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reps_serie_3')), '6');
      await tester.tap(find.byKey(const Key('confirmar_serie_3')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reps_serie_3')), '5');
      await tester.pumpAndSettle();

      expect(confirmada(tester, 3), isFalse);
      expect(find.byKey(const Key('quitar_serie_3')), findsNothing);
    });
  });

  group('el botón anuncia el bloque que empieza', () {
    /// Dos bloques, un ejercicio cada uno: el primero cierra su bloque.
    SesionEntrenamiento conDosBloques() => sesionDePrueba(
      bloques: [
        bloqueDePrueba(
          id: 'b-1',
          orden: 1,
          tipo: TipoBloque.calentamiento,
          ejercicios: [deFuerza()],
        ),
        bloqueDePrueba(
          id: 'b-2',
          orden: 2,
          ejercicios: [
            ejercicioPlanificadoDePrueba(id: 'ep-2', bloqueId: 'b-2'),
          ],
        ),
      ],
    );

    testWidgets('al cerrar un bloque, lo dice', (tester) async {
      await montar(tester, deFuerza(), sesion: conDosBloques());

      expect(find.text('Guardar y comenzar el bloque Fuerza'), findsOneWidget);
    });

    testWidgets('dentro del mismo bloque, el texto de siempre', (tester) async {
      final primero = deFuerza();
      await montar(
        tester,
        primero,
        sesion: sesionDePrueba(
          bloques: [
            bloqueDePrueba(
              ejercicios: [
                primero,
                ejercicioPlanificadoDePrueba(id: 'ep-2'),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Guardar y siguiente ejercicio'), findsOneWidget);
    });

    testWidgets('en el último ejercicio del día, termina', (tester) async {
      final unico = deFuerza();
      await montar(
        tester,
        unico,
        sesion: sesionDePrueba(
          bloques: [
            bloqueDePrueba(ejercicios: [unico]),
          ],
        ),
      );

      expect(find.text('Terminar ejercicio'), findsOneWidget);
    });
  });

  group('el encabezado', () {
    EjercicioPlanificado conFicha({
      String descripcion = 'Espalda pegada al banco y bajar controlado.',
      String? video = 'https://www.youtube.com/watch?v=abc123',
    }) => deFuerza().copyWith(
      ejercicio: ejercicioDePrueba().copyWith(
        descripcion: descripcion,
        videoEjemploUrl: video,
      ),
    );

    // Pedido el 2026-10-19: "Vídeo" y, a su derecha, "Descripción".
    testWidgets('lleva Vídeo y, a su derecha, Descripción', (tester) async {
      await montar(tester, conFicha());

      final video = find.byKey(const Key('boton_ver_video'));
      final descripcion = find.byKey(const Key('boton_ver_descripcion'));
      expect(
        find.descendant(of: video, matching: find.text('Vídeo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: descripcion, matching: find.text('Descripción')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(descripcion).dx,
        greaterThan(tester.getTopLeft(video).dx),
      );
    });

    testWidgets('Descripción enseña la explicación del ejercicio', (
      tester,
    ) async {
      await montar(tester, conFicha());

      await tester.tap(find.byKey(const Key('boton_ver_descripcion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hoja_descripcion')), findsOneWidget);
      expect(
        find.text('Espalda pegada al banco y bajar controlado.'),
        findsOneWidget,
      );
    });

    // La descripcion es opcional: un boton que abre una hoja vacia es peor que
    // no tenerlo. Lo mismo el video.
    testWidgets('sin descripción ni vídeo no hay botones', (tester) async {
      await montar(tester, conFicha(descripcion: '   ', video: null));

      expect(find.byKey(const Key('boton_ver_descripcion')), findsNothing);
      expect(find.byKey(const Key('boton_ver_video')), findsNothing);
    });

    testWidgets('sin vídeo, Descripción sale sola', (tester) async {
      await montar(tester, conFicha(video: null));

      expect(find.byKey(const Key('boton_ver_descripcion')), findsOneWidget);
      expect(find.byKey(const Key('boton_ver_video')), findsNothing);
    });
  });
}
