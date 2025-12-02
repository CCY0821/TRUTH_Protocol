// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mint_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MintRequestImpl _$$MintRequestImplFromJson(Map<String, dynamic> json) =>
    _$MintRequestImpl(
      recipientWalletAddress: json['recipientWalletAddress'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$MintRequestImplToJson(_$MintRequestImpl instance) =>
    <String, dynamic>{
      'recipientWalletAddress': instance.recipientWalletAddress,
      'metadata': instance.metadata,
    };
