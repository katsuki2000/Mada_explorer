import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/species_model.dart';

abstract class SpeciesRemoteDataSource {
  Future<List<SpeciesModel>> getSpecies();
}

class SpeciesRemoteDataSourceImpl implements SpeciesRemoteDataSource {
  final Dio dio;
  SpeciesRemoteDataSourceImpl(this.dio);

  @override
  Future<List<SpeciesModel>> getSpecies() async {
    try {
      final response = await dio.get(ApiConstants.species);
      final list = response.data as List;
      return list.map((e) => SpeciesModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ServerException('Impossible de joindre le serveur.');
      }
      throw ServerException(e.response?.data?['message']?.toString() ?? 'Erreur serveur.');
    }
  }
}
