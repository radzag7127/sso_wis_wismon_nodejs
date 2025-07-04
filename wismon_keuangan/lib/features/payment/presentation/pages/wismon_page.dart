import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/payment/domain/entities/payment.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_event.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_state.dart';
import 'package:wismon_keuangan/features/payment/presentation/pages/transaction_detail_page.dart';

class WismonPage extends StatefulWidget {
  const WismonPage({super.key});

  @override
  State<WismonPage> createState() => _WismonPageState();
}

class _WismonPageState extends State<WismonPage> with RouteAware {
  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? currentRoute = ModalRoute.of(context);
    if (currentRoute is PageRoute) {
      di.sl<RouteObserver<PageRoute>>().subscribe(this, currentRoute);
    }
  }

  @override
  void dispose() {
    di.sl<RouteObserver<PageRoute>>().unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<PaymentBloc>().add(const RefreshPaymentDataEvent());
  }

  void _loadPaymentData() {
    context.read<PaymentBloc>().add(const LoadPaymentHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 1,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading && state is! PaymentHistoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentHistoryLoaded) {
            return _buildPaymentContent(
              context,
              state.historyItems,
              state.summary,
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildPaymentContent(
    BuildContext context,
    List<PaymentHistoryItem> historyItems,
    PaymentSummary? summary,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PaymentBloc>().add(const RefreshPaymentDataEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (summary != null) _buildPaymentSummary(context, summary),
            const SizedBox(height: 24),
            _buildPaymentHistory(context, historyItems),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, PaymentSummary summary) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rekapitulasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              context,
              'Total Pembayaran',
              currencyFormat.format(summary.totalPembayaran),
            ),
            const Divider(height: 24),
            ...summary.breakdown.entries.map(
              (entry) => _buildSummaryRow(
                context,
                entry.key,
                currencyFormat.format(entry.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(
    BuildContext context,
    List<PaymentHistoryItem> historyItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Pembayaran',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (historyItems.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historyItems.length,
            itemBuilder: (context, index) =>
                _buildTransactionCard(context, historyItems[index]),
          )
        else
          _buildEmptyHistory(context),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, PaymentHistoryItem item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailPage(transactionId: item.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: Colors.blue[600]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.tanggal,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(item.jumlah),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${item.txId}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Payment History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any payment records yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Unable to load payment data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadPaymentData(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
