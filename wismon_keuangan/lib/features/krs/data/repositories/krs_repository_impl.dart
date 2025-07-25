// lib/features/krs/data/repositories/krs_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/krs.dart';
import '../../domain/repositories/krs_repository.dart';
import '../datasources/krs_remote_data_source.dart';

class KrsRepositoryImpl implements KrsRepository {
  final KrsRemoteDataSource remoteDataSource;

  KrsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Krs>> getKrs(int semesterKe) async {
    try {
      final krsModel = await remoteDataSource.getKrs(semesterKe);
      return Right(krsModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
