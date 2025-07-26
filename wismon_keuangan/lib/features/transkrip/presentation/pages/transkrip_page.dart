// lib/features/transkrip/presentation/pages/transkrip_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_bloc.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

class TranskripPage extends StatefulWidget {
  const TranskripPage({super.key});

  @override
  State<TranskripPage> createState() => _TranskripPageState();
}

class _TranskripPageState extends State<TranskripPage> {
  String selectedSemester = 'Semua Semester';
  final List<String> semesterOptions = [
    'Semua Semester',
    'Genap 2024/2025',
    'Ganjil 2024/2025',
    'Genap 2023/2024',
    'Ganjil 2023/2024',
    'Genap 2022/2023',
    'Ganjil 2022/2023',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TranskripBloc>()..add(const FetchTranskrip()),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocBuilder<TranskripBloc, TranskripState>(
                  builder: (context, state) {
                    if (state is TranskripLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF135EA2),
                          ),
                        ),
                      );
                    } else if (state is TranskripLoaded) {
                      return _buildContent(context, state.transkrip);
                    } else if (state is TranskripError) {
                      return _buildErrorState(context, state.message);
                    }
                    return const Center(
                      child: Text("Memuat data transkrip..."),
                    );
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
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF135EA2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF121212),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            const Text(
              'Transkrip Nilai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFBFBFB),
                letterSpacing: -0.18,
              ),
            ),
            const SizedBox(width: 40), // Spacer for center alignment
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Transkrip transkrip) {
    final filteredCourses = _filterCoursesBySemester(transkrip.courses);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSemesterDropdown(),
                const SizedBox(height: 20),
                _buildSummaryCards(transkrip, filteredCourses),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFE7E7E7), height: 1),
                const SizedBox(height: 20),
                _buildCourseList(filteredCourses),
              ],
            ),
          ),
        ),
        _buildDownloadButton(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<TranskripBloc>().add(const FetchTranskrip());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135EA2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Semester',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF121315),
            letterSpacing: -0.14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSemester,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF121212),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF545556),
                letterSpacing: -0.14,
              ),
              items: semesterOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedSemester = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Transkrip transkrip, List<Course> filteredCourses) {
    final totalSks = filteredCourses.fold<int>(
      0,
      (sum, course) => sum + course.sks,
    );
    final totalBobot = filteredCourses.fold<double>(
      0.0,
      (sum, course) => sum + ((course.bobotNilai ?? 0) * course.sks),
    );
    final ipk = totalSks > 0 ? totalBobot / totalSks : 0.0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(title: 'Total SKS', value: totalSks.toString()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Bobot',
            value: totalBobot.toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'IP Kumulatif',
            value: ipk.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseList(List<Course> courses) {
    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Tidak ada data mata kuliah untuk semester yang dipilih',
            style: TextStyle(fontSize: 14, color: Color(0xFF545556)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableHeader(),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return _CourseTile(course: courses[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 64,
            child: Text(
              'Semester',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nama Matakuliah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 37,
            child: Text(
              'SKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 37,
            child: Text(
              'Nilai',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 37,
            child: Text(
              'Bobot',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFBFB),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      child: ElevatedButton(
        onPressed: () => _showDownloadModal(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135EA2),
          foregroundColor: const Color(0xFFFBFBFB),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Download Transkrip Nilai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.16,
          ),
        ),
      ),
    );
  }

  void _showDownloadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Column(
                    children: [
                      Text(
                        'Download Transkrip Nilai',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF121212),
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Apakah Anda yakin untuk download\ntranskrip nilai Anda?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF545556),
                          letterSpacing: -0.14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF858586),
                            foregroundColor: const Color(0xFFFBFBFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fitur download sedang dalam pengembangan',
                                ),
                                backgroundColor: Color(0xFF135EA2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF135EA2),
                            foregroundColor: const Color(0xFFFBFBFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Course> _filterCoursesBySemester(List<Course> courses) {
    if (selectedSemester == 'Semua Semester') {
      return courses;
    }

    // Simple filtering logic - can be enhanced based on actual semester data structure
    return courses;
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1D1F),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;

  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        children: [
          // Semester number with circular background
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                course.semesterKe.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1D1F),
                  letterSpacing: -0.14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Course info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.namamk,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1D1F),
                    letterSpacing: -0.12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                      text: '2020',
                      backgroundColor: const Color(0xFF135EA2),
                      textColor: const Color(0xFFFBFBFB),
                    ),
                    const SizedBox(width: 4),
                    _InfoChip(
                      text: 'BD.5.101',
                      backgroundColor: const Color(0xFFA6DCFF),
                      textColor: const Color(0xFF121212),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // SKS, Nilai, Bobot
          Row(
            children: [
              SizedBox(
                width: 37,
                child: Text(
                  course.sks.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                    letterSpacing: -0.14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 37,
                child: Text(
                  course.nilai ?? 'null',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                    letterSpacing: -0.14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 37,
                child: Text(
                  (course.bobotNilai ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                    letterSpacing: -0.14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _InfoChip({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1,
          height: 16 / 9,
        ),
      ),
    );
  }
}
