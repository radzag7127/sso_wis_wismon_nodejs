// lib/features/transkrip/presentation/pages/transkrip_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_bloc.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

class TranskripPage extends StatelessWidget {
  const TranskripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TranskripBloc>()..add(const FetchTranskrip()),
      child: const TranskripView(),
    );
  }
}

class TranskripView extends StatelessWidget {
  const TranskripView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text(
          'Transkrip Nilai',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF135EA2),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<TranskripBloc, TranskripState>(
        builder: (context, state) {
          if (state is TranskripLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TranskripLoaded) {
            return _buildTranskripContent(context, state.transkrip);
          } else if (state is TranskripError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gagal memuat data: ${state.message}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const Center(child: Text("Memuat data transkrip..."));
        },
      ),
      // Tombol Download di bagian bawah
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement download functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur download belum tersedia')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF135EA2),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Download Transkrip Nilai',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTranskripContent(BuildContext context, Transkrip transkrip) {
    // PERBAIKAN: Menghapus logika filter dan dropdown
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummary(context, transkrip),
        const SizedBox(height: 24),
        _buildCourseListHeader(context),
        _buildCourseList(
          context,
          transkrip.courses,
        ), // Langsung menampilkan semua mata kuliah
      ],
    );
  }

  Widget _buildSummary(BuildContext context, Transkrip transkrip) {
    final totalBobot = transkrip.courses.fold<double>(
      0.0,
      (sum, item) => sum + ((item.bobotNilai ?? 0) * item.sks),
    );

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total SKS',
            value: transkrip.totalSks.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Total Bobot',
            value: totalBobot.toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(title: 'IP Kumulatif', value: transkrip.ipk),
        ),
      ],
    );
  }

  Widget _buildCourseListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              'Semester',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const Expanded(
            flex: 4,
            child: Text(
              'Nama Matakuliah',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'SKS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Nilai',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Bobot',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _CourseTile(course: courses[index]);
      },
    );
  }
}

// Widget untuk kartu rangkuman (Total SKS, Bobot, IPK)
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Widget untuk setiap baris mata kuliah di dalam transkrip
class _CourseTile extends StatelessWidget {
  final Course course;
  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Semester
            Expanded(
              flex: 1,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    course.semesterKe.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nama Matakuliah & Chips
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.namamk,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _InfoChip(
                        text: '2020',
                        backgroundColor: Colors.grey[200]!,
                        textColor: Colors.grey[700]!,
                      ),
                      _InfoChip(
                        text: 'BD.5.101',
                        backgroundColor: Colors.grey[200]!,
                        textColor: Colors.grey[700]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // SKS, Nilai, Bobot
            Expanded(
              flex: 1,
              child: Text(course.sks.toString(), textAlign: TextAlign.center),
            ),
            Expanded(
              flex: 1,
              child: Text(course.nilai ?? '-', textAlign: TextAlign.center),
            ),
            Expanded(
              flex: 1,
              child: Text(
                course.bobotNilai?.toStringAsFixed(1) ?? '0.0',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk chip info
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
