// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cliente.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Cliente {

 String get id; String get nombre; String get correo; DiaSemana get diaControlPreferido; EstadoCliente get estado; DateTime get fechaAlta; DateTime? get fechaNacimiento; double? get alturaCm; double? get pesoInicialKg; String? get objetivos; DateTime? get fechaBaja;
/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClienteCopyWith<Cliente> get copyWith => _$ClienteCopyWithImpl<Cliente>(this as Cliente, _$identity);

  /// Serializes this Cliente to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Cliente;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cliente&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.correo, _this.correo) || other.correo == _this.correo)&&(identical(other.diaControlPreferido, _this.diaControlPreferido) || other.diaControlPreferido == _this.diaControlPreferido)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.fechaAlta, _this.fechaAlta) || other.fechaAlta == _this.fechaAlta)&&(identical(other.fechaNacimiento, _this.fechaNacimiento) || other.fechaNacimiento == _this.fechaNacimiento)&&(identical(other.alturaCm, _this.alturaCm) || other.alturaCm == _this.alturaCm)&&(identical(other.pesoInicialKg, _this.pesoInicialKg) || other.pesoInicialKg == _this.pesoInicialKg)&&(identical(other.objetivos, _this.objetivos) || other.objetivos == _this.objetivos)&&(identical(other.fechaBaja, _this.fechaBaja) || other.fechaBaja == _this.fechaBaja));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Cliente;
  return Object.hash(runtimeType,_this.id,_this.nombre,_this.correo,_this.diaControlPreferido,_this.estado,_this.fechaAlta,_this.fechaNacimiento,_this.alturaCm,_this.pesoInicialKg,_this.objetivos,_this.fechaBaja);
}

@override
String toString() {
  final _this = this as Cliente;
  return 'Cliente(id: ${_this.id}, nombre: ${_this.nombre}, correo: ${_this.correo}, diaControlPreferido: ${_this.diaControlPreferido}, estado: ${_this.estado}, fechaAlta: ${_this.fechaAlta}, fechaNacimiento: ${_this.fechaNacimiento}, alturaCm: ${_this.alturaCm}, pesoInicialKg: ${_this.pesoInicialKg}, objetivos: ${_this.objetivos}, fechaBaja: ${_this.fechaBaja})';
}


}

/// @nodoc
abstract mixin class $ClienteCopyWith<$Res>  {
  factory $ClienteCopyWith(Cliente value, $Res Function(Cliente) _then) = _$ClienteCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, String correo, DiaSemana diaControlPreferido, EstadoCliente estado, DateTime fechaAlta, DateTime? fechaNacimiento, double? alturaCm, double? pesoInicialKg, String? objetivos, DateTime? fechaBaja
});




}
/// @nodoc
class _$ClienteCopyWithImpl<$Res>
    implements $ClienteCopyWith<$Res> {
  _$ClienteCopyWithImpl(this._self, this._then);

  final Cliente _self;
  final $Res Function(Cliente) _then;

/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? correo = null,Object? diaControlPreferido = null,Object? estado = null,Object? fechaAlta = null,Object? fechaNacimiento = freezed,Object? alturaCm = freezed,Object? pesoInicialKg = freezed,Object? objetivos = freezed,Object? fechaBaja = freezed,}) {
  return _then(Cliente(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,correo: null == correo ? _self.correo : correo // ignore: cast_nullable_to_non_nullable
as String,diaControlPreferido: null == diaControlPreferido ? _self.diaControlPreferido : diaControlPreferido // ignore: cast_nullable_to_non_nullable
as DiaSemana,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoCliente,fechaAlta: null == fechaAlta ? _self.fechaAlta : fechaAlta // ignore: cast_nullable_to_non_nullable
as DateTime,fechaNacimiento: freezed == fechaNacimiento ? _self.fechaNacimiento : fechaNacimiento // ignore: cast_nullable_to_non_nullable
as DateTime?,alturaCm: freezed == alturaCm ? _self.alturaCm : alturaCm // ignore: cast_nullable_to_non_nullable
as double?,pesoInicialKg: freezed == pesoInicialKg ? _self.pesoInicialKg : pesoInicialKg // ignore: cast_nullable_to_non_nullable
as double?,objetivos: freezed == objetivos ? _self.objetivos : objetivos // ignore: cast_nullable_to_non_nullable
as String?,fechaBaja: freezed == fechaBaja ? _self.fechaBaja : fechaBaja // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Cliente].
extension ClientePatterns on Cliente {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Cliente value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cliente() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Cliente value)  $default,){
final _that = this;
switch (_that) {
case _Cliente():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Cliente value)?  $default,){
final _that = this;
switch (_that) {
case _Cliente() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  String correo,  DiaSemana diaControlPreferido,  EstadoCliente estado,  DateTime fechaAlta,  DateTime? fechaNacimiento,  double? alturaCm,  double? pesoInicialKg,  String? objetivos,  DateTime? fechaBaja)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cliente() when $default != null:
return $default(_that.id,_that.nombre,_that.correo,_that.diaControlPreferido,_that.estado,_that.fechaAlta,_that.fechaNacimiento,_that.alturaCm,_that.pesoInicialKg,_that.objetivos,_that.fechaBaja);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  String correo,  DiaSemana diaControlPreferido,  EstadoCliente estado,  DateTime fechaAlta,  DateTime? fechaNacimiento,  double? alturaCm,  double? pesoInicialKg,  String? objetivos,  DateTime? fechaBaja)  $default,) {final _that = this;
switch (_that) {
case _Cliente():
return $default(_that.id,_that.nombre,_that.correo,_that.diaControlPreferido,_that.estado,_that.fechaAlta,_that.fechaNacimiento,_that.alturaCm,_that.pesoInicialKg,_that.objetivos,_that.fechaBaja);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  String correo,  DiaSemana diaControlPreferido,  EstadoCliente estado,  DateTime fechaAlta,  DateTime? fechaNacimiento,  double? alturaCm,  double? pesoInicialKg,  String? objetivos,  DateTime? fechaBaja)?  $default,) {final _that = this;
switch (_that) {
case _Cliente() when $default != null:
return $default(_that.id,_that.nombre,_that.correo,_that.diaControlPreferido,_that.estado,_that.fechaAlta,_that.fechaNacimiento,_that.alturaCm,_that.pesoInicialKg,_that.objetivos,_that.fechaBaja);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cliente implements Cliente {
  const _Cliente({required this.id, required this.nombre, required this.correo, required this.diaControlPreferido, required this.estado, required this.fechaAlta, this.fechaNacimiento, this.alturaCm, this.pesoInicialKg, this.objetivos, this.fechaBaja});
  factory _Cliente.fromJson(Map<String, dynamic> json) => _$ClienteFromJson(json);

@override final  String id;
@override final  String nombre;
@override final  String correo;
@override final  DiaSemana diaControlPreferido;
@override final  EstadoCliente estado;
@override final  DateTime fechaAlta;
@override final  DateTime? fechaNacimiento;
@override final  double? alturaCm;
@override final  double? pesoInicialKg;
@override final  String? objetivos;
@override final  DateTime? fechaBaja;

/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClienteCopyWith<_Cliente> get copyWith => __$ClienteCopyWithImpl<_Cliente>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClienteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cliente&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.correo, correo) || other.correo == correo)&&(identical(other.diaControlPreferido, diaControlPreferido) || other.diaControlPreferido == diaControlPreferido)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaAlta, fechaAlta) || other.fechaAlta == fechaAlta)&&(identical(other.fechaNacimiento, fechaNacimiento) || other.fechaNacimiento == fechaNacimiento)&&(identical(other.alturaCm, alturaCm) || other.alturaCm == alturaCm)&&(identical(other.pesoInicialKg, pesoInicialKg) || other.pesoInicialKg == pesoInicialKg)&&(identical(other.objetivos, objetivos) || other.objetivos == objetivos)&&(identical(other.fechaBaja, fechaBaja) || other.fechaBaja == fechaBaja));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nombre,correo,diaControlPreferido,estado,fechaAlta,fechaNacimiento,alturaCm,pesoInicialKg,objetivos,fechaBaja);
}

@override
String toString() {
    return 'Cliente(id: $id, nombre: $nombre, correo: $correo, diaControlPreferido: $diaControlPreferido, estado: $estado, fechaAlta: $fechaAlta, fechaNacimiento: $fechaNacimiento, alturaCm: $alturaCm, pesoInicialKg: $pesoInicialKg, objetivos: $objetivos, fechaBaja: $fechaBaja)';
}


}

/// @nodoc
abstract mixin class _$ClienteCopyWith<$Res> implements $ClienteCopyWith<$Res> {
  factory _$ClienteCopyWith(_Cliente value, $Res Function(_Cliente) _then) = __$ClienteCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, String correo, DiaSemana diaControlPreferido, EstadoCliente estado, DateTime fechaAlta, DateTime? fechaNacimiento, double? alturaCm, double? pesoInicialKg, String? objetivos, DateTime? fechaBaja
});




}
/// @nodoc
class __$ClienteCopyWithImpl<$Res>
    implements _$ClienteCopyWith<$Res> {
  __$ClienteCopyWithImpl(this._self, this._then);

  final _Cliente _self;
  final $Res Function(_Cliente) _then;

/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? correo = null,Object? diaControlPreferido = null,Object? estado = null,Object? fechaAlta = null,Object? fechaNacimiento = freezed,Object? alturaCm = freezed,Object? pesoInicialKg = freezed,Object? objetivos = freezed,Object? fechaBaja = freezed,}) {
  return _then(_Cliente(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,correo: null == correo ? _self.correo : correo // ignore: cast_nullable_to_non_nullable
as String,diaControlPreferido: null == diaControlPreferido ? _self.diaControlPreferido : diaControlPreferido // ignore: cast_nullable_to_non_nullable
as DiaSemana,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoCliente,fechaAlta: null == fechaAlta ? _self.fechaAlta : fechaAlta // ignore: cast_nullable_to_non_nullable
as DateTime,fechaNacimiento: freezed == fechaNacimiento ? _self.fechaNacimiento : fechaNacimiento // ignore: cast_nullable_to_non_nullable
as DateTime?,alturaCm: freezed == alturaCm ? _self.alturaCm : alturaCm // ignore: cast_nullable_to_non_nullable
as double?,pesoInicialKg: freezed == pesoInicialKg ? _self.pesoInicialKg : pesoInicialKg // ignore: cast_nullable_to_non_nullable
as double?,objetivos: freezed == objetivos ? _self.objetivos : objetivos // ignore: cast_nullable_to_non_nullable
as String?,fechaBaja: freezed == fechaBaja ? _self.fechaBaja : fechaBaja // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
