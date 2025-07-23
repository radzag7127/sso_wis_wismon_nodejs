// lib/features/khs/presentation/pages/khs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/khs.dart';
import '../bloc/khs_bloc.dart';

// Halaman utama yang menggabungkan semua widget
class KhsPage extends StatelessWidget {
  const KhsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Memuat data semester 1 saat halaman pertama kali dibuka
      create: (context) =>
          di.sl<KhsBloc>()..add(const FetchKhsData(semesterKe: 1)),
      child: const KhsView(),
    );
  }
}

class KhsView extends StatefulWidget {
  const KhsView({super.key});

  @override
  State<KhsView> createState() => _KhsViewState();
}

class _KhsViewState extends State<KhsView> {
  int _selectedSemester = 1;
  int _selectedCourseType = 0; // 0 untuk Reguler, 1 untuk Pendek

  void _onSemesterChanged(int newSemester) {
    setState(() {
      _selectedSemester = newSemester;
    });
    context.read<KhsBloc>().add(FetchKhsData(semesterKe: newSemester));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F7F9,
      ), // Warna latar belakang sesuai desain
      appBar: AppBar(
        title: const Text(
          'Kartu Hasil Studi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF135EA2),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Slice 1: Filter Semester & Toggle
          _buildFilterAndToggleSection(),
          Expanded(
            child: BlocBuilder<KhsBloc, KhsState>(
              builder: (context, state) {
                if (state is KhsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is KhsLoaded) {
                  return _buildKhsContent(context, state.khs);
                } else if (state is KhsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Gagal memuat data: ${state.message}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const Center(
                  child: Text("Pilih semester untuk memulai."),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Menggabungkan Filter dan Toggle dalam satu container putih
  Widget _buildFilterAndToggleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Dropdown
          const Text(
            'Pilih Semester',
            style: TextStyle(
              color: Color(0xFF545556),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _SemesterFilter(
            selectedSemester: _selectedSemester,
            onChanged: _onSemesterChanged,
          ),
          const SizedBox(height: 16),
          // Toggle Button
          _CourseTypeToggle(
            selectedIndex: _selectedCourseType,
            onTap: (index) {
              setState(() {
                _selectedCourseType = index;
                // TODO: Tambahkan logika filter di sini jika data dari API sudah mendukung
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKhsContent(BuildContext context, Khs khs) {
    // Menggabungkan semua slice menjadi satu halaman
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Slice 2: Kartu Rekapitulasi
        RekapitulasiCard(rekap: khs.rekapitulasi),
        const SizedBox(height: 24),
        // Slice 3: Daftar Mata Kuliah
        _MataKuliahList(courses: khs.mataKuliah),
      ],
    );
  }
}

// --- WIDGET-WIDGET HASIL SLICING ---

// Slice 1 (Bagian Dropdown)
class _SemesterFilter extends StatelessWidget {
  final int selectedSemester;
  final Function(int) onChanged;
  final List<int> semesters = List.generate(14, (index) => index + 1);

  _SemesterFilter({required this.selectedSemester, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final List<String> semesterLabels = semesters
        .map((s) => 'Semester $s')
        .toList();

    return DropdownButtonFormField<String>(
      value: 'Semester $selectedSemester',
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: semesterLabels.map((String label) {
        return DropdownMenuItem<String>(value: label, child: Text(label));
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          final semester =
              int.tryParse(newValue.replaceAll('Semester ', '')) ?? 1;
          onChanged(semester);
        }
      },
    );
  }
}

// Slice 1 (Bagian Toggle) - PERBAIKAN UNTUK MENGHINDARI OVERFLOW
class _CourseTypeToggle extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CourseTypeToggle({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildToggleButton(context, 'Reguler', 0)),
        Expanded(child: _buildToggleButton(context, 'Pendek', 1)),
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context, String text, int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135EA2) : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.horizontal(
            left: index == 0 ? const Radius.circular(8) : Radius.zero,
            right: index == 1 ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF135EA2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Slice 2: Kartu Rekapitulasi - PERBAIKAN LAYOUT
class RekapitulasiCard extends StatelessWidget {
  final Rekapitulasi rekap;
  const RekapitulasiCard({super.key, required this.rekap});

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Menggunakan Column dan Row untuk layout 2x2
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _RekapItem(
                title: "IP Lulus/Beban",
                value: rekap.ipSemester,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RekapItem(
                title: "IP Kumulatif Lulus/Beban",
                value: rekap.ipKumulatif,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RekapItem(
                title: "SKS Lulus/Beban",
                value: rekap.sksSemester,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RekapItem(
                title: "SKS Kumulatif Lulus/Beban",
                value: rekap.sksKumulatif,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Komponen item di dalam kartu rekapitulasi - PERBAIKAN
class _RekapItem extends StatelessWidget {
  final String title;
  final String value;
  const _RekapItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Box untuk Label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              title,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Box untuk Nilai
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            width: double.infinity,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Slice 3: Daftar Mata Kuliah (Tidak ada perubahan)
class _MataKuliahList extends StatelessWidget {
  final List<KhsCourse> courses;
  const _MataKuliahList({required this.courses});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return MataKuliahTile(course: courses[index]);
      },
    );
  }
}

// Komponen tile untuk setiap mata kuliah (Tidak ada perubahan)
class MataKuliahTile extends StatelessWidget {
  final KhsCourse course;
  const MataKuliahTile({super.key, required this.course});

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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  course.nilai,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.namaMataKuliah,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _InfoChip(text: '${course.sks} SKS'),
                      _InfoChip(text: course.kodeMataKuliah),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Komponen Chip (Tidak ada perubahan)
class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF135EA2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
