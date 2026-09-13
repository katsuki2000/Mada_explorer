import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(
      {required String email, required String password});
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  });
  Future<UserModel> getProfile();
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<AuthResponseModel> login(
      {required String email, required String password}) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(
            e.response?.data?['message'] ?? 'Identifiants invalides.');
      }
      throw ServerException(_dioMessage(e));
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException('Cet email est deja utilise.');
      }
      throw ServerException(_dioMessage(e));
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
    } on DioException {
      // Best-effort: even if the server call fails, local session is cleared
      // by the repository. We swallow the error here on purpose.
    }
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur.';
    }
    return e.response?.data?['message']?.toString() ?? 'Erreur serveur.';
  }
}
