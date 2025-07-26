import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/payment/presentation/pages/wismon_page.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/pages/transkrip_page.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_event.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_state.dart';
import 'package:wismon_keuangan/features/payment/presentation/components/payment_summary_card.dart';
import 'package:wismon_keuangan/features/payment/domain/entities/payment.dart';
import '../bloc/beranda_bloc.dart';
import '../bloc/beranda_event.dart';
import '../bloc/beranda_state.dart';
import '../../domain/entities/beranda.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> with WidgetsBindingObserver {
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startCarouselTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopCarouselTimer();
        break;
      case AppLifecycleState.detached:
        _stopCarouselTimer();
        break;
      case AppLifecycleState.hidden:
        _stopCarouselTimer();
        break;
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_carouselController.hasClients) {
        final nextIndex =
            (_currentCarouselIndex + 1) %
            3; // 3 dummy announcements - loops back to start
        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopCarouselTimer() {
    _carouselTimer?.cancel();
  }

  Future<void> _openArticleUrl(String? articleUrl) async {
    if (articleUrl == null || articleUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link artikel tidak tersedia'),
          backgroundColor: Color(0xFF135EA2),
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(articleUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $articleUrl');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getServiceIcon(String serviceId) {
    switch (serviceId) {
      case 'repository':
        return Icons.library_books;
      case 'jurnal_whn':
        return Icons.article;
      case 'e_library':
        return Icons.account_balance;
      case 'e_resources':
        return Icons.computer;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = di.sl<BerandaBloc>();
        // Always start with a refresh to ensure fresh data
        bloc.add(const RefreshBerandaDataEvent());
        return bloc;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocBuilder<BerandaBloc, BerandaState>(
                  builder: (context, state) {
                    if (state is BerandaLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF135EA2),
                          ),
                        ),
                      );
                    } else if (state is BerandaError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<BerandaBloc>().add(
                                  const FetchBerandaDataEvent(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF207BB5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Coba Lagi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (state is BerandaLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<BerandaBloc>().add(
                            const RefreshBerandaDataEvent(),
                          );
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildHeroCarousel(state.data.announcements),
                              const SizedBox(height: 24),
                              _buildLibraryServices(state.data.libraryServices),
                              const SizedBox(height: 24),
                              _buildPaymentSummary(state.data.payment),
                              const SizedBox(height: 24),
                              _buildTranscriptSummary(state.data.transcript),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 36,
            child: SvgPicture.asset(
              'wira-husada-nusantara-homepage.svg',
              fit: BoxFit.contain,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                _showSettingsBottomSheet(context);
              },
              icon: const Icon(
                Icons.settings,
                color: Color(0xFF121212),
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(List<AnnouncementData> announcements) {
    // TODO: Replace with API data when backend is ready
    final dummyAnnouncements = [
      const AnnouncementData(
        id: '1',
        title: 'Gedung Baru WHN',
        description:
            'Peresmian gedung baru untuk fasilitas belajar mengajar yang modern dan nyaman.',
        imageUrl: 'https://picsum.photos/seed/1/800/600',
        articleUrl: 'https://wira-husada-nusantara.ac.id/news/1',
        status: 'active',
        createdAt: '2025-01-20T00:00:00.000Z',
      ),
      const AnnouncementData(
        id: '2',
        title: 'Seminar Kesehatan Nasional',
        description:
            'Jangan lewatkan seminar nasional "Inovasi dalam Penanganan Covid-29" tanggal 10 Juli 2025.',
        imageUrl: 'https://picsum.photos/seed/2/800/600',
        articleUrl: 'https://wira-husada-nusantara.ac.id/news/2',
        status: 'active',
        createdAt: '2025-01-19T00:00:00.000Z',
      ),
      const AnnouncementData(
        id: '3',
        title: 'Pendaftaran Mahasiswa Baru',
        description:
            'Periode pendaftaran mahasiswa baru telah dibuka! Dapatkan informasi lengkap di website resmi.',
        imageUrl: 'https://picsum.photos/seed/3/800/600',
        articleUrl: 'https://wira-husada-nusantara.ac.id/news/3',
        status: 'active',
        createdAt: '2025-01-18T00:00:00.000Z',
      ),
    ];

    final displayAnnouncements = dummyAnnouncements;

    if (displayAnnouncements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Start auto-scroll timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCarouselTimer();
    });

    return Container(
      height: 258,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            PageView.builder(
              controller: _carouselController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
                // Restart timer when page changes (either auto or manual)
                _startCarouselTimer();
              },
              itemCount: displayAnnouncements.length,
              itemBuilder: (context, index) {
                return _buildCarouselItem(displayAnnouncements[index]);
              },
            ),

            // Navigation dots
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: displayAnnouncements.asMap().entries.map((entry) {
                  int index = entry.key;
                  return GestureDetector(
                    onTap: () {
                      _carouselController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      // Restart the timer when user manually navigates
                      _startCarouselTimer();
                    },
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentCarouselIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(AnnouncementData announcement) {
    return GestureDetector(
      onTap: () => _openArticleUrl(announcement.articleUrl),
      child: Container(
        decoration: BoxDecoration(
          image: announcement.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(announcement.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image loading error by showing gradient fallback
                    debugPrint(
                      'Failed to load image: ${announcement.imageUrl}',
                    );
                  },
                )
              : null,
          gradient: announcement.imageUrl == null
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF207BB5), Color(0xFF135EA2)],
                )
              : null,
        ),
        child: Stack(
          children: [
            // Dark overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFBFBFB),
                      letterSpacing: -0.16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE7E7E7),
                      letterSpacing: -0.12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryServices(List<LibraryServiceData> libraryServices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(
            title: "Layanan Perpustakaan",
            actionText: "Lihat Semua",
            onActionTap: () {
              // TODO: Navigate to library services
            },
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 9,
              mainAxisSpacing: 12,
            ),
            itemCount: libraryServices.length,
            itemBuilder: (context, index) {
              return _buildLibraryServiceCard(libraryServices[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryServiceCard(LibraryServiceData service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (service.status == "coming_soon") {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur segera hadir!'),
                  backgroundColor: Color(0xFF135EA2),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getServiceIcon(service.id),
                  size: 40,
                  color: const Color(0xFF1C1D1F),
                ),
                const SizedBox(height: 8),
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1D1F),
                    letterSpacing: -0.16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(PaymentSummaryData? payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(
            title: "Rekap Biaya Kuliah",
            actionText: "Lihat Detail",
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WismonPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          // Use PaymentBloc for the actual payment data (same as wismon_page.dart)
          BlocProvider(
            create: (context) {
              final bloc = di.sl<PaymentBloc>();
              // Use refresh event to ensure fresh data load
              bloc.add(const RefreshPaymentDataEvent());
              return bloc;
            },
            child: BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                if (state is PaymentLoading) {
                  return const Center(
                    child: SizedBox(
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF135EA2),
                        ),
                      ),
                    ),
                  );
                }

                if (state is PaymentSummaryLoaded) {
                  return _buildPaymentSummaryCards(state.summary);
                }

                if (state is PaymentError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Error loading payment data: ${state.message}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Same logic as wismon_page.dart _buildPaymentSummary method
  Widget _buildPaymentSummaryCards(PaymentSummary summary) {
    // Map database payment types to user-friendly names
    const paymentTypeMapping = {
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'Tidak ada data pembayaran tersedia',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<Widget> cardRows = [];
    for (int i = 0; i < filteredBreakdown.length; i += 2) {
      final item1 = filteredBreakdown[i];
      final card1 = Expanded(
        child: PaymentSummaryCard(
          title: paymentTypeMapping[item1.key]!,
          amount: item1.value,
        ),
      );

      final rowChildren = <Widget>[card1];

      if (i + 1 < filteredBreakdown.length) {
        final item2 = filteredBreakdown[i + 1];
        final card2 = Expanded(
          child: PaymentSummaryCard(
            title: paymentTypeMapping[item2.key]!,
            amount: item2.value,
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

  Widget _buildTranscriptSummary(TranscriptSummaryData? transcript) {
    if (transcript == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(
            title: "Transkrip Nilai",
            actionText: "Lihat Detail",
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TranskripPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTranscriptCard(
                  "Total SKS",
                  transcript.totalSks.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTranscriptCard(
                  "Total Bobot",
                  transcript.totalBobot.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTranscriptCard(
                  "IP Kumulatif",
                  transcript.ipKumulatif.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1D1F),
                letterSpacing: -0.12,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1D1F),
            letterSpacing: -0.16,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF135EA2),
              letterSpacing: -0.14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pengaturan Aplikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kelola pengaturan dan preferensi aplikasi Anda di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur pengaturan akan segera tersedia'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF207BB5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Pengaturan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
