// lib/features/transkrip/domain/usecases/get_transkrip_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/domain/repositories/transkrip_repository.dart';

class GetTranskripUseCase implements UseCase<Transkrip, String> {
  final TranskripRepository repository;

  GetTranskripUseCase(this.repository);

  @override
  Future<Either<Failure, Transkrip>> call(String params) async {
    // params di sini adalah nrm
    return await repository.getTranskrip(params);
  }
}
