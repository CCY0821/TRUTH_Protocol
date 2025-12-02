import 'package:truth_protocol_app/data/dtos/mint_request.dart';
import 'package:truth_protocol_app/data/dtos/mint_response.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';

abstract class CredentialRepository {
  Future<MintResponse> mintCredential(MintRequest request);
  Future<List<Credential>> getMyCredentials();
  Future<Credential> getCredentialById(String id);
}
