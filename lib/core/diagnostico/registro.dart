import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';

/// Registro de diagnostico para desarrollo.
///
/// Existe porque la arquitectura de la app es deliberadamente silenciosa: los
/// repositorios capturan toda excepcion y la convierten en [ErrorApp] para
/// mostrar un mensaje util en la interfaz. Eso esta bien para quien usa la app,
/// pero sin este registro la causa real (la `PostgrestException`, el fallo de red,
/// el error de PostgREST) no aparece en ningun sitio y no hay forma de depurar.
///
/// Solo escribe en modo debug: un build de produccion no debe filtrar mensajes
/// internos ni datos en la consola del navegador.
abstract final class Registro {
  /// Se desactiva en los tests para que no ensucien la salida; `verificarRegistro`
  /// lo activa cuando lo que se prueba es el propio registro.
  @visibleForTesting
  static bool activo = kDebugMode;

  /// Instala los manejadores globales de errores no capturados.
  ///
  /// Sin esto, en Flutter Web un error dentro de un `Future` sin `catch` puede
  /// perderse sin dejar rastro en la consola de depuracion.
  static void instalarManejadoresGlobales() {
    FlutterError.onError = (detalles) {
      FlutterError.presentError(detalles);
      _escribir(
        'Error de Flutter',
        detalles.exception,
        detalles.stack,
        contexto: detalles.context?.toDescription(),
      );
    };

    // Errores que escapan del arbol de widgets (Futures sin capturar, callbacks
    // asincronos). Devolver `true` los marca como atendidos.
    PlatformDispatcher.instance.onError = (error, traza) {
      _escribir('Error no capturado', error, traza);
      return true;
    };
  }

  /// Registra la causa real de un error que se va a traducir a [ErrorApp].
  ///
  /// Se llama desde los repositorios: el usuario vera "ha ocurrido un error
  /// inesperado", y aqui queda escrito qué paso de verdad.
  static void fallo(
    Object error,
    StackTrace? traza, {
    required String contexto,
  }) => _escribir('Fallo en $contexto', error, traza);

  /// Registra el error y devuelve el [ErrorInesperado] correspondiente.
  ///
  /// Pensado para usarse dentro de una expresion `switch`, donde no cabe una
  /// sentencia: `_ => Registro.inesperado(error, traza, contexto: '...')`.
  static ErrorApp inesperado(
    Object error,
    StackTrace? traza, {
    required String contexto,
  }) {
    _escribir('Fallo en $contexto', error, traza);
    return ErrorInesperado(causa: error, traza: traza);
  }

  /// Traza informativa de un paso del flujo. Util para seguir, por ejemplo, la
  /// secuencia de eventos de autenticacion.
  static void info(String mensaje) {
    if (!activo) return;
    debugPrint('[aimar] $mensaje');
  }

  static void _escribir(
    String titulo,
    Object error,
    StackTrace? traza, {
    String? contexto,
  }) {
    if (!activo) return;

    final lineas = <String>[
      '',
      '┌─ [aimar] $titulo ${'─' * 20}',
      '│ tipo: ${error.runtimeType}',
      '│ $error',
      if (contexto != null) '│ contexto: $contexto',
      ..._detalleDeError(error),
    ];
    debugPrint(lineas.join('\n'));

    if (traza != null) {
      // Se recortan las primeras lineas: suelen ser suficientes para localizar el
      // origen, y la pila completa de Flutter Web es larguisima.
      final pila = traza.toString().split('\n').take(12).join('\n');
      debugPrint('│ pila:\n$pila');
    }
    debugPrint('└${'─' * 40}\n');
  }

  /// Saca a la luz los campos que los errores de Supabase esconden en sus
  /// propiedades, y que son justo los que explican el fallo.
  static List<String> _detalleDeError(Object error) {
    final detalle = <String>[];

    // Se accede por `dynamic` para no importar supabase_flutter en `core/`, que
    // debe quedar libre de dependencias de infraestructura.
    try {
      final dinamico = error as dynamic;
      void anadir(String etiqueta, Object? valor) {
        if (valor != null && valor.toString().isNotEmpty) {
          detalle.add('│ $etiqueta: $valor');
        }
      }

      final nombre = error.runtimeType.toString();
      if (nombre == 'PostgrestException') {
        anadir('code', dinamico.code);
        anadir('details', dinamico.details);
        anadir('hint', dinamico.hint);
      } else if (nombre == 'AuthException' ||
          nombre == 'AuthApiException' ||
          nombre == 'AuthWeakPasswordException') {
        anadir('code', dinamico.code);
        anadir('statusCode', dinamico.statusCode);
      } else if (nombre == 'FunctionException') {
        anadir('status', dinamico.status);
        anadir('details', dinamico.details);
        anadir('reasonPhrase', dinamico.reasonPhrase);
      } else if (error is ErrorInesperado) {
        anadir('causa', error.causa);
      }
    } on Object {
      // Si el error no tiene esas propiedades, no pasa nada: ya se ha escrito su
      // `toString()`.
    }
    return detalle;
  }
}

/// Envuelve el arranque de la app para capturar lo que falle durante el `runApp`.
Future<void> ejecutarConRegistro(Future<void> Function() arranque) async {
  Registro.instalarManejadoresGlobales();
  await runZonedGuarded(arranque, (error, traza) {
    Registro.fallo(error, traza, contexto: 'la zona raiz de la aplicacion');
  });
}
