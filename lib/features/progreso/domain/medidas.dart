import 'package:freezed_annotation/freezed_annotation.dart';

part 'medidas.freezed.dart';
part 'medidas.g.dart';

/// Registro de medidas corporales (entidad 9 de `docs/domain-model.md`).
///
/// Solo `pesoKg` es obligatorio; los perimetros son opcionales porque el cliente
/// no siempre se los mide todos.
@freezed
abstract class RegistroMedidas with _$RegistroMedidas {
  const factory RegistroMedidas({
    required String id,
    required String clienteId,
    required DateTime fecha,
    required double pesoKg,
    double? pechoCm,
    double? cinturaCm,
    double? caderaCm,
    double? cuadricepsCm,
    double? brazosCm,
    @Default([]) @JsonKey(name: 'fotos_progreso') List<FotoProgreso> fotos,
  }) = _RegistroMedidas;

  factory RegistroMedidas.fromJson(Map<String, dynamic> json) =>
      _$RegistroMedidasFromJson(json);
}

/// Foto de progreso. El fichero vive en el bucket privado `fotos-progreso`; aqui
/// solo esta su ruta. Para mostrarla hace falta pedir una URL firmada, que caduca.
@freezed
abstract class FotoProgreso with _$FotoProgreso {
  const factory FotoProgreso({
    required String id,
    required String registroMedidasId,
    required String rutaStorage,
    required DateTime subidaEn,
  }) = _FotoProgreso;

  factory FotoProgreso.fromJson(Map<String, dynamic> json) =>
      _$FotoProgresoFromJson(json);
}

/// Check-in semanal de recuperacion (entidad 10).
///
/// No tiene relacion con [RegistroMedidas]: comparten `fecha` por convencion de la
/// interfaz, no por restriccion de dominio.
@freezed
abstract class CheckinRecuperacion with _$CheckinRecuperacion {
  const factory CheckinRecuperacion({
    required String id,
    required String clienteId,
    required DateTime fecha,
    required double horasSueno,
    required int estres,
    required int agujetas,
    required int fatiga,
    String? notas,
  }) = _CheckinRecuperacion;

  factory CheckinRecuperacion.fromJson(Map<String, dynamic> json) =>
      _$CheckinRecuperacionFromJson(json);
}
