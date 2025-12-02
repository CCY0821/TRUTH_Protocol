// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mint_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MintRequest _$MintRequestFromJson(Map<String, dynamic> json) {
  return _MintRequest.fromJson(json);
}

/// @nodoc
mixin _$MintRequest {
  String get recipientWalletAddress => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MintRequestCopyWith<MintRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MintRequestCopyWith<$Res> {
  factory $MintRequestCopyWith(
          MintRequest value, $Res Function(MintRequest) then) =
      _$MintRequestCopyWithImpl<$Res, MintRequest>;
  @useResult
  $Res call({String recipientWalletAddress, Map<String, dynamic> metadata});
}

/// @nodoc
class _$MintRequestCopyWithImpl<$Res, $Val extends MintRequest>
    implements $MintRequestCopyWith<$Res> {
  _$MintRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipientWalletAddress = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      recipientWalletAddress: null == recipientWalletAddress
          ? _value.recipientWalletAddress
          : recipientWalletAddress // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MintRequestImplCopyWith<$Res>
    implements $MintRequestCopyWith<$Res> {
  factory _$$MintRequestImplCopyWith(
          _$MintRequestImpl value, $Res Function(_$MintRequestImpl) then) =
      __$$MintRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String recipientWalletAddress, Map<String, dynamic> metadata});
}

/// @nodoc
class __$$MintRequestImplCopyWithImpl<$Res>
    extends _$MintRequestCopyWithImpl<$Res, _$MintRequestImpl>
    implements _$$MintRequestImplCopyWith<$Res> {
  __$$MintRequestImplCopyWithImpl(
      _$MintRequestImpl _value, $Res Function(_$MintRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipientWalletAddress = null,
    Object? metadata = null,
  }) {
    return _then(_$MintRequestImpl(
      recipientWalletAddress: null == recipientWalletAddress
          ? _value.recipientWalletAddress
          : recipientWalletAddress // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MintRequestImpl implements _MintRequest {
  const _$MintRequestImpl(
      {required this.recipientWalletAddress,
      required final Map<String, dynamic> metadata})
      : _metadata = metadata;

  factory _$MintRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$MintRequestImplFromJson(json);

  @override
  final String recipientWalletAddress;
  final Map<String, dynamic> _metadata;
  @override
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'MintRequest(recipientWalletAddress: $recipientWalletAddress, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MintRequestImpl &&
            (identical(other.recipientWalletAddress, recipientWalletAddress) ||
                other.recipientWalletAddress == recipientWalletAddress) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recipientWalletAddress,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MintRequestImplCopyWith<_$MintRequestImpl> get copyWith =>
      __$$MintRequestImplCopyWithImpl<_$MintRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MintRequestImplToJson(
      this,
    );
  }
}

abstract class _MintRequest implements MintRequest {
  const factory _MintRequest(
      {required final String recipientWalletAddress,
      required final Map<String, dynamic> metadata}) = _$MintRequestImpl;

  factory _MintRequest.fromJson(Map<String, dynamic> json) =
      _$MintRequestImpl.fromJson;

  @override
  String get recipientWalletAddress;
  @override
  Map<String, dynamic> get metadata;
  @override
  @JsonKey(ignore: true)
  _$$MintRequestImplCopyWith<_$MintRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
