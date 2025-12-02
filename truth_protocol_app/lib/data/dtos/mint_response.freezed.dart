// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mint_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MintResponse _$MintResponseFromJson(Map<String, dynamic> json) {
  return _MintResponse.fromJson(json);
}

/// @nodoc
mixin _$MintResponse {
  String get credentialId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MintResponseCopyWith<MintResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MintResponseCopyWith<$Res> {
  factory $MintResponseCopyWith(
          MintResponse value, $Res Function(MintResponse) then) =
      _$MintResponseCopyWithImpl<$Res, MintResponse>;
  @useResult
  $Res call({String credentialId, String status, String? message});
}

/// @nodoc
class _$MintResponseCopyWithImpl<$Res, $Val extends MintResponse>
    implements $MintResponseCopyWith<$Res> {
  _$MintResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? credentialId = null,
    Object? status = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      credentialId: null == credentialId
          ? _value.credentialId
          : credentialId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MintResponseImplCopyWith<$Res>
    implements $MintResponseCopyWith<$Res> {
  factory _$$MintResponseImplCopyWith(
          _$MintResponseImpl value, $Res Function(_$MintResponseImpl) then) =
      __$$MintResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String credentialId, String status, String? message});
}

/// @nodoc
class __$$MintResponseImplCopyWithImpl<$Res>
    extends _$MintResponseCopyWithImpl<$Res, _$MintResponseImpl>
    implements _$$MintResponseImplCopyWith<$Res> {
  __$$MintResponseImplCopyWithImpl(
      _$MintResponseImpl _value, $Res Function(_$MintResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? credentialId = null,
    Object? status = null,
    Object? message = freezed,
  }) {
    return _then(_$MintResponseImpl(
      credentialId: null == credentialId
          ? _value.credentialId
          : credentialId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MintResponseImpl implements _MintResponse {
  const _$MintResponseImpl(
      {required this.credentialId, required this.status, this.message});

  factory _$MintResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MintResponseImplFromJson(json);

  @override
  final String credentialId;
  @override
  final String status;
  @override
  final String? message;

  @override
  String toString() {
    return 'MintResponse(credentialId: $credentialId, status: $status, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MintResponseImpl &&
            (identical(other.credentialId, credentialId) ||
                other.credentialId == credentialId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, credentialId, status, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MintResponseImplCopyWith<_$MintResponseImpl> get copyWith =>
      __$$MintResponseImplCopyWithImpl<_$MintResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MintResponseImplToJson(
      this,
    );
  }
}

abstract class _MintResponse implements MintResponse {
  const factory _MintResponse(
      {required final String credentialId,
      required final String status,
      final String? message}) = _$MintResponseImpl;

  factory _MintResponse.fromJson(Map<String, dynamic> json) =
      _$MintResponseImpl.fromJson;

  @override
  String get credentialId;
  @override
  String get status;
  @override
  String? get message;
  @override
  @JsonKey(ignore: true)
  _$$MintResponseImplCopyWith<_$MintResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
