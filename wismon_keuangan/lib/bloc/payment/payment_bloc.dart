import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ApiService apiService;

  PaymentBloc({required this.apiService}) : super(const PaymentInitial()) {
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<LoadPaymentSummary>(_onLoadPaymentSummary);
    on<LoadTransactionDetail>(_onLoadTransactionDetail);
    on<RefreshPaymentData>(_onRefreshPaymentData);
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final historyItems = await apiService.getPaymentHistory(
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.type,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      // Also load summary if it's the first page
      if (event.page == 1) {
        try {
          final summary = await apiService.getPaymentSummary();
          emit(
            PaymentHistoryLoaded(historyItems: historyItems, summary: summary),
          );
        } catch (e) {
          // If summary fails, still show history
          emit(PaymentHistoryLoaded(historyItems: historyItems));
        }
      } else {
        emit(PaymentHistoryLoaded(historyItems: historyItems));
      }
    } catch (e) {
      emit(PaymentError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadPaymentSummary(
    LoadPaymentSummary event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final summary = await apiService.getPaymentSummary();
      emit(PaymentSummaryLoaded(summary: summary));
    } catch (e) {
      emit(PaymentError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadTransactionDetail(
    LoadTransactionDetail event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final transactionDetail = await apiService.getTransactionDetail(
        event.transactionId,
      );
      emit(TransactionDetailLoaded(transactionDetail: transactionDetail));
    } catch (e) {
      emit(PaymentError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRefreshPaymentData(
    RefreshPaymentData event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final refreshed = await apiService.refreshPaymentData();
      emit(PaymentRefreshed(refreshed: refreshed));

      // After refresh, reload the payment history
      add(const LoadPaymentHistory());
    } catch (e) {
      emit(PaymentError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
