import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/data/datasources/credential_remote_data_source.dart';
import 'package:truth_protocol_app/data/dtos/mint_request.dart';
import 'package:truth_protocol_app/data/dtos/mint_response.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';
import 'package:truth_protocol_app/domain/repositories/credential_repository.dart';

part 'credential_repository_impl.g.dart';

@Riverpod(keepAlive: true)
CredentialRepository credentialRepository(CredentialRepositoryRef ref) {
  return CredentialRepositoryImpl(
    ref.watch(credentialRemoteDataSourceProvider),
  );
}

class CredentialRepositoryImpl implements CredentialRepository {
  final CredentialRemoteDataSource _remoteDataSource;

  CredentialRepositoryImpl(this._remoteDataSource);

  @override
  Future<MintResponse> mintCredential(MintRequest request) async {
    return await _remoteDataSource.mintCredential(request);
  }

  @override
  Future<List<Credential>> getMyCredentials() async {
    return await _remoteDataSource.getMyCredentials();
  }

  @override
  Future<Credential> getCredentialById(String id) async {
    return await _remoteDataSource.getCredentialById(id);
  }
}
