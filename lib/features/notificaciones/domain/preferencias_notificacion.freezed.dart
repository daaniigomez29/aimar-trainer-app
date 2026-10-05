// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferencias_notificacion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PreferenciasNotificacion {

 String get clienteId; bool get pushActivado; DateTime? get actualizadoEn;
/// Create a copy of PreferenciasNotificacion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreferenciasNotificacionCopyWith<PreferenciasNotificacion> get copyWith => _$PreferenciasNotificacionCopyWithImpl<PreferenciasNotificacion>(this as PreferenciasNotificacion, _$identity);

  /// Serializes this PreferenciasNotificacion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PreferenciasNotificacion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreferenciasNotificacion&&(identical(other.clienteId, _this.clienteId) || other.clienteId == _this.clienteId)&&(identical(other.pushActivado, _this.pushActivado) || other.pushActivado == _this.pushActivado)&&(identical(other.actualizadoEn, _this.actualizadoEn) || other.actualizadoEn == _this.actualizadoEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PreferenciasNotificacion;
  return Object.hash(runtimeType,_this.clienteId,_this.pushActivado,_this.actualizadoEn);
}

@override
String toString() {
  final _this = this as PreferenciasNotificacion;
  return 'PreferenciasNotificacion(clienteId: ${_this.clienteId}, pushActivado: ${_this.pushActivado}, actualizadoEn: ${_this.actualizadoEn})';
}


}

/// @nodoc
abstract mixin class $PreferenciasNotificacionCopyWith<$Res>  {
  factory $PreferenciasNotificacionCopyWith(PreferenciasNotificacion value, $Res Function(PreferenciasNotificacion) _then) = _$PreferenciasNotificacionCopyWithImpl;
@useResult
$Res call({
 String clienteId, bool pushActivado, DateTime? actualizadoEn
});




}
/// @nodoc
class _$PreferenciasNotificacionCopyWithImpl<$Res>
    implements $PreferenciasNotificacionCopyWith<$Res> {
  _$PreferenciasNotificacionCopyWithImpl(this._self, this._then);

  final PreferenciasNotificacion _self;
  final $Res Function(PreferenciasNotificacion) _then;

/// Create a copy of PreferenciasNotificacion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clienteId = null,Object? pushActivado = null,Object? actualizadoEn = freezed,}) {
  return _then(PreferenciasNotificacion(
clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,pushActivado: null == pushActivado ? _self.pushActivado : pushActivado // ignore: cast_nullable_to_non_nullable
as bool,actualizadoEn: freezed == actualizadoEn ? _self.actualizadoEn : actualizadoEn // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PreferenciasNotificacion].
extension PreferenciasNotificacionPatterns on PreferenciasNotificacion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreferenciasNotificacion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreferenciasNotificacion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreferenciasNotificacion value)  $default,){
final _that = this;
switch (_that) {
case _PreferenciasNotificacion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreferenciasNotificacion value)?  $default,){
final _that = this;
switch (_that) {
case _PreferenciasNotificacion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clienteId,  bool pushActivado,  DateTime? actualizadoEn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreferenciasNotificacion() when $default != null:
return $default(_that.clienteId,_that.pushActivado,_that.actualizadoEn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clienteId,  bool pushActivado,  DateTime? actualizadoEn)  $default,) {final _that = this;
switch (_that) {
case _PreferenciasNotificacion():
return $default(_that.clienteId,_that.pushActivado,_that.actualizadoEn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clienteId,  bool pushActivado,  DateTime? actualizadoEn)?  $default,) {final _that = this;
switch (_that) {
case _PreferenciasNotificacion() when $default != null:
return $default(_that.clienteId,_that.pushActivado,_that.actualizadoEn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreferenciasNotificacion implements PreferenciasNotificacion {
  const _PreferenciasNotificacion({required this.clienteId, this.pushActivado = false, this.actualizadoEn});
  factory _PreferenciasNotificacion.fromJson(Map<String, dynamic> json) => _$PreferenciasNotificacionFromJson(json);

@override final  String clienteId;
@override@JsonKey() final  bool pushActivado;
@override final  DateTime? actualizadoEn;

/// Create a copy of PreferenciasNotificacion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreferenciasNotificacionCopyWith<_PreferenciasNotificacion> get copyWith => __$PreferenciasNotificacionCopyWithImpl<_PreferenciasNotificacion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreferenciasNotificacionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreferenciasNotificacion&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.pushActivado, pushActivado) || other.pushActivado == pushActivado)&&(identical(other.actualizadoEn, actualizadoEn) || other.actualizadoEn == actualizadoEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clienteId,pushActivado,actualizadoEn);
}

@override
String toString() {
    return 'PreferenciasNotificacion(clienteId: $clienteId, pushActivado: $pushActivado, actualizadoEn: $actualizadoEn)';
}


}

/// @nodoc
abstract mixin class _$PreferenciasNotificacionCopyWith<$Res> implements $PreferenciasNotificacionCopyWith<$Res> {
  factory _$PreferenciasNotificacionCopyWith(_PreferenciasNotificacion value, $Res Function(_PreferenciasNotificacion) _then) = __$PreferenciasNotificacionCopyWithImpl;
@override @useResult
$Res call({
 String clienteId, bool pushActivado, DateTime? actualizadoEn
});




}
/// @nodoc
class __$PreferenciasNotificacionCopyWithImpl<$Res>
    implements _$PreferenciasNotificacionCopyWith<$Res> {
  __$PreferenciasNotificacionCopyWithImpl(this._self, this._then);

  final _PreferenciasNotificacion _self;
  final $Res Function(_PreferenciasNotificacion) _then;

/// Create a copy of PreferenciasNotificacion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clienteId = null,Object? pushActivado = null,Object? actualizadoEn = freezed,}) {
  return _then(_PreferenciasNotificacion(
clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,pushActivado: null == pushActivado ? _self.pushActivado : pushActivado // ignore: cast_nullable_to_non_nullable
as bool,actualizadoEn: freezed == actualizadoEn ? _self.actualizadoEn : actualizadoEn // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
