import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/park_model.dart';

abstract class ParksRemoteDataSource {
  Future<List<ParkModel>> getParks();
  Future<ParkModel> getParkById(String id);
}

class ParksRemoteDataSourceImpl implements ParksRemoteDataSource {
  final Dio dio;
  ParksRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ParkModel>> getParks() async {
    try {
      final response = await dio.get(ApiConstants.parks);
      final list = response.data as List;
      return list.map((e) => ParkModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_message(e));
    }
  }

  @override
  Future<ParkModel> getParkById(String id) async {
    try {
      final response = await dio.get('${ApiConstants.parks}/$id');
      return ParkModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_message(e));
    }
  }

  String _message(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur.';
    }
    return e.response?.data?['message']?.toString() ?? 'Erreur serveur.';
  }
}
