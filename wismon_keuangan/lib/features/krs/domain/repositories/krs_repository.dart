// File: lib/features/krs/domain/repositories/krs_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/krs.dart';

abstract class KrsRepository {
  Future<Either<Failure, Krs>> getKrs(int semesterKe, int jenisSemester);
}
