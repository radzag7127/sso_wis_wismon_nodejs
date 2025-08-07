import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiService apiService;

  PaymentRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, List<PaymentHistoryItem>>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? type,
    String sortBy = 'tanggal',
    String sortOrder = 'desc',
  }) async {
    try {
      final historyModels = await apiService.getPaymentHistory(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
        type: type,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      // Convert models to entities
      final List<PaymentHistoryItem> entities = historyModels
          .cast<PaymentHistoryItem>();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, PaymentSummary>> getPaymentSummary() async {
    try {
      final summaryModel = await apiService.getPaymentSummary();
      return Right(summaryModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, TransactionDetail>> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final detailModel = await apiService.getTransactionDetail(transactionId);
      return Right(detailModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, bool>> refreshPaymentData() async {
    try {
      final refreshed = await apiService.refreshPaymentData();
      return Right(refreshed);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
