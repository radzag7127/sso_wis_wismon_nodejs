// lib/features/krs/presentation/pages/krs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/krs.dart';
import '../bloc/krs_bloc.dart';

class KrsPage extends StatelessWidget {
  const KrsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<KrsBloc>()..add(const FetchKrsData(semesterKe: 1)),
      child: const KrsView(),
    );
  }
}

class KrsView extends StatefulWidget {
  const KrsView({super.key});

  @override
  State<KrsView> createState() => _KrsViewState();
}

class _KrsViewState extends State<KrsView> {
  int _selectedSemester = 1;
  final int _selectedCourseType = 0; // 0 for Reguler, 1 for Pendek
  final int latestSemesterForStudent = 6;
  Krs? _lastLoadedKrs;

  void _onSemesterChanged(int newSemester) {
    if (newSemester >= 1 && newSemester <= latestSemesterForStudent) {
      setState(() {
        _selectedSemester = newSemester;
      });
      context.read<KrsBloc>().add(FetchKrsData(semesterKe: newSemester));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text(
          'Kartu Rencana Studi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF135EA2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterAndToggleSection(),
          Expanded(
            child: BlocListener<KrsBloc, KrsState>(
              listener: (context, state) {
                if (state is KrsLoaded) {
                  setState(() {
                    _lastLoadedKrs = state.krs;
                  });
                }
              },
              child: BlocBuilder<KrsBloc, KrsState>(
                builder: (context, state) {
                  if (state is KrsLoading && _lastLoadedKrs == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is KrsError) {
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

                  if (_lastLoadedKrs != null) {
                    return Stack(
                      children: [
                        // Konten yang bisa di-scroll
                        _buildKrsContent(context, _lastLoadedKrs!),

                        // Overlay loading
                        if (state is KrsLoading)
                          Container(
                            color: Colors.black.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
                  }

                  return const Center(
                    child: Text("Pilih semester untuk memulai."),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // --- PERUBAHAN UTAMA: Bottom Navigation Bar untuk Navigasi Semester ---
      bottomNavigationBar: _lastLoadedKrs != null
          ? _SemesterNavigator(
              currentSemester: _selectedSemester,
              maxSemester: latestSemesterForStudent,
              onNavigate: _onSemesterChanged,
            )
          : null,
    );
  }

  Widget _buildFilterAndToggleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SemesterFilter(
            latestSemester: latestSemesterForStudent,
            selectedSemester: _selectedSemester,
            onChanged: _onSemesterChanged,
          ),
          const SizedBox(height: 16),
          _CourseTypeToggle(
            selectedIndex: _selectedCourseType,
            onTap: (index) {
              setState(() {
                // _selectedCourseType = index;
                // Logic for course type change can be added here
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKrsContent(BuildContext context, Krs krs) {
    // Menggunakan SingleChildScrollView agar konten bisa di-scroll
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        80.0,
      ), // Padding bawah untuk ruang navigator
      child: Column(
        children: [
          _KrsHeaderCard(krs: krs),
          const SizedBox(height: 24),
          _MataKuliahList(courses: krs.mataKuliah),
        ],
      ),
    );
  }
}

// --- WIDGET-WIDGET LAINNYA ---

class _SemesterFilter extends StatelessWidget {
  final int selectedSemester;
  final int latestSemester;
  final Function(int) onChanged;

  const _SemesterFilter({
    required this.selectedSemester,
    required this.latestSemester,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> semesters = List.generate(
      latestSemester,
      (index) => index + 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Semester',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedSemester,
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
          ),
          items: semesters.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('Semester $value'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }
}

class _SemesterNavigator extends StatelessWidget {
  final int currentSemester;
  final int maxSemester;
  final Function(int) onNavigate;

  const _SemesterNavigator({
    required this.currentSemester,
    required this.maxSemester,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = currentSemester > 1;
    final bool canGoForward = currentSemester < maxSemester;

    if (maxSemester <= 1) {
      return const SizedBox.shrink();
    }

    // --- PERUBAHAN: Widget ini sekarang akan digunakan di bottomNavigationBar ---
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 32,
            onPressed: canGoBack ? () => onNavigate(currentSemester - 1) : null,
            color: canGoBack
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.5),
          ),
          Text(
            'Semester $currentSemester',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 32,
            onPressed: canGoForward
                ? () => onNavigate(currentSemester + 1)
                : null,
            color: canGoForward
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

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

class _KrsHeaderCard extends StatelessWidget {
  final Krs krs;

  const _KrsHeaderCard({required this.krs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semester ${krs.semesterKe} (${krs.jenisSemester})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'T.A. ${krs.tahunAjaran}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total SKS', style: TextStyle(fontSize: 12)),
              Text(
                '${krs.totalSks}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MataKuliahList extends StatelessWidget {
  final List<KrsCourse> courses;

  const _MataKuliahList({required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: Text("Tidak ada mata kuliah yang diambil."),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Mata Kuliah",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            return _MataKuliahTile(course: courses[index]);
          },
        ),
      ],
    );
  }
}

class _MataKuliahTile extends StatelessWidget {
  final KrsCourse course;

  const _MataKuliahTile({required this.course});

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.namaMataKuliah,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                _InfoChip(
                  text: '${course.sks} SKS',
                  backgroundColor: const Color(0xFF0D6EFD),
                  textColor: Colors.white,
                ),
                _InfoChip(
                  text: course.kodeMataKuliah,
                  backgroundColor: const Color(0xFFD1E9FF),
                  textColor: const Color(0xFF0D6EFD),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
