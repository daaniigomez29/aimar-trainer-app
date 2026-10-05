import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/data/autenticacion_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/pantalla_clientes.dart';

class AutenticacionFalsa extends Mock implements AutenticacionRepositorio {}

class ClientesFalso extends Mock implements ClienteRepositorio {}

Cliente _cliente({
  String id = 'id-1',
  String nombre = 'Ana Garcia',
  String correo = 'ana@ejemplo.com',
  EstadoCliente estado = EstadoCliente.activo,
}) => Cliente(
  id: id,
  nombre: nombre,
  correo: correo,
  diaControlPreferido: DiaSemana.domingo,
  estado: estado,
  fechaAlta: DateTime.utc(2026),
  fechaBaja: estado == EstadoCliente.baja ? DateTime.utc(2026, 6) : null,
);

void main() {
  late AutenticacionFalsa autenticacion;
  late ClientesFalso clientes;

  setUp(() {
    autenticacion = AutenticacionFalsa();
    clientes = ClientesFalso();
    when(() => autenticacion.cambiosDeAutenticacion)
        .thenAnswer((_) => const Stream.empty());
    when(() => autenticacion.debeFijarContrasena).thenReturn(false);
    when(() => autenticacion.idUsuarioActual).thenReturn('id-usuario');
  });

  Future<void> montar(
    WidgetTester tester, {
    required RolUsuario rol,
    required List<Cliente> fichas,
  }) async {
    when(() => autenticacion.perfilDeLaSesion()).thenAnswer(
      (_) async => Success(
        Perfil(id: 'id-usuario', rol: rol, creadoEn: DateTime.utc(2026)),
      ),
    );
    when(() => clientes.listar()).thenAnswer((_) async => Success(fichas));

    final contenedor = ProviderContainer(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        clienteRepositorioProvider.overrideWithValue(clientes),
      ],
    );
    addTearDown(contenedor.dispose);
    await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaClientes()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el entrenador ve el listado y puede gestionar', (tester) async {
    await montar(tester, rol: RolUsuario.entrenador, fichas: [_cliente()]);

    expect(find.text('Ana Garcia'), findsOneWidget);
    expect(find.byKey(const Key('boton_nuevo_cliente')), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);
  });

  testWidgets(
    'el administrador puede dar de alta pero no ve fichas (minimizacion de datos)',
    (tester) async {
      // RLS no le da politica de lectura sobre `clientes`, asi que su listado
      // llega vacio. La pantalla lo explica en vez de parecer un error.
      await montar(tester, rol: RolUsuario.administrador, fichas: []);

      expect(find.byKey(const Key('boton_nuevo_cliente')), findsOneWidget);
      expect(find.textContaining('no consultar sus fichas'), findsOneWidget);
      expect(find.byKey(const Key('campo_busqueda_clientes')), findsNothing);
    },
  );

  testWidgets('los dados de baja se ocultan salvo que se pidan', (
    tester,
  ) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      fichas: [
        _cliente(),
        _cliente(
          id: 'id-2',
          nombre: 'Luis Perez',
          correo: 'luis@ejemplo.com',
          estado: EstadoCliente.baja,
        ),
      ],
    );
    expect(find.text('Luis Perez'), findsNothing);

    await tester.tap(find.text('Ver dados de baja'));
    await tester.pumpAndSettle();

    expect(find.text('Luis Perez'), findsOneWidget);
  });

  testWidgets('un cliente de baja no ofrece editar ni volver a dar de baja', (
    tester,
  ) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      fichas: [_cliente(estado: EstadoCliente.baja)],
    );
    await tester.tap(find.text('Ver dados de baja'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.person_off_outlined), findsNothing);
  });

  testWidgets('la busqueda filtra por nombre y correo', (tester) async {
    await montar(
      tester,
      rol: RolUsuario.entrenador,
      fichas: [
        _cliente(),
        _cliente(id: 'id-2', nombre: 'Luis Perez', correo: 'luis@ejemplo.com'),
      ],
    );

    await tester.enterText(
      find.byKey(const Key('campo_busqueda_clientes')),
      'luis@',
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Garcia'), findsNothing);
    expect(find.text('Luis Perez'), findsOneWidget);
  });

  testWidgets('sin clientes invita a dar de alta al primero', (tester) async {
    await montar(tester, rol: RolUsuario.entrenador, fichas: []);

    expect(find.textContaining('Da de alta al primero'), findsOneWidget);
  });
}
