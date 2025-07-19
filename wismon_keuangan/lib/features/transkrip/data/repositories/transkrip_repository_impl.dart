// lib/features/transkrip/data/repositories/transkrip_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/services/api_service.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/domain/repositories/transkrip_repository.dart';
import 'package:wismon_keuangan/features/transkrip/data/models/transkrip_model.dart';

class TranskripRepositoryImpl implements TranskripRepository {
  final ApiService apiService;

  TranskripRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, Transkrip>> getTranskrip() async {
    try {
      final TranskripModel transkripModel = await apiService.getTranskrip();
      return Right(transkripModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
