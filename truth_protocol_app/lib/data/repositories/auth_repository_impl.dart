import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/core/utils/secure_storage.dart';
import 'package:truth_protocol_app/data/datasources/auth_remote_data_source.dart';
import 'package:truth_protocol_app/data/dtos/login_request.dart';
import 'package:truth_protocol_app/domain/entities/user.dart';
import 'package:truth_protocol_app/domain/repositories/auth_repository.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  );
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl(this._remoteDataSource, this._secureStorage);

  @override
  Future<User> login(String email, String password) async {
    final response = await _remoteDataSource.login(
      LoginRequest(email: email, password: password),
    );

    await _secureStorage.write(key: 'jwt_token', value: response.token);
    await _secureStorage.write(key: 'user_id', value: response.userId);
    await _secureStorage.write(key: 'user_email', value: response.email);
    await _secureStorage.write(key: 'user_role', value: response.role);

    return User(
      id: response.userId,
      email: response.email,
      role: response.role,
    );
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_role');
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) return null;

    final userId = await _secureStorage.read(key: 'user_id');
    final email = await _secureStorage.read(key: 'user_email');
    final role = await _secureStorage.read(key: 'user_role');

    if (userId != null && email != null && role != null) {
      return User(id: userId, email: email, role: role);
    }
    return null;
  }

  @override
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }
}
