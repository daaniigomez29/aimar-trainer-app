import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudas/app_con_rutas.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_biblioteca.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

Ejercicio _ejercicio([EstadoEjercicio estado = EstadoEjercicio.activo]) =>
    Ejercicio(
      id: 'id-1',
      nombre: 'Press banca',
      descripcion: 'Tumbado en banco plano.',
      tipo: TipoEjercicio.fuerza,
      estado: estado,
      creadoEn: DateTime.utc(2026),
    );

void main() {
  late AutenticacionFalsa autenticacion;
  late EjerciciosFalso ejercicios;

  setUpAll(() {
    registerFallbackValue(
      const DatosEjercicio(
        nombre: 'x',
        descripcion: 'x',
        tipo: TipoEjercicio.fuerza,
      ),
    );
  });

  setUp(() {
    autenticacion = AutenticacionFalsa();
    ejercicios = EjerciciosFalso();
    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn('id-entrenador');
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(
          id: 'id-entrenador',
          rol: RolUsuario.entrenador,
          creadoEn: DateTime.utc(2026),
        ),
      ),
    );
    when(() => ejercicios.listar())
        .thenAnswer((_) async => Success([_ejercicio()]));
    when(() => ejercicios.contarUsosEnPlanningsActivos(any()))
        .thenAnswer((_) async => const Success(0));
    when(
      () => ejercicios.darDeBaja(any()),
    ).thenAnswer((_) async => Success(_ejercicio(EstadoEjercicio.eliminado)));
  });

  Future<void> montar(WidgetTester tester) async {
    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        ejercicioRepositorioProvider.overrideWithValue(ejercicios),
      ],
    );
    addTearDown(contenedor.dispose);
    // Sin esto el rol no esta resuelto y la pantalla no pinta las acciones del
    // entrenador.
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        // Con las rutas anidadas igual que en la aplicación: el formulario
        // cuelga de la biblioteca, así que al cerrarlo queda pantalla debajo.
        child: appConRutas(
          rutaInicial: Rutas.bibliotecaEntrenador,
          rutas: [
            GoRoute(
              path: Rutas.bibliotecaEntrenador,
              builder: (_, _) => const PantallaBiblioteca(),
              routes: [
                GoRoute(
                  path: Rutas.nuevo,
                  builder: (_, _) => const PantallaFormularioEjercicio(),
                ),
                GoRoute(
                  path: Rutas.detalleEjercicio,
                  builder: (_, estado) => PantallaFormularioEjercicio(
                    idEjercicio: estado.pathParameters['idEjercicio'],
                  ),
                  routes: [
                    GoRoute(
                      path: Rutas.editar,
                      builder: (_, estado) => PantallaFormularioEjercicio(
                        idEjercicio: estado.pathParameters['idEjercicio'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('CU-04: dar de baja desde el listado completa el flujo', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('Dar de baja el ejercicio'),
      findsOneWidget,
      reason: 'deberia abrirse el dialogo de confirmación',
    );

    await tester.tap(find.byKey(const Key('boton_confirmar_baja')));
    await tester.pumpAndSettle();

    verify(() => ejercicios.darDeBaja('id-1')).called(1);
    expect(find.text('Dar de baja el ejercicio'), findsNothing);
    // El aviso con "Deshacer" se cierra con un temporizador propio: hay que
    // dejarlo expirar o el test termina con un Timer pendiente.
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('CU-04: cancelar no da de baja', (tester) async {
    await montar(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => ejercicios.darDeBaja(any()));
  });

  testWidgets('CU-04: si esta en uso pide una confirmación adicional', (
    tester,
  ) async {
    when(() => ejercicios.contarUsosEnPlanningsActivos(any()))
        .thenAnswer((_) async => const Success(2));
    await montar(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_baja')));
    await tester.pumpAndSettle();

    expect(find.text('El ejercicio está en uso'), findsOneWidget);
    verifyNever(() => ejercicios.darDeBaja(any()));

    await tester.tap(find.byKey(const Key('boton_confirmar_aviso')));
    await tester.pumpAndSettle();

    verify(() => ejercicios.darDeBaja('id-1')).called(1);
    // El aviso con "Deshacer" se cierra con un temporizador propio: hay que
    // dejarlo expirar o el test termina con un Timer pendiente.
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('el alta desde el listado llega al repositorio (CU-02)', (
    tester,
  ) async {
    when(() => ejercicios.crear(any()))
        .thenAnswer((_) async => Success(_ejercicio()));
    await montar(tester);

    await tester.tap(find.byKey(const Key('boton_nuevo_ejercicio')));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo ejercicio'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('campo_nombre')),
      'Remo con barra',
    );
    await tester.enterText(
      find.byKey(const Key('campo_descripcion')),
      'Torso inclinado, tira hacia el abdomen.',
    );
    // El formulario es mas alto que el viewport de 600px del test: hay que
    // desplazarse hasta el boton antes de pulsarlo.
    await tester.ensureVisible(
      find.byKey(const Key('boton_guardar_ejercicio')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_guardar_ejercicio')));
    await tester.pumpAndSettle();

    verify(() => ejercicios.crear(any())).called(1);
  });

  testWidgets('la edicion precarga los datos y guarda (CU-03)', (tester) async {
    when(
      () => ejercicios.editar(
        id: any(named: 'id'),
        datos: any(named: 'datos'),
      ),
    ).thenAnswer((_) async => Success(_ejercicio()));
    await montar(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Editar ejercicio'), findsOneWidget);
    expect(find.text('Press banca'), findsOneWidget);

    // El formulario es mas alto que el viewport de 600px del test: hay que
    // desplazarse hasta el boton antes de pulsarlo.
    await tester.ensureVisible(
      find.byKey(const Key('boton_guardar_ejercicio')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_guardar_ejercicio')));
    await tester.pumpAndSettle();

    verify(
      () => ejercicios.editar(
        id: 'id-1',
        datos: any(named: 'datos'),
      ),
    ).called(1);
  });
}
