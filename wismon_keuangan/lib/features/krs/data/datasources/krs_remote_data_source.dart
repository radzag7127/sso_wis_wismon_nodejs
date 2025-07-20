// lib/features/krs/data/datasources/krs_remote_data_source.dart

import '../../../../core/services/api_service.dart';
import '../models/krs_model.dart';

abstract class KrsRemoteDataSource {
  Future<KrsModel> getKrs(int semesterKe);
}

class KrsRemoteDataSourceImpl implements KrsRemoteDataSource {
  final ApiService apiService;

  KrsRemoteDataSourceImpl({required this.apiService});

  @override
  Future<KrsModel> getKrs(int semesterKe) async {
    // The endpoint now only requires semesterKe
    final endpoint = '/api/akademik/krs?semesterKe=$semesterKe';
    final data = await apiService.get(endpoint);
    if (data['success']) {
      return KrsModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data KRS');
    }
  }
}
