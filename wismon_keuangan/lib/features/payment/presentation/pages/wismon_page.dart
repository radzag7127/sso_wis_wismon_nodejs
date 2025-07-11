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
  List<PaymentHistoryItem>? _historyItems;
  List<PaymentHistoryItem> _filteredHistoryItems = [];
  PaymentSummary? _paymentSummary;
  // TODO: Fetch from API - These will be replaced by actual API data
  final List<Map<String, String>> _paymentTypes = [
    {'kode': 'all', 'nama': 'Semua Jenis Pembayaran'},
    {'kode': 'SPP', 'nama': 'SPP'},
    {'kode': 'SWP', 'nama': 'SWP'},
    {
      'kode': 'Pendaftaran Mahasiswa Baru',
      'nama': 'Pendaftaran Mahasiswa Baru',
    },
    {'kode': 'Praktek Rumah Sakit', 'nama': 'Praktek Rumah Sakit'},
    {'kode': 'Seragam', 'nama': 'Seragam'},
    {'kode': 'Wisuda', 'nama': 'Wisuda'},
    {'kode': 'KTI dan Wisuda', 'nama': 'KTI dan Wisuda'},
  ];
  String _selectedPaymentTypeCode = 'all';

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
    context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
  }

  void _loadPaymentData() {
    // Clear existing data
    setState(() {
      _historyItems = null;
      _paymentSummary = null;
    });
    context.read<PaymentBloc>().add(const LoadPaymentHistoryEvent());
    context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
  }

  void _filterHistoryItems() {
    if (_historyItems == null) {
      _filteredHistoryItems = [];
      return;
    }
    if (_selectedPaymentTypeCode == 'all') {
      _filteredHistoryItems = List.from(_historyItems!);
    } else {
      _filteredHistoryItems = _historyItems!
          .where((item) => item.type == _selectedPaymentTypeCode)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<PaymentBloc, PaymentState>(
              listener: (context, state) {
                if (state is PaymentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is PaymentHistoryLoaded) {
                  setState(() {
                    _historyItems = state.historyItems;
                    _filterHistoryItems();
                  });
                } else if (state is PaymentSummaryLoaded) {
                  setState(() {
                    _paymentSummary = state.summary;
                  });
                }
              },
              builder: (context, state) {
                if (state is PaymentLoading && _historyItems == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_historyItems != null) {
                  return _buildPaymentContent(
                    context,
                    _historyItems!,
                    _paymentSummary,
                  );
                }

                return _buildEmptyState(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF135EA2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Status bar height
          SizedBox(height: MediaQuery.of(context).padding.top),
          // Header content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF135EA2),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                // Title
                const Text(
                  'Biaya Kuliah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.18,
                  ),
                ),
                // Right placeholder (to balance the layout)
                const SizedBox(width: 40, height: 40),
              ],
            ),
          ),
        ],
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
        context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(context),
              const SizedBox(height: 20),
              if (summary != null) ...[
                _buildPaymentSummary(context, summary),
                const SizedBox(height: 20),
              ],
              Container(height: 1, color: const Color(0xFFE7E7E7)),
              const SizedBox(height: 16),
              _buildPaymentHistory(context, _filteredHistoryItems),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Pembayaran',
          style: TextStyle(
            color: Color(0xFF1C1D1F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaymentTypeCode,
          onChanged: (String? newValue) {
            setState(() {
              _selectedPaymentTypeCode = newValue!;
              _filterHistoryItems();
            });
          },
          items: _paymentTypes.map<DropdownMenuItem<String>>((
            Map<String, String> type,
          ) {
            return DropdownMenuItem<String>(
              value: type['kode'],
              child: Text(
                type['nama']!,
                style: const TextStyle(
                  color: Color(0xFF545556),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.14,
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(
    BuildContext context,
    List<PaymentHistoryItem> historyItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (historyItems.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historyItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailPage(transactionId: item.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.type,
                    style: const TextStyle(
                      color: Color(0xFF121315),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Transaction ID Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5DCFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.txId,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF323335),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.78,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Amount
                      Text(
                        currencyFormat.format(item.jumlah),
                        style: const TextStyle(
                          color: Color(0xFF858586),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(item.tanggal),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF858586),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.09,
                  ),
                ),
                Text(
                  _formatYear(item.tanggal),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF858586),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.09,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      // Assuming the date format is consistent with your backend
      // You might need to adjust this based on your actual date format
      final parts = dateString.split(' ');
      if (parts.length >= 2) {
        return '${parts[0]} ${parts[1]}';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _formatYear(String dateString) {
    try {
      // Extract year from date string
      final parts = dateString.split(' ');
      if (parts.length >= 3) {
        return parts[2];
      }
      return DateTime.now().year.toString();
    } catch (e) {
      return DateTime.now().year.toString();
    }
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
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
    );
  }

  Widget _buildPaymentSummary(BuildContext context, PaymentSummary summary) {
    // Map database payment types to user-friendly names
    final paymentTypeMapping = {
      'SPP': 'SPP',
      'SWP': 'SWP',
      'Pendaftaran Mahasiswa Baru': 'Pendaftaran Mahasiswa Baru',
      'Praktek Rumah Sakit': 'Praktek Rumah Sakit',
      'Seragam': 'Seragam',
      'Wisuda': 'Wisuda',
      'KTI dan Wisuda': 'KTI dan Wisuda',
    };

    // Filter summary to only show what's in the mapping and has a value > 0
    final filteredBreakdown = summary.breakdown.entries
        .where(
          (entry) =>
              paymentTypeMapping.containsKey(entry.key) && entry.value > 0,
        )
        .toList();

    if (filteredBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> cardRows = [];
    for (int i = 0; i < filteredBreakdown.length; i += 2) {
      final item1 = filteredBreakdown[i];
      final card1 = Expanded(
        child: _buildSummaryBox(
          context,
          paymentTypeMapping[item1.key]!,
          item1.value,
        ),
      );

      final rowChildren = <Widget>[card1];

      if (i + 1 < filteredBreakdown.length) {
        final item2 = filteredBreakdown[i + 1];
        final card2 = Expanded(
          child: _buildSummaryBox(
            context,
            paymentTypeMapping[item2.key]!,
            item2.value,
          ),
        );
        rowChildren.addAll([const SizedBox(width: 12), card2]);
      }

      cardRows.add(Row(children: rowChildren));
      if (i + 2 < filteredBreakdown.length) {
        cardRows.add(const SizedBox(height: 12));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: cardRows);
  }

  Widget _buildSummaryBox(BuildContext context, String title, double amount) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1C1D1F),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: Color(0xFFE7E7E7),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: const Color(0xFFFAFAFA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      color: Color(0xFF121111),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
