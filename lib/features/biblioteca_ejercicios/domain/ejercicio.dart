import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

part 'ejercicio.freezed.dart';
part 'ejercicio.g.dart';

/// Ejercicio de la biblioteca (entidad 5 de `docs/domain-model.md`).
///
/// Editar nombre, descripcion o grupo muscular no altera los parametros ya
/// guardados en ejercicios planificados existentes (RF-03): esos guardan su
/// propia copia de series y minutos, y solo referencian el `id`.
@freezed
abstract class Ejercicio with _$Ejercicio {
  const factory Ejercicio({
    required String id,
    required String nombre,
    required String descripcion,
    required TipoEjercicio tipo,
    required EstadoEjercicio estado,
    required DateTime creadoEn,
    String? grupoMuscular,
    String? equipamiento,
    String? videoEjemploUrl,

    /// Ruta de la ilustracion dentro del bucket publico `imagenes-ejercicios`.
    /// No se guarda la URL completa porque el dominio cambia entre local y la
    /// nube; la arma el repositorio.
    String? imagenRuta,
  }) = _Ejercicio;

  factory Ejercicio.fromJson(Map<String, dynamic> json) =>
      _$EjercicioFromJson(json);
}

/// Datos que el entrenador introduce al crear o editar un ejercicio (CU-02,
/// CU-03). No incluye `id`, `estado` ni `creadoEn`: los gestiona la base de datos
/// o el propio flujo de baja.
class DatosEjercicio {
  const DatosEjercicio({
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    this.grupoMuscular,
    this.equipamiento,
    this.videoEjemploUrl,
    this.imagenRuta,
  });

  static const int longitudMaximaNombre = 120;
  static const int longitudMaximaDescripcion = 2000;

  final String nombre;
  final String descripcion;
  final TipoEjercicio tipo;
  final String? grupoMuscular;
  final String? equipamiento;
  final String? videoEjemploUrl;

  /// Ruta ya subida al bucket. La imagen se sube antes de guardar la fila, asi
  /// que cuando estos datos llegan al repositorio ya es una ruta, no un fichero.
  final String? imagenRuta;

  String get nombreNormalizado => nombre.trim();

  /// Campos de texto opcionales: se guardan como `null` si quedan vacios, para
  /// no mezclar cadena vacia y ausencia de dato en la base de datos.
  String? get grupoMuscularNormalizado => _oNulo(grupoMuscular);
  String? get equipamientoNormalizado => _oNulo(equipamiento);
  String? get videoEjemploUrlNormalizada => _oNulo(videoEjemploUrl);

  static String? _oNulo(String? valor) {
    final limpio = valor?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  static ErrorValidacion? validarNombre(String nombre) {
    final valor = nombre.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion(
        'El nombre es obligatorio.',
        campo: 'nombre',
      );
    }
    if (valor.length > longitudMaximaNombre) {
      return const ErrorValidacion(
        'El nombre no puede pasar de $longitudMaximaNombre caracteres.',
        campo: 'nombre',
      );
    }
    return null;
  }

  static ErrorValidacion? validarDescripcion(String descripcion) {
    final valor = descripcion.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion(
        'La descripción es obligatoria: explica como se ejecuta.',
        campo: 'descripcion',
      );
    }
    if (valor.length > longitudMaximaDescripcion) {
      return const ErrorValidacion(
        'La descripción no puede pasar de '
        '$longitudMaximaDescripcion caracteres.',
        campo: 'descripcion',
      );
    }
    return null;
  }

  /// El video es opcional, pero si se indica tiene que ser una URL http(s):
  /// se abre en el navegador del cliente.
  static ErrorValidacion? validarVideo(String? url) {
    final valor = url?.trim() ?? '';
    if (valor.isEmpty) return null;

    final uri = Uri.tryParse(valor);
    final esValida =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host.isNotEmpty);
    if (!esValida) {
      return const ErrorValidacion(
        'El enlace del vídeo debe empezar por http:// o https://.',
        campo: 'videoEjemploUrl',
      );
    }
    return null;
  }

  /// Primer error de validacion, o `null` si los datos son validos.
  ErrorValidacion? validar() =>
      validarNombre(nombre) ??
      validarDescripcion(descripcion) ??
      validarVideo(videoEjemploUrl);

  /// Cuerpo para Supabase. Las claves van en `snake_case` porque aqui se escribe
  /// un filtro/payload a mano, no un modelo generado.
  Map<String, dynamic> aJsonDeEscritura() => {
    'nombre': nombreNormalizado,
    'descripcion': descripcion.trim(),
    'tipo': tipo.name,
    'grupo_muscular': grupoMuscularNormalizado,
    'equipamiento': equipamientoNormalizado,
    'video_ejemplo_url': videoEjemploUrlNormalizada,
    'imagen_ruta': _oNulo(imagenRuta),
  };

  /// Mismos datos con otra imagen. Lo usa el controlador cuando acaba de subir
  /// una: el formulario no conoce la ruta hasta que la subida termina.
  DatosEjercicio conImagen(String? ruta) => DatosEjercicio(
    nombre: nombre,
    descripcion: descripcion,
    tipo: tipo,
    grupoMuscular: grupoMuscular,
    equipamiento: equipamiento,
    videoEjemploUrl: videoEjemploUrl,
    imagenRuta: ruta,
  );

  /// Datos precargados al abrir el formulario de edicion (CU-03, paso 2).
  factory DatosEjercicio.desdeEjercicio(Ejercicio ejercicio) => DatosEjercicio(
    nombre: ejercicio.nombre,
    descripcion: ejercicio.descripcion,
    tipo: ejercicio.tipo,
    grupoMuscular: ejercicio.grupoMuscular,
    equipamiento: ejercicio.equipamiento,
    videoEjemploUrl: ejercicio.videoEjemploUrl,
    imagenRuta: ejercicio.imagenRuta,
  );
}
