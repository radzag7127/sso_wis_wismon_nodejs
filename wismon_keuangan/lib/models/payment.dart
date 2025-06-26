class PaymentHistoryItem {
  final String id;
  final String tanggal;
  final String tanggalFull;
  final String type;
  final String jumlah;
  final String status;
  final String txId;
  final String method;
  final String methodCode;

  PaymentHistoryItem({
    required this.id,
    required this.tanggal,
    required this.tanggalFull,
    required this.type,
    required this.jumlah,
    required this.status,
    required this.txId,
    required this.method,
    required this.methodCode,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      tanggalFull: json['tanggal_full']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      jumlah: json['jumlah']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      txId: json['tx_id']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      methodCode: json['method_code']?.toString() ?? '',
    );
  }
}

class PaymentSummary {
  final String totalPembayaran;
  final Map<String, String> breakdown;

  PaymentSummary({required this.totalPembayaran, required this.breakdown});

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    // Convert all breakdown values to strings
    Map<String, String> convertedBreakdown = {};
    if (json['breakdown'] != null) {
      (json['breakdown'] as Map<String, dynamic>).forEach((key, value) {
        convertedBreakdown[key.toString()] = value?.toString() ?? '';
      });
    }

    return PaymentSummary(
      totalPembayaran: json['total_pembayaran']?.toString() ?? '',
      breakdown: convertedBreakdown,
    );
  }
}

class TransactionDetail extends PaymentHistoryItem {
  final String studentName;
  final String studentNim;
  final String studentProdi;
  final Map<String, String> paymentBreakdown;

  TransactionDetail({
    required super.id,
    required super.tanggal,
    required super.tanggalFull,
    required super.type,
    required super.jumlah,
    required super.status,
    required super.txId,
    required super.method,
    required super.methodCode,
    required this.studentName,
    required this.studentNim,
    required this.studentProdi,
    required this.paymentBreakdown,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    // Convert all payment breakdown values to strings
    Map<String, String> convertedPaymentBreakdown = {};
    if (json['payment_breakdown'] != null) {
      (json['payment_breakdown'] as Map<String, dynamic>).forEach((key, value) {
        convertedPaymentBreakdown[key.toString()] = value?.toString() ?? '';
      });
    }

    return TransactionDetail(
      id: json['id']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      tanggalFull: json['tanggal_full']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      jumlah: json['jumlah']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      txId: json['tx_id']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      methodCode: json['method_code']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      studentNim: json['student_nim']?.toString() ?? '',
      studentProdi: json['student_prodi']?.toString() ?? '',
      paymentBreakdown: convertedPaymentBreakdown,
    );
  }
}
