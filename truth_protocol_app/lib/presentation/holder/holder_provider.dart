import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/data/datasources/credential_remote_data_source.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';

part 'holder_provider.g.dart';

@riverpod
class HolderCredentialList extends _$HolderCredentialList {
  @override
  Future<List<Credential>> build() async {
    return _fetchCredentials();
  }

  Future<List<Credential>> _fetchCredentials() async {
    final dataSource = ref.read(credentialRemoteDataSourceProvider);
    return await dataSource.getHolderCredentials();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCredentials());
  }
}
