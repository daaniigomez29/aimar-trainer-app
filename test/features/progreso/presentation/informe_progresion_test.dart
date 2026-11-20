import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';
import 'package:aimar_trainer_app/features/progreso/application/controlador_informe.dart';
import 'package:aimar_trainer_app/features/progreso/data/descargador_pdf.dart';
import 'package:aimar_trainer_app/features/progreso/domain/informe_progresion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/informe/pdf_informe.dart';

import '../../../ayudas/sesion_falsa.dart';
import '../../planificacion_semanal/ayudas_planificacion.dart';
import '../domain/informe_de_prueba.dart';

class PlanningsFalso extends Mock implements PlanningRepositorio {}

class ClientesFalso extends Mock implements ClienteRepositorio {}

/// Se queda con lo que se le pide descargar, en vez de llamar al navegador.
class DescargadorFalso implements DescargadorPdf {
  Uint8List? bytes;
  String? nombreArchivo;

  @override
  Future<void> descargar(
    Uint8List bytes, {
    required String nombreArchivo,
  }) async {
    this.bytes = bytes;
    this.nombreArchivo = nombreArchivo;
  }
}

bool esUnPdf(Uint8List bytes) =>
    ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-';

/// POR QUE ESTE TEST: el informe lo genera el entrenador para enviarlo a un
/// cliente. Lo que importa es que las semanas que elige son las que se
/// cuentan, que el PDF sale, y que se entera de cuando los datos pueden estar
/// inflados por series guardadas sin tocar.
void main() {
  late PlanningsFalso plannings;
  late ClientesFalso clientes;
  late DescargadorFalso descargador;

  final semanas = planningsDePrueba();
  // Una semana futura: no tiene nada que informar y no se ofrece.
  final futura = planningDePrueba(id: 'p-9', fechaInicio: DateTime(2099));

  setUp(() {
    plannings = PlanningsFalso();
    clientes = ClientesFalso();
    descargador = DescargadorFalso();
    when(() => plannings.listarDeCliente(any()))
        .thenAnswer((_) async => Success([...semanas, futura]));
    for (final planning in semanas) {
      when(() => plannings.obtenerPlanningCompleto(planning.id))
          .thenAnswer((_) async => Success(planning));
    }
    when(() => clientes.listar()).thenAnswer(
      (_) async => Success([
        Cliente(
          id: 'c-1',
          nombre: 'Ana García',
          correo: 'ana@ejemplo.com',
          diaControlPreferido: DiaSemana.domingo,
          estado: EstadoCliente.activo,
          fechaAlta: DateTime.utc(2026),
        ),
      ]),
    );
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenedor = await conSesionAbierta(
      ProviderContainer(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(
            AutenticacionDeMentira(),
          ),
          planningRepositorioProvider.overrideWithValue(plannings),
          clienteRepositorioProvider.overrideWithValue(clientes),
          descargadorPdfProvider.overrideWithValue(descargador),
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
    router.go(Rutas.informeDeCliente('c-1'));
    await tester.pumpAndSettle();
  }

  String texto(WidgetTester tester, String clave) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(Key(clave)),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data ?? t.textSpan?.toPlainText())
      .join(' ');

  Future<void> elegir(WidgetTester tester, String clave, String opcion) async {
    await tester.tap(find.byKey(Key(clave)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  testWidgets('de partida, las últimas 8 semanas, sin las futuras', (
    tester,
  ) async {
    await montar(tester);

    // Solo hay dos semanas ya empezadas: el periodo arranca en la primera.
    expect(texto(tester, 'reparto_del_periodo'), contains('Del 05/10/2026'));
    expect(
      texto(tester, 'reparto_del_periodo'),
      contains('2 de 8 semanas planificadas'),
    );
    // Las dos: 2 de 3 sesiones.
    expect(texto(tester, 'cifra_sesiones'), contains('67 %'));
  });

  testWidgets('empezar más tarde deja fuera las anteriores', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('semana_de_inicio')));
    await tester.pumpAndSettle();
    // Un miercoles: el informe empieza el lunes de su semana, el 12/10.
    await tester.tap(find.text('14'));
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();

    expect(texto(tester, 'reparto_del_periodo'), contains('Del 12/10/2026'));
    // Solo la del 12/10: 1 de 1 sesiones.
    expect(texto(tester, 'cifra_sesiones'), contains('100 %'));
  });

  testWidgets('la duración recorta el periodo', (tester) async {
    await montar(tester);

    await elegir(tester, 'duracion_informe', '1 semana');

    // Solo la del 5/10: 1 de 2 sesiones.
    expect(texto(tester, 'cifra_sesiones'), contains('50 %'));
  });

  testWidgets('avisa si muchas series son idénticas al plan', (tester) async {
    await montar(tester);

    // La mitad de las series hechas coincide con el plan.
    expect(find.byKey(const Key('aviso_identicas')), findsOneWidget);
  });

  testWidgets('descarga el PDF con el nombre del cliente', (tester) async {
    await montar(tester);

    await tester.enterText(
      find.byKey(const Key('campo_valoracion')),
      'Buena semana.',
    );
    await tester.tap(find.byKey(const Key('boton_descargar_pdf')));
    // Generar el PDF lleva trabajo real y algun temporizador: se alterna el
    // reloj de verdad con el falso de los tests hasta que termina.
    for (var i = 0; i < 100 && descargador.bytes == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    expect(descargador.bytes, isNotNull);
    expect(esUnPdf(descargador.bytes!), isTrue);
    expect(descargador.nombreArchivo, contains('Ana García'));
  });

  group('mesociclos', () {
    testWidgets('dos semanas en mesociclos de 4: un solo mesociclo', (
      tester,
    ) async {
      await montar(tester);

      expect(find.byKey(const Key('campo_foco_1')), findsOneWidget);
      expect(find.byKey(const Key('campo_foco_2')), findsNothing);
    });

    testWidgets('en mesociclos de 1, uno por semana, sin tocar nada más', (
      tester,
    ) async {
      await montar(tester);

      await elegir(tester, 'semanas_por_mesociclo', '1 semana');

      expect(texto(tester, 'reparto_del_periodo'), contains('Mesociclo 2'));
      expect(find.byKey(const Key('campo_foco_2')), findsOneWidget);
      expect(find.byKey(const Key('campo_hitos_2')), findsOneWidget);
    });

    testWidgets('sin dividir no hay mesociclos', (tester) async {
      await montar(tester);

      await elegir(tester, 'semanas_por_mesociclo', 'Sin dividir');

      expect(find.byKey(const Key('campo_foco_1')), findsNothing);
      expect(
        texto(tester, 'reparto_del_periodo'),
        isNot(contains('Mesociclo')),
      );
    });
  });

  group('el texto para el PDF', () {
    test('lo tipográfico pasa a su equivalente, no desaparece', () {
      expect(
        paraPdf('it’s “bien” – 20 ➔ 22… • ok'),
        'it\'s "bien" - 20 -> 22... · ok',
      );
    });

    test('las tildes y la ñ se quedan como están', () {
      expect(paraPdf('Jesús Ñandú, cuádriceps'), 'Jesús Ñandú, cuádriceps');
    });

    test('lo que no tiene equivalente se marca, no se pierde', () {
      expect(paraPdf('漢'), '?');
    });

    test('párrafos y puntos de lista', () {
      final partes = parrafosDe(
        'Primer párrafo,\nque sigue aquí.\n\nSegundo.\n'
        '- Volumen: alto\n• RIR: 2-3',
      );
      // Dos parrafos y dos puntos.
      expect(partes, hasLength(4));
    });
  });

  group('el PDF', () {
    test('se genera con todo', () async {
      final bytes = await generarPdfInforme(
        DatosPdfInforme(
          nombreCliente: 'Ana García',
          informe: calcularInforme(semanas),
          emitido: DateTime(2026, 11, 17),
          resumen: 'Buena evolución.\n- Volumen total: estable.',
          valoracion: 'Muy constante; las molestias de rodilla remiten.',
          proximosPasos: 'Subir carga en el press.',
          mesociclos: [
            for (final meso in mesociclosDe(
              calcularInforme(semanas),
              desde: DateTime(2026, 10, 5),
              semanasPorMesociclo: 1,
            ))
              TextoMesociclo(
                mesociclo: meso,
                foco: 'Adaptación.',
                hitos: '- Sin molestias.',
              ),
          ],
        ),
      );
      expect(esUnPdf(bytes), isTrue);
    });

    test('se genera aunque no haya nada que contar', () async {
      final bytes = await generarPdfInforme(
        DatosPdfInforme(
          nombreCliente: 'Ana García',
          informe: calcularInforme(const []),
          emitido: DateTime(2026, 11, 17),
        ),
      );
      expect(esUnPdf(bytes), isTrue);
    });

    test('el nombre del archivo lleva el cliente y la fecha', () {
      final datos = DatosPdfInforme(
        nombreCliente: 'Ana García',
        informe: calcularInforme(const []),
        emitido: DateTime(2026, 11, 7),
      );
      expect(
        datos.nombreArchivo,
        'Informe de progresión - Ana García - 2026-11-07.pdf',
      );
    });
  });
}
