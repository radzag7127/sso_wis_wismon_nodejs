// lib/features/khs/presentation/pages/khs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/khs.dart';
import '../bloc/khs_bloc.dart';

class KhsPage extends StatelessWidget {
  const KhsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
  final int _selectedCourseType = 0; // 0 for Reguler, 1 for Pendek
  final int latestSemesterForStudent = 6;
  Khs? _lastLoadedKhs; // To store the last successfully loaded data

  void _onSemesterChanged(int newSemester) {
    if (newSemester >= 1 && newSemester <= latestSemesterForStudent) {
      setState(() {
        _selectedSemester = newSemester;
      });
      context.read<KhsBloc>().add(FetchKhsData(semesterKe: newSemester));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
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
          _buildFilterAndToggleSection(),
          Expanded(
            child: BlocListener<KhsBloc, KhsState>(
              listener: (context, state) {
                if (state is KhsLoaded) {
                  setState(() {
                    _lastLoadedKhs = state.khs;
                  });
                }
              },
              child: BlocBuilder<KhsBloc, KhsState>(
                builder: (context, state) {
                  if (state is KhsLoading && _lastLoadedKhs == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is KhsError) {
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

                  if (_lastLoadedKhs != null) {
                    return Stack(
                      children: [
                        _buildKhsContent(context, _lastLoadedKhs!),
                        if (state is KhsLoading)
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
      bottomNavigationBar: _lastLoadedKhs != null
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
          const Text(
            'Pilih Semester',
            style: TextStyle(
              color: Color(0xFF545556),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
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
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKhsContent(BuildContext context, Khs khs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      child: Column(
        children: [
          _RekapitulasiCard(rekap: khs.rekapitulasi),
          const SizedBox(height: 24),
          _MataKuliahList(courses: khs.mataKuliah),
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
    required this.onChanged,
    required this.latestSemester,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> semesterLabels = List.generate(
      latestSemester,
      (index) => 'Semester ${index + 1}',
    );

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
          final semester = int.tryParse(newValue.replaceAll('Semester ', ''));
          if (semester != null) {
            onChanged(semester);
          }
        }
      },
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

class _RekapitulasiCard extends StatelessWidget {
  final Rekapitulasi rekap;

  const _RekapitulasiCard({required this.rekap});

  @override
  Widget build(BuildContext context) {
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

class _MataKuliahList extends StatelessWidget {
  final List<KhsCourse> courses;

  const _MataKuliahList({required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: Text("Tidak ada data mata kuliah untuk semester ini."),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _MataKuliahTile(course: courses[index]);
      },
    );
  }
}

class _MataKuliahTile extends StatelessWidget {
  final KhsCourse course;

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
