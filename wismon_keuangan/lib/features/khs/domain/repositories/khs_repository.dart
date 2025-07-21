// lib/features/khs/domain/repositories/khs_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/khs.dart';

abstract class KhsRepository {
  Future<Either<Failure, Khs>> getKhs(int semesterKe);
}
