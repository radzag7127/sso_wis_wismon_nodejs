// lib/features/transkrip/presentation/pages/transkrip_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_bloc.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

class TranskripPage extends StatelessWidget {
  // REVISI: Tidak perlu lagi menerima NRM di constructor
  const TranskripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // REVISI: Event yang dipanggil adalah FetchTranskrip() tanpa parameter
      create: (context) => di.sl<TranskripBloc>()..add(const FetchTranskrip()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transkrip Akademik'),
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
            return const Center(
              child: Text("Memulai untuk memuat transkrip..."),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTranskripContent(BuildContext context, Transkrip transkrip) {
    // ... (UI untuk menampilkan konten transkrip tidak perlu diubah)
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummary(context, transkrip.totalSks, transkrip.ipk),
        const SizedBox(height: 16),
        _buildCourseList(context, transkrip.courses),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, int totalSks, String ipk) {
    // ... (UI untuk summary tidak perlu diubah)
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  "Total SKS",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  totalSks.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(height: 50, width: 1, color: Colors.grey[300]),
            Column(
              children: [
                Text(
                  "IPK",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  ipk,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF135EA2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, List<Course> courses) {
    // ... (UI untuk daftar mata kuliah tidak perlu diubah)
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => const Color(0xFF135EA2).withOpacity(0.1),
          ),
          columns: const [
            DataColumn(
              label: Text(
                "Mata Kuliah",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text("SKS", style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                "Nilai",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: courses.map((course) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(course.namamk, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(course.sks.toString())),
                DataCell(Text(course.nilai ?? '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
