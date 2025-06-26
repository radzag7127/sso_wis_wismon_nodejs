import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentHistory extends PaymentEvent {
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;
  final String? type;
  final String sortBy;
  final String sortOrder;

  const LoadPaymentHistory({
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.type,
    this.sortBy = 'tanggal',
    this.sortOrder = 'desc',
  });

  @override
  List<Object?> get props => [
    page,
    limit,
    startDate,
    endDate,
    type,
    sortBy,
    sortOrder,
  ];
}

class LoadPaymentSummary extends PaymentEvent {
  const LoadPaymentSummary();
}

class LoadTransactionDetail extends PaymentEvent {
  final String transactionId;

  const LoadTransactionDetail({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class RefreshPaymentData extends PaymentEvent {
  const RefreshPaymentData();
}
