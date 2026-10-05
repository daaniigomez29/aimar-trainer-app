// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metricas_progreso.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegistroProgreso {

 String get clienteId; String get ejercicioId; String get ejercicioNombre; TipoEjercicio get ejercicioTipo; String get sesionId; DateTime get fecha; int? get numeroSerie; int? get repeticionesRealizadas; double? get pesoReal; int? get rirReal; double? get minutosRealizados;
/// Create a copy of RegistroProgreso
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegistroProgresoCopyWith<RegistroProgreso> get copyWith => _$RegistroProgresoCopyWithImpl<RegistroProgreso>(this as RegistroProgreso, _$identity);

  /// Serializes this RegistroProgreso to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RegistroProgreso;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegistroProgreso&&(identical(other.clienteId, _this.clienteId) || other.clienteId == _this.clienteId)&&(identical(other.ejercicioId, _this.ejercicioId) || other.ejercicioId == _this.ejercicioId)&&(identical(other.ejercicioNombre, _this.ejercicioNombre) || other.ejercicioNombre == _this.ejercicioNombre)&&(identical(other.ejercicioTipo, _this.ejercicioTipo) || other.ejercicioTipo == _this.ejercicioTipo)&&(identical(other.sesionId, _this.sesionId) || other.sesionId == _this.sesionId)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.numeroSerie, _this.numeroSerie) || other.numeroSerie == _this.numeroSerie)&&(identical(other.repeticionesRealizadas, _this.repeticionesRealizadas) || other.repeticionesRealizadas == _this.repeticionesRealizadas)&&(identical(other.pesoReal, _this.pesoReal) || other.pesoReal == _this.pesoReal)&&(identical(other.rirReal, _this.rirReal) || other.rirReal == _this.rirReal)&&(identical(other.minutosRealizados, _this.minutosRealizados) || other.minutosRealizados == _this.minutosRealizados));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RegistroProgreso;
  return Object.hash(runtimeType,_this.clienteId,_this.ejercicioId,_this.ejercicioNombre,_this.ejercicioTipo,_this.sesionId,_this.fecha,_this.numeroSerie,_this.repeticionesRealizadas,_this.pesoReal,_this.rirReal,_this.minutosRealizados);
}

@override
String toString() {
  final _this = this as RegistroProgreso;
  return 'RegistroProgreso(clienteId: ${_this.clienteId}, ejercicioId: ${_this.ejercicioId}, ejercicioNombre: ${_this.ejercicioNombre}, ejercicioTipo: ${_this.ejercicioTipo}, sesionId: ${_this.sesionId}, fecha: ${_this.fecha}, numeroSerie: ${_this.numeroSerie}, repeticionesRealizadas: ${_this.repeticionesRealizadas}, pesoReal: ${_this.pesoReal}, rirReal: ${_this.rirReal}, minutosRealizados: ${_this.minutosRealizados})';
}


}

/// @nodoc
abstract mixin class $RegistroProgresoCopyWith<$Res>  {
  factory $RegistroProgresoCopyWith(RegistroProgreso value, $Res Function(RegistroProgreso) _then) = _$RegistroProgresoCopyWithImpl;
@useResult
$Res call({
 String clienteId, String ejercicioId, String ejercicioNombre, TipoEjercicio ejercicioTipo, String sesionId, DateTime fecha, int? numeroSerie, int? repeticionesRealizadas, double? pesoReal, int? rirReal, double? minutosRealizados
});




}
/// @nodoc
class _$RegistroProgresoCopyWithImpl<$Res>
    implements $RegistroProgresoCopyWith<$Res> {
  _$RegistroProgresoCopyWithImpl(this._self, this._then);

  final RegistroProgreso _self;
  final $Res Function(RegistroProgreso) _then;

/// Create a copy of RegistroProgreso
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clienteId = null,Object? ejercicioId = null,Object? ejercicioNombre = null,Object? ejercicioTipo = null,Object? sesionId = null,Object? fecha = null,Object? numeroSerie = freezed,Object? repeticionesRealizadas = freezed,Object? pesoReal = freezed,Object? rirReal = freezed,Object? minutosRealizados = freezed,}) {
  return _then(RegistroProgreso(
clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,ejercicioNombre: null == ejercicioNombre ? _self.ejercicioNombre : ejercicioNombre // ignore: cast_nullable_to_non_nullable
as String,ejercicioTipo: null == ejercicioTipo ? _self.ejercicioTipo : ejercicioTipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,numeroSerie: freezed == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int?,repeticionesRealizadas: freezed == repeticionesRealizadas ? _self.repeticionesRealizadas : repeticionesRealizadas // ignore: cast_nullable_to_non_nullable
as int?,pesoReal: freezed == pesoReal ? _self.pesoReal : pesoReal // ignore: cast_nullable_to_non_nullable
as double?,rirReal: freezed == rirReal ? _self.rirReal : rirReal // ignore: cast_nullable_to_non_nullable
as int?,minutosRealizados: freezed == minutosRealizados ? _self.minutosRealizados : minutosRealizados // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RegistroProgreso].
extension RegistroProgresoPatterns on RegistroProgreso {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegistroProgreso value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegistroProgreso() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegistroProgreso value)  $default,){
final _that = this;
switch (_that) {
case _RegistroProgreso():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegistroProgreso value)?  $default,){
final _that = this;
switch (_that) {
case _RegistroProgreso() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clienteId,  String ejercicioId,  String ejercicioNombre,  TipoEjercicio ejercicioTipo,  String sesionId,  DateTime fecha,  int? numeroSerie,  int? repeticionesRealizadas,  double? pesoReal,  int? rirReal,  double? minutosRealizados)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegistroProgreso() when $default != null:
return $default(_that.clienteId,_that.ejercicioId,_that.ejercicioNombre,_that.ejercicioTipo,_that.sesionId,_that.fecha,_that.numeroSerie,_that.repeticionesRealizadas,_that.pesoReal,_that.rirReal,_that.minutosRealizados);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clienteId,  String ejercicioId,  String ejercicioNombre,  TipoEjercicio ejercicioTipo,  String sesionId,  DateTime fecha,  int? numeroSerie,  int? repeticionesRealizadas,  double? pesoReal,  int? rirReal,  double? minutosRealizados)  $default,) {final _that = this;
switch (_that) {
case _RegistroProgreso():
return $default(_that.clienteId,_that.ejercicioId,_that.ejercicioNombre,_that.ejercicioTipo,_that.sesionId,_that.fecha,_that.numeroSerie,_that.repeticionesRealizadas,_that.pesoReal,_that.rirReal,_that.minutosRealizados);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clienteId,  String ejercicioId,  String ejercicioNombre,  TipoEjercicio ejercicioTipo,  String sesionId,  DateTime fecha,  int? numeroSerie,  int? repeticionesRealizadas,  double? pesoReal,  int? rirReal,  double? minutosRealizados)?  $default,) {final _that = this;
switch (_that) {
case _RegistroProgreso() when $default != null:
return $default(_that.clienteId,_that.ejercicioId,_that.ejercicioNombre,_that.ejercicioTipo,_that.sesionId,_that.fecha,_that.numeroSerie,_that.repeticionesRealizadas,_that.pesoReal,_that.rirReal,_that.minutosRealizados);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegistroProgreso implements RegistroProgreso {
  const _RegistroProgreso({required this.clienteId, required this.ejercicioId, required this.ejercicioNombre, required this.ejercicioTipo, required this.sesionId, required this.fecha, this.numeroSerie, this.repeticionesRealizadas, this.pesoReal, this.rirReal, this.minutosRealizados});
  factory _RegistroProgreso.fromJson(Map<String, dynamic> json) => _$RegistroProgresoFromJson(json);

@override final  String clienteId;
@override final  String ejercicioId;
@override final  String ejercicioNombre;
@override final  TipoEjercicio ejercicioTipo;
@override final  String sesionId;
@override final  DateTime fecha;
@override final  int? numeroSerie;
@override final  int? repeticionesRealizadas;
@override final  double? pesoReal;
@override final  int? rirReal;
@override final  double? minutosRealizados;

/// Create a copy of RegistroProgreso
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegistroProgresoCopyWith<_RegistroProgreso> get copyWith => __$RegistroProgresoCopyWithImpl<_RegistroProgreso>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegistroProgresoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegistroProgreso&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.ejercicioId, ejercicioId) || other.ejercicioId == ejercicioId)&&(identical(other.ejercicioNombre, ejercicioNombre) || other.ejercicioNombre == ejercicioNombre)&&(identical(other.ejercicioTipo, ejercicioTipo) || other.ejercicioTipo == ejercicioTipo)&&(identical(other.sesionId, sesionId) || other.sesionId == sesionId)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.numeroSerie, numeroSerie) || other.numeroSerie == numeroSerie)&&(identical(other.repeticionesRealizadas, repeticionesRealizadas) || other.repeticionesRealizadas == repeticionesRealizadas)&&(identical(other.pesoReal, pesoReal) || other.pesoReal == pesoReal)&&(identical(other.rirReal, rirReal) || other.rirReal == rirReal)&&(identical(other.minutosRealizados, minutosRealizados) || other.minutosRealizados == minutosRealizados));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clienteId,ejercicioId,ejercicioNombre,ejercicioTipo,sesionId,fecha,numeroSerie,repeticionesRealizadas,pesoReal,rirReal,minutosRealizados);
}

@override
String toString() {
    return 'RegistroProgreso(clienteId: $clienteId, ejercicioId: $ejercicioId, ejercicioNombre: $ejercicioNombre, ejercicioTipo: $ejercicioTipo, sesionId: $sesionId, fecha: $fecha, numeroSerie: $numeroSerie, repeticionesRealizadas: $repeticionesRealizadas, pesoReal: $pesoReal, rirReal: $rirReal, minutosRealizados: $minutosRealizados)';
}


}

/// @nodoc
abstract mixin class _$RegistroProgresoCopyWith<$Res> implements $RegistroProgresoCopyWith<$Res> {
  factory _$RegistroProgresoCopyWith(_RegistroProgreso value, $Res Function(_RegistroProgreso) _then) = __$RegistroProgresoCopyWithImpl;
@override @useResult
$Res call({
 String clienteId, String ejercicioId, String ejercicioNombre, TipoEjercicio ejercicioTipo, String sesionId, DateTime fecha, int? numeroSerie, int? repeticionesRealizadas, double? pesoReal, int? rirReal, double? minutosRealizados
});




}
/// @nodoc
class __$RegistroProgresoCopyWithImpl<$Res>
    implements _$RegistroProgresoCopyWith<$Res> {
  __$RegistroProgresoCopyWithImpl(this._self, this._then);

  final _RegistroProgreso _self;
  final $Res Function(_RegistroProgreso) _then;

/// Create a copy of RegistroProgreso
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clienteId = null,Object? ejercicioId = null,Object? ejercicioNombre = null,Object? ejercicioTipo = null,Object? sesionId = null,Object? fecha = null,Object? numeroSerie = freezed,Object? repeticionesRealizadas = freezed,Object? pesoReal = freezed,Object? rirReal = freezed,Object? minutosRealizados = freezed,}) {
  return _then(_RegistroProgreso(
clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,ejercicioNombre: null == ejercicioNombre ? _self.ejercicioNombre : ejercicioNombre // ignore: cast_nullable_to_non_nullable
as String,ejercicioTipo: null == ejercicioTipo ? _self.ejercicioTipo : ejercicioTipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,numeroSerie: freezed == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int?,repeticionesRealizadas: freezed == repeticionesRealizadas ? _self.repeticionesRealizadas : repeticionesRealizadas // ignore: cast_nullable_to_non_nullable
as int?,pesoReal: freezed == pesoReal ? _self.pesoReal : pesoReal // ignore: cast_nullable_to_non_nullable
as double?,rirReal: freezed == rirReal ? _self.rirReal : rirReal // ignore: cast_nullable_to_non_nullable
as int?,minutosRealizados: freezed == minutosRealizados ? _self.minutosRealizados : minutosRealizados // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$EjercicioConRegistro {

 String get ejercicioId; String get ejercicioNombre; TipoEjercicio get ejercicioTipo;
/// Create a copy of EjercicioConRegistro
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EjercicioConRegistroCopyWith<EjercicioConRegistro> get copyWith => _$EjercicioConRegistroCopyWithImpl<EjercicioConRegistro>(this as EjercicioConRegistro, _$identity);

  /// Serializes this EjercicioConRegistro to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EjercicioConRegistro;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EjercicioConRegistro&&(identical(other.ejercicioId, _this.ejercicioId) || other.ejercicioId == _this.ejercicioId)&&(identical(other.ejercicioNombre, _this.ejercicioNombre) || other.ejercicioNombre == _this.ejercicioNombre)&&(identical(other.ejercicioTipo, _this.ejercicioTipo) || other.ejercicioTipo == _this.ejercicioTipo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EjercicioConRegistro;
  return Object.hash(runtimeType,_this.ejercicioId,_this.ejercicioNombre,_this.ejercicioTipo);
}

@override
String toString() {
  final _this = this as EjercicioConRegistro;
  return 'EjercicioConRegistro(ejercicioId: ${_this.ejercicioId}, ejercicioNombre: ${_this.ejercicioNombre}, ejercicioTipo: ${_this.ejercicioTipo})';
}


}

/// @nodoc
abstract mixin class $EjercicioConRegistroCopyWith<$Res>  {
  factory $EjercicioConRegistroCopyWith(EjercicioConRegistro value, $Res Function(EjercicioConRegistro) _then) = _$EjercicioConRegistroCopyWithImpl;
@useResult
$Res call({
 String ejercicioId, String ejercicioNombre, TipoEjercicio ejercicioTipo
});




}
/// @nodoc
class _$EjercicioConRegistroCopyWithImpl<$Res>
    implements $EjercicioConRegistroCopyWith<$Res> {
  _$EjercicioConRegistroCopyWithImpl(this._self, this._then);

  final EjercicioConRegistro _self;
  final $Res Function(EjercicioConRegistro) _then;

/// Create a copy of EjercicioConRegistro
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ejercicioId = null,Object? ejercicioNombre = null,Object? ejercicioTipo = null,}) {
  return _then(EjercicioConRegistro(
ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,ejercicioNombre: null == ejercicioNombre ? _self.ejercicioNombre : ejercicioNombre // ignore: cast_nullable_to_non_nullable
as String,ejercicioTipo: null == ejercicioTipo ? _self.ejercicioTipo : ejercicioTipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,
  ));
}

}


/// Adds pattern-matching-related methods to [EjercicioConRegistro].
extension EjercicioConRegistroPatterns on EjercicioConRegistro {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EjercicioConRegistro value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EjercicioConRegistro() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EjercicioConRegistro value)  $default,){
final _that = this;
switch (_that) {
case _EjercicioConRegistro():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EjercicioConRegistro value)?  $default,){
final _that = this;
switch (_that) {
case _EjercicioConRegistro() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ejercicioId,  String ejercicioNombre,  TipoEjercicio ejercicioTipo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EjercicioConRegistro() when $default != null:
return $default(_that.ejercicioId,_that.ejercicioNombre,_that.ejercicioTipo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ejercicioId,  String ejercicioNombre,  TipoEjercicio ejercicioTipo)  $default,) {final _that = this;
switch (_that) {
case _EjercicioConRegistro():
return $default(_that.ejercicioId,_that.ejercicioNombre,_that.ejercicioTipo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ejercicioId,  String ejercicioNombre,  TipoEjercicio ejercicioTipo)?  $default,) {final _that = this;
switch (_that) {
case _EjercicioConRegistro() when $default != null:
return $default(_that.ejercicioId,_that.ejercicioNombre,_that.ejercicioTipo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EjercicioConRegistro implements EjercicioConRegistro {
  const _EjercicioConRegistro({required this.ejercicioId, required this.ejercicioNombre, required this.ejercicioTipo});
  factory _EjercicioConRegistro.fromJson(Map<String, dynamic> json) => _$EjercicioConRegistroFromJson(json);

@override final  String ejercicioId;
@override final  String ejercicioNombre;
@override final  TipoEjercicio ejercicioTipo;

/// Create a copy of EjercicioConRegistro
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EjercicioConRegistroCopyWith<_EjercicioConRegistro> get copyWith => __$EjercicioConRegistroCopyWithImpl<_EjercicioConRegistro>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EjercicioConRegistroToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EjercicioConRegistro&&(identical(other.ejercicioId, ejercicioId) || other.ejercicioId == ejercicioId)&&(identical(other.ejercicioNombre, ejercicioNombre) || other.ejercicioNombre == ejercicioNombre)&&(identical(other.ejercicioTipo, ejercicioTipo) || other.ejercicioTipo == ejercicioTipo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ejercicioId,ejercicioNombre,ejercicioTipo);
}

@override
String toString() {
    return 'EjercicioConRegistro(ejercicioId: $ejercicioId, ejercicioNombre: $ejercicioNombre, ejercicioTipo: $ejercicioTipo)';
}


}

/// @nodoc
abstract mixin class _$EjercicioConRegistroCopyWith<$Res> implements $EjercicioConRegistroCopyWith<$Res> {
  factory _$EjercicioConRegistroCopyWith(_EjercicioConRegistro value, $Res Function(_EjercicioConRegistro) _then) = __$EjercicioConRegistroCopyWithImpl;
@override @useResult
$Res call({
 String ejercicioId, String ejercicioNombre, TipoEjercicio ejercicioTipo
});




}
/// @nodoc
class __$EjercicioConRegistroCopyWithImpl<$Res>
    implements _$EjercicioConRegistroCopyWith<$Res> {
  __$EjercicioConRegistroCopyWithImpl(this._self, this._then);

  final _EjercicioConRegistro _self;
  final $Res Function(_EjercicioConRegistro) _then;

/// Create a copy of EjercicioConRegistro
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ejercicioId = null,Object? ejercicioNombre = null,Object? ejercicioTipo = null,}) {
  return _then(_EjercicioConRegistro(
ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,ejercicioNombre: null == ejercicioNombre ? _self.ejercicioNombre : ejercicioNombre // ignore: cast_nullable_to_non_nullable
as String,ejercicioTipo: null == ejercicioTipo ? _self.ejercicioTipo : ejercicioTipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,
  ));
}


}

// dart format on
