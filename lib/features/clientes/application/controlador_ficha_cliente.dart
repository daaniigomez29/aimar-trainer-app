import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aimar_trainer_app/core/aplicacion/estado_accion.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/clientes/data/cliente_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';

part 'controlador_ficha_cliente.g.dart';

/// CU-17 (alta) y CU-19 (editar ficha).
///
/// Los metodos devuelven el resultado en lugar de dejarlo solo en `state`: este
/// provider es autoDispose y, con dialogos o navegacion de por medio, el estado
/// no es fiable al volver. Misma leccion que el fallo de CU-04.
@riverpod
class ControladorFichaCliente extends _$ControladorFichaCliente {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  /// CU-17: alta via Edge Function. Devuelve el resultado del alta, que incluye
  /// si la invitacion salio por correo.
  Future<Result<ResultadoAlta>> darDeAlta(DatosCliente datos) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay un alta en curso.'));
    }
    final errorValidacion = datos.validar();
    if (errorValidacion != null) {
      state = EstadoAccion.conError(errorValidacion);
      return Failure(errorValidacion);
    }

    state = const EstadoAccion.enCurso();
    final resultado = await ref
        .read(clienteRepositorioProvider)
        .darDeAlta(datos);

    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) ref.invalidate(listaClientesProvider);
    }
    return resultado;
  }

  /// CU-19: edicion de la ficha.
  Future<Result<Cliente>> editar({
    required String id,
    required DatosCliente datos,
  }) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una edición en curso.'));
    }
    final errorValidacion = datos.validar();
    if (errorValidacion != null) {
      state = EstadoAccion.conError(errorValidacion);
      return Failure(errorValidacion);
    }

    state = const EstadoAccion.enCurso();
    final resultado = await ref
        .read(clienteRepositorioProvider)
        .editar(id: id, datos: datos);

    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) ref.invalidate(listaClientesProvider);
    }
    return resultado;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }

  void reiniciar() => state = const EstadoAccion.inicial();
}

/// CU-18: baja logica del cliente, con el aviso previo de plannings activos.
@riverpod
class ControladorBajaCliente extends _$ControladorBajaCliente {
  @override
  EstadoAccion build() => const EstadoAccion.inicial();

  /// Cuantos plannings activos tiene, para decidir si hace falta la confirmacion
  /// adicional de CU-18. `null` si no se ha podido comprobar.
  Future<int?> comprobarPlanningsActivos(String id) async {
    final resultado = await ref
        .read(clienteRepositorioProvider)
        .contarPlanningsActivos(id);
    return switch (resultado) {
      Success(:final valor) => valor,
      Failure() => null,
    };
  }

  Future<Result<Cliente>> darDeBaja(String id) async {
    if (state.enCurso) {
      return const Failure(ErrorValidacion('Ya hay una baja en curso.'));
    }
    state = const EstadoAccion.enCurso();
    final resultado = await ref.read(clienteRepositorioProvider).darDeBaja(id);

    if (ref.mounted) {
      state = switch (resultado) {
        Success() => const EstadoAccion.completada(),
        Failure(:final error) => EstadoAccion.conError(error),
      };
      if (resultado.esExito) ref.invalidate(listaClientesProvider);
    }
    return resultado;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoAccion.inicial();
  }
}
