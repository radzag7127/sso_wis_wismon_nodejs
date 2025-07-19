// lib/features/transkrip/domain/repositories/transkrip_repository.dart

import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';

abstract class TranskripRepository {
  Future<Either<Failure, Transkrip>> getTranskrip();
}
