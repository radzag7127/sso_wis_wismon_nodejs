import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment/payment_bloc.dart';
import '../bloc/payment/payment_event.dart';
import '../bloc/payment/payment_state.dart';
import '../models/payment.dart';
import 'transaction_detail_page.dart';
import '../main.dart';

class WismonPage extends StatefulWidget {
  const WismonPage({super.key});

  @override
  State<WismonPage> createState() => _WismonPageState();
}

// Add RouteAware mixin to detect route lifecycle events
class _WismonPageState extends State<WismonPage> with RouteAware {
  @override
  void initState() {
    super.initState();
    // Load payment data when page is initialized
    _loadPaymentData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer
    final ModalRoute? currentRoute = ModalRoute.of(context);
    if (currentRoute != null && currentRoute is PageRoute) {
      MyApp.routeObserver.subscribe(this, currentRoute);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from the route observer when disposing
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when this route is covered by another route (e.g., navigating to TransactionDetailPage)
  @override
  void didPushNext() {
    debugPrint('WismonPage: didPushNext - Page covered by another route');
  }

  // Called when the top route has been popped off, and this route shows up again
  @override
  void didPopNext() {
    debugPrint(
      'WismonPage: didPopNext - Returning to WismonPage, refreshing data',
    );
    // This is the key fix - refresh data when returning to the page
    context.read<PaymentBloc>().add(const RefreshPaymentData());
  }

  // Called when this route has been pushed
  @override
  void didPush() {
    debugPrint('WismonPage: didPush - Page has been pushed');
  }

  // Called when this route has been popped
  @override
  void didPop() {
    debugPrint('WismonPage: didPop - Page has been popped');
  }

  void _loadPaymentData() {
    // Load initial payment data
    context.read<PaymentBloc>().add(const LoadPaymentHistory());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notification action
            },
          ),
        ],
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
          } else if (state is PaymentRefreshed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment data refreshed successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Payment Summary (Rekapitulasi)
          if (summary != null) _buildPaymentSummary(context, summary),
          const SizedBox(height: 24),

          // Payment History (Riwayat Pembayaran)
          _buildPaymentHistory(context, historyItems),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, PaymentSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rekapitulasi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<PaymentBloc>().add(const RefreshPaymentData());
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Breakdown items
            ...summary.breakdown.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
              ),
            ),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  summary.totalPembayaran,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Pembayaran',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              onPressed: () {
                // Show filter options
                _showFilterDialog(context);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Transaction List
        if (historyItems.isNotEmpty)
          ...historyItems.map((item) => _buildTransactionCard(context, item))
        else
          _buildEmptyHistory(context),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, PaymentHistoryItem item) {
    Color statusColor = Colors.green;
    IconData typeIcon = Icons.school;
    Color iconBackgroundColor = Colors.blue[100]!;
    Color iconColor = Colors.blue[600]!;

    // Set icon based on payment type
    if (item.type.toLowerCase().contains('wisuda')) {
      typeIcon = Icons.school;
      iconBackgroundColor = Colors.blue[100]!;
      iconColor = Colors.blue[600]!;
    } else if (item.type.toLowerCase().contains('ijazah')) {
      typeIcon = Icons.description;
      iconBackgroundColor = Colors.purple[100]!;
      iconColor = Colors.purple[600]!;
    } else {
      typeIcon = Icons.payment;
      iconBackgroundColor = Colors.orange[100]!;
      iconColor = Colors.orange[600]!;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailPage(transactionId: item.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),

              // Transaction Info
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

              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.jumlah,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${item.txId.split('-').last}',
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
            onPressed: () {
              context.read<PaymentBloc>().add(const LoadPaymentHistory());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: const Text('Filter functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
