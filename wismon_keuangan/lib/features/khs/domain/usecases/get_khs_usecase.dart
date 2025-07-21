// lib/features/khs/domain/usecases/get_khs_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/khs.dart';
import '../repositories/khs_repository.dart';

class GetKhsUseCase implements UseCase<Khs, KhsParams> {
  final KhsRepository repository;

  GetKhsUseCase(this.repository);

  @override
  Future<Either<Failure, Khs>> call(KhsParams params) async {
    return await repository.getKhs(params.semesterKe);
  }
}

class KhsParams extends Equatable {
  final int semesterKe;

  const KhsParams({required this.semesterKe});

  @override
  List<Object> get props => [semesterKe];
}
