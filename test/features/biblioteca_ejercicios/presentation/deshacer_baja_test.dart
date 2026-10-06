import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/data/ejercicio_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/dialogos_ejercicio.dart';

class RepositorioFalso extends Mock implements EjercicioRepositorio {}

/// POR QUE ESTE TEST: el "Deshacer" del aviso de baja no hacía nada cuando se
/// daba de baja desde la ficha del ejercicio. La ficha hace `pop` al terminar,
/// así que su `BuildContext` ya estaba muerto cuando el usuario pulsaba, y la
/// reactivación salía por un `if (!context.mounted) return` sin decir nada.
///
/// Aquí se reproduce esa situación: se lanza la baja desde una pantalla que
/// **se cierra** justo después, y se comprueba que el botón sigue reactivando.
void main() {
  late RepositorioFalso repositorio;

  final ejercicio = Ejercicio(
    id: 'ej-1',
    nombre: 'Press banca',
    descripcion: 'x',
    tipo: TipoEjercicio.fuerza,
    estado: EstadoEjercicio.activo,
    creadoEn: DateTime.utc(2026),
  );

  setUp(() {
    repositorio = RepositorioFalso();
    when(() => repositorio.contarUsosEnPlanningsActivos(any()))
        .thenAnswer((_) async => const Success(0));
    when(() => repositorio.darDeBaja(any())).thenAnswer(
      (_) async =>
          Success(ejercicio.copyWith(estado: EstadoEjercicio.eliminado)),
    );
    when(() => repositorio.reactivar(any()))
        .thenAnswer((_) async => Success(ejercicio));
  });

  testWidgets('el Deshacer reactiva aunque la pantalla ya se haya cerrado', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ejercicioRepositorioProvider.overrideWithValue(repositorio),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (contexto) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(contexto).push(
                    MaterialPageRoute<void>(builder: (_) => const _Ficha()),
                  ),
                  child: const Text('Abrir ficha'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir ficha'));
    await tester.pumpAndSettle();

    // La ficha da de baja y se cierra, como hace la de verdad.
    await tester.tap(find.text('Dar de baja y cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_baja')));
    await tester.pumpAndSettle();

    expect(find.text('"Press banca" dado de baja.'), findsOneWidget);
    expect(
      find.text('Abrir ficha'),
      findsOneWidget,
      reason: 'la ficha se cerró',
    );

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    verify(() => repositorio.reactivar('ej-1')).called(1);
    expect(find.text('"Press banca" vuelve a estar activo.'), findsOneWidget);
  });

  testWidgets('el aviso de la baja (con Deshacer) se va a los 6 segundos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ejercicioRepositorioProvider.overrideWithValue(repositorio),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (contexto) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(contexto).push(
                    MaterialPageRoute<void>(builder: (_) => const _Ficha()),
                  ),
                  child: const Text('Abrir ficha'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir ficha'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dar de baja y cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_baja')));
    await tester.pumpAndSettle();

    expect(find.text('"Press banca" dado de baja.'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);

    // A los 6,1 s ya se está yendo: es el camino real de dar de baja, el mismo
    // que se probó a mano en el navegador.
    await tester.pump(const Duration(seconds: 6, milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('"Press banca" dado de baja.'), findsNothing);
  });

  testWidgets('el aviso se va solo a los 3 segundos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (contexto) => Center(
                child: ElevatedButton(
                  onPressed: () => Avisos.mostrar(contexto, 'Guardado.'),
                  child: const Text('Avisar'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Avisar'));
    // La cuenta atrás empieza cuando termina la animación de entrada, así que
    // primero se deja aparecer del todo.
    await tester.pumpAndSettle();
    expect(find.text('Guardado.'), findsOneWidget);

    // A los 3,1 s ya se está yendo. Con los cuatro segundos de por defecto, que
    // es lo que había antes, aquí seguiría en pantalla.
    await tester.pump(const Duration(seconds: 3, milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Guardado.'), findsNothing);
  });
}

/// Una ficha de las que se cierran al dar de baja.
class _Ficha extends ConsumerWidget {
  const _Ficha();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ejercicio = Ejercicio(
      id: 'ej-1',
      nombre: 'Press banca',
      descripcion: 'x',
      tipo: TipoEjercicio.fuerza,
      estado: EstadoEjercicio.activo,
      creadoEn: DateTime.utc(2026),
    );

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final navegador = Navigator.of(context);
            await confirmarBajaEjercicio(
              context: context,
              ref: ref,
              ejercicio: ejercicio,
            );
            navegador.pop();
          },
          child: const Text('Dar de baja y cerrar'),
        ),
      ),
    );
  }
}
