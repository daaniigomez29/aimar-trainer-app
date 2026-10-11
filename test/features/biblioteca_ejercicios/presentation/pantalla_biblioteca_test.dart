import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_biblioteca.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

Ejercicio _ejercicio({
  String id = 'id-1',
  String nombre = 'Press banca',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
  EstadoEjercicio estado = EstadoEjercicio.activo,
  Musculo? musculoPrincipal = Musculo.porcionEsternoCostal,
  List<Musculo> musculosSecundarios = const [],
}) => Ejercicio(
  id: id,
  nombre: nombre,
  descripcion: 'Descripción.',
  tipo: tipo,
  estado: estado,
  creadoEn: DateTime.utc(2026),
  musculoPrincipal: musculoPrincipal,
  musculosSecundarios: musculosSecundarios,
);

void main() {
  late AutenticacionFalsa autenticacion;
  late EjerciciosFalso ejercicios;

  setUp(() {
    autenticacion = AutenticacionFalsa();
    ejercicios = EjerciciosFalso();
    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
  });

  /// Monta la pantalla con la sesion ya resuelta en el rol indicado.
  Future<void> montar(
    WidgetTester tester, {
    required RolUsuario rol,
    required List<Ejercicio> biblioteca,
  }) async {
    when(() => ejercicios.listar())
        .thenAnswer((_) async => Success(biblioteca));
    when(() => autenticacion.idUsuarioActual).thenReturn('id-usuario');
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(id: 'id-usuario', rol: rol, creadoEn: DateTime.utc(2026)),
      ),
    );

    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        ejercicioRepositorioProvider.overrideWithValue(ejercicios),
      ],
    );
    addTearDown(contenedor.dispose);

    // El rol se resuelve leyendo el perfil; se fuerza antes de pintar.
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.oscuro(),
          home: const PantallaBiblioteca(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el entrenador ve el boton de nuevo y las acciones', (
    tester,
  ) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [_ejercicio()],
    );

    expect(find.byKey(const Key('boton_nuevo_ejercicio')), findsOneWidget);
    expect(find.byKey(const Key('editar_id-1')), findsOneWidget);
  });

  testWidgets('el cliente solo consulta: sin alta, edicion ni baja', (
    tester,
  ) async {
    await montar(tester, rol: RolUsuario.cliente, biblioteca: [_ejercicio()]);

    expect(find.text('Press banca'), findsOneWidget);
    expect(find.byKey(const Key('boton_nuevo_ejercicio')), findsNothing);
    expect(find.byKey(const Key('editar_id-1')), findsNothing);
  });

  testWidgets('el cliente no ve el filtro de dados de baja', (tester) async {
    await montar(tester, rol: RolUsuario.cliente, biblioteca: [_ejercicio()]);

    expect(find.text('Dados de baja'), findsNothing);
  });

  testWidgets('el entrenador si ve el filtro de dados de baja', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [_ejercicio()],
    );

    expect(find.text('Dados de baja'), findsOneWidget);
  });

  // El filtro de dos niveles: arriba los grupos, y al elegir uno aparecen sus
  // musculos. Es lo que sustituye a la lista plana en la que no se podia buscar.
  testWidgets('al elegir un grupo aparecen sus músculos', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [
        _ejercicio(
          id: 'id-1',
          nombre: 'Sentadilla',
          musculoPrincipal: Musculo.cuadriceps,
          musculosSecundarios: const [Musculo.gluteo],
        ),
        _ejercicio(
          id: 'id-2',
          nombre: 'Hip thrust',
          musculoPrincipal: Musculo.gluteo,
        ),
      ],
    );

    // El segundo nivel no existe hasta elegir grupo.
    expect(find.byKey(const Key('musculo_cuadriceps')), findsNothing);

    await tester.tap(find.byKey(const Key('grupo_pierna')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('musculo_cuadriceps')), findsOneWidget);
    expect(find.byKey(const Key('musculo_gluteo')), findsOneWidget);
  });

  testWidgets('filtrar por un músculo cuenta los secundarios, con el '
      'principal delante', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [
        _ejercicio(
          id: 'id-1',
          nombre: 'Sentadilla',
          musculoPrincipal: Musculo.cuadriceps,
          musculosSecundarios: const [Musculo.gluteo],
        ),
        _ejercicio(
          id: 'id-2',
          nombre: 'Hip thrust',
          musculoPrincipal: Musculo.gluteo,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('grupo_pierna')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('musculo_gluteo')));
    await tester.pumpAndSettle();

    // La sentadilla sigue estando, aunque el gluteo sea secundario, y lo dice.
    expect(find.text('Hip thrust'), findsOneWidget);
    expect(find.text('Sentadilla'), findsOneWidget);
    expect(find.textContaining('secundario'), findsOneWidget);

    final posiciones = tester
        .widgetList<Text>(find.byType(Text))
        .map((texto) => texto.data)
        .toList();
    expect(
      posiciones.indexOf('Hip thrust'),
      lessThan(posiciones.indexOf('Sentadilla')),
    );
  });

  // Lo que quedo por reclasificar al pasar del texto libre a la taxonomia: se
  // ofrece como pestana para que el entrenador lo complete, en vez de dejarlo
  // escondido.
  testWidgets('los sin clasificar tienen su propia pestaña', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [
        _ejercicio(id: 'id-1', nombre: 'Press banca'),
        _ejercicio(
          id: 'id-2',
          nombre: 'Ejercicio viejo',
          musculoPrincipal: null,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('chip_sin_clasificar')));
    await tester.pumpAndSettle();

    expect(find.text('Ejercicio viejo'), findsOneWidget);
    expect(find.text('Press banca'), findsNothing);
  });

  testWidgets('sin ninguno sin clasificar, esa pestaña no se ofrece', (
    tester,
  ) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [_ejercicio()],
    );

    expect(find.byKey(const Key('chip_sin_clasificar')), findsNothing);
  });

  testWidgets('la búsqueda filtra el listado', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [
        _ejercicio(),
        _ejercicio(id: 'id-2', nombre: 'Remo con barra'),
      ],
    );
    expect(find.text('Press banca'), findsOneWidget);
    expect(find.text('Remo con barra'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo_busqueda')), 'remo');
    await tester.pumpAndSettle();

    expect(find.text('Press banca'), findsNothing);
    expect(find.text('Remo con barra'), findsOneWidget);
  });

  testWidgets('sin coincidencias ofrece quitar los filtros', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      biblioteca: [_ejercicio()],
    );

    await tester.enterText(
      find.byKey(const Key('campo_busqueda')),
      'no-existe',
    );
    await tester.pumpAndSettle();

    expect(find.text('Quitar filtros'), findsOneWidget);
  });

  testWidgets('la biblioteca vacía invita al entrenador a añadir', (
    tester,
  ) async {
    await montar(tester, rol: RolUsuario.entrenador, biblioteca: []);

    expect(find.textContaining('Añade el primer ejercicio'), findsOneWidget);
  });

  testWidgets('la biblioteca vacía da al cliente otro mensaje', (tester) async {
    await montar(tester, rol: RolUsuario.cliente, biblioteca: []);

    expect(
      find.textContaining('todavía no ha añadido ejercicios'),
      findsOneWidget,
    );
  });

  testWidgets('un fallo al cargar muestra el error y permite reintentar', (
    tester,
  ) async {
    when(() => autenticacion.idUsuarioActual).thenReturn('id-usuario');
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(
          id: 'id-usuario',
          rol: RolUsuario.entrenador,
          creadoEn: DateTime.utc(2026),
        ),
      ),
    );
    when(() => ejercicios.listar())
        .thenAnswer((_) async => const Failure(ErrorConexion()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autenticacionRepositorioProvider.overrideWithValue(autenticacion),
          ejercicioRepositorioProvider.overrideWithValue(ejercicios),
        ],
        child: const MaterialApp(home: PantallaBiblioteca()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(const ErrorConexion().mensaje), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
