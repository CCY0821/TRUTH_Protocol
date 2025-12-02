import 'package:freezed_annotation/freezed_annotation.dart';

part 'mint_request.freezed.dart';
part 'mint_request.g.dart';

@freezed
class MintRequest with _$MintRequest {
  const factory MintRequest({
    required String recipientWalletAddress,
    required Map<String, dynamic> metadata,
  }) = _MintRequest;

  factory MintRequest.fromJson(Map<String, dynamic> json) => _$MintRequestFromJson(json);
}
