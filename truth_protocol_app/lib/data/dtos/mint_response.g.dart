// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mint_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MintResponseImpl _$$MintResponseImplFromJson(Map<String, dynamic> json) =>
    _$MintResponseImpl(
      credentialId: json['credentialId'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$$MintResponseImplToJson(_$MintResponseImpl instance) =>
    <String, dynamic>{
      'credentialId': instance.credentialId,
      'status': instance.status,
      'message': instance.message,
    };
