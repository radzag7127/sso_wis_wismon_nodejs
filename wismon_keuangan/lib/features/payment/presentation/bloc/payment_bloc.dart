import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/get_payment_history_usecase.dart';
import '../../domain/usecases/get_payment_summary_usecase.dart';
import '../../domain/usecases/get_transaction_detail_usecase.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetPaymentHistoryUseCase getPaymentHistoryUseCase;
  final GetPaymentSummaryUseCase getPaymentSummaryUseCase;
  final GetTransactionDetailUseCase getTransactionDetailUseCase;

  PaymentBloc({
    required this.getPaymentHistoryUseCase,
    required this.getPaymentSummaryUseCase,
    required this.getTransactionDetailUseCase,
  }) : super(const PaymentInitial()) {
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
    on<LoadPaymentSummaryEvent>(_onLoadPaymentSummary);
    on<LoadTransactionDetailEvent>(_onLoadTransactionDetail);
    on<RefreshPaymentDataEvent>(_onRefreshPaymentData);
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    // Keep current history for a better refresh experience
    List<PaymentHistoryItem> currentHistory = [];
    if (state is PaymentHistoryLoaded) {
      currentHistory = (state as PaymentHistoryLoaded).historyItems;
    }

    // Show loading indicator only on initial load
    if (event.page == 1) {
      emit(const PaymentLoading());
    }

    final result = await getPaymentHistoryUseCase(
      PaymentHistoryParams(page: event.page, limit: event.limit),
    );

    await result.fold(
      (failure) async =>
          emit(PaymentError(message: _mapFailureToMessage(failure))),
      (newHistoryItems) async {
        final summaryResult = await getPaymentSummaryUseCase(NoParams());
        await summaryResult.fold(
          (summaryFailure) async => emit(
            PaymentHistoryLoaded(
              historyItems: event.page == 1
                  ? newHistoryItems
                  : (currentHistory + newHistoryItems),
            ),
          ),
          (summary) async => emit(
            PaymentHistoryLoaded(
              historyItems: event.page == 1
                  ? newHistoryItems
                  : (currentHistory + newHistoryItems),
              summary: summary,
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSummaryWithHistory(
    List<PaymentHistoryItem> historyItems,
    Emitter<PaymentState> emit,
  ) async {
    final summaryResult = await getPaymentSummaryUseCase(NoParams());

    await summaryResult.fold(
      (failure) async => emit(PaymentHistoryLoaded(historyItems: historyItems)),
      (summary) async => emit(
        PaymentHistoryLoaded(historyItems: historyItems, summary: summary),
      ),
    );
  }

  Future<void> _onLoadPaymentSummary(
    LoadPaymentSummaryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());

    final result = await getPaymentSummaryUseCase(NoParams());

    await result.fold(
      (failure) async =>
          emit(PaymentError(message: _mapFailureToMessage(failure))),
      (summary) async => emit(PaymentSummaryLoaded(summary: summary)),
    );
  }

  Future<void> _onLoadTransactionDetail(
    LoadTransactionDetailEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());

    final result = await getTransactionDetailUseCase(
      TransactionDetailParams(transactionId: event.transactionId),
    );

    await result.fold(
      (failure) async =>
          emit(PaymentError(message: _mapFailureToMessage(failure))),
      (transactionDetail) async =>
          emit(TransactionDetailLoaded(transactionDetail: transactionDetail)),
    );
  }

  Future<void> _onRefreshPaymentData(
    RefreshPaymentDataEvent event,
    Emitter<PaymentState> emit,
  ) async {
    final result = await getPaymentHistoryUseCase(
      const PaymentHistoryParams(page: 1, limit: 20),
    );
    add(const LoadPaymentHistoryEvent());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      default:
        return 'Unexpected error occurred';
    }
  }
}
