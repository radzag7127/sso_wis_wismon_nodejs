import 'package:equatable/equatable.dart';
import '../../models/payment.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentHistoryItem> historyItems;
  final PaymentSummary? summary;

  const PaymentHistoryLoaded({required this.historyItems, this.summary});

  @override
  List<Object?> get props => [historyItems, summary];
}

class PaymentSummaryLoaded extends PaymentState {
  final PaymentSummary summary;

  const PaymentSummaryLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class TransactionDetailLoaded extends PaymentState {
  final TransactionDetail transactionDetail;

  const TransactionDetailLoaded({required this.transactionDetail});

  @override
  List<Object?> get props => [transactionDetail];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PaymentRefreshed extends PaymentState {
  final bool refreshed;

  const PaymentRefreshed({required this.refreshed});

  @override
  List<Object?> get props => [refreshed];
}
