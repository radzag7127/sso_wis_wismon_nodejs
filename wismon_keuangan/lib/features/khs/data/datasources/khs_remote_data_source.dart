// lib/features/khs/data/datasources/khs_remote_data_source.dart

import '../../../../core/services/api_service.dart';
import '../models/khs_model.dart';

abstract class KhsRemoteDataSource {
  Future<KhsModel> getKhs(int semesterKe);
}

class KhsRemoteDataSourceImpl implements KhsRemoteDataSource {
  final ApiService apiService;

  KhsRemoteDataSourceImpl({required this.apiService});

  @override
  Future<KhsModel> getKhs(int semesterKe) async {
    final endpoint = '/api/akademik/mahasiswa/khs?semesterKe=$semesterKe';
    final data = await apiService.get(endpoint);

    if (data['success']) {
      return KhsModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data KHS');
    }
  }
}
