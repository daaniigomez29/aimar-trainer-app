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
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/pantalla_biblioteca.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class EjerciciosFalso extends Mock implements EjercicioRepositorio {}

Ejercicio _ejercicio({
  String id = 'id-1',
  String nombre = 'Press banca',
  TipoEjercicio tipo = TipoEjercicio.fuerza,
  EstadoEjercicio estado = EstadoEjercicio.activo,
  String? grupoMuscular = 'Pecho',
}) => Ejercicio(
  id: id,
  nombre: nombre,
  descripcion: 'Descripcion.',
  tipo: tipo,
  estado: estado,
  creadoEn: DateTime.utc(2026),
  grupoMuscular: grupoMuscular,
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

  testWidgets('la busqueda filtra el listado', (tester) async {
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

  testWidgets('la biblioteca vacia invita al entrenador a anadir', (
    tester,
  ) async {
    await montar(tester, rol: RolUsuario.entrenador, biblioteca: []);

    expect(find.textContaining('Anade el primer ejercicio'), findsOneWidget);
  });

  testWidgets('la biblioteca vacia da al cliente otro mensaje', (tester) async {
    await montar(tester, rol: RolUsuario.cliente, biblioteca: []);

    expect(
      find.textContaining('todavia no ha anadido ejercicios'),
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
