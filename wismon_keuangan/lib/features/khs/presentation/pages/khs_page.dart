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
      create: (context) => di.sl<KhsBloc>(),
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
  final List<int> _semesters = List.generate(14, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<KhsBloc>().add(FetchKhsData(semesterKe: _selectedSemester));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartu Hasil Studi'),
        backgroundColor: const Color(0xFF135EA2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
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
                      padding: const EdgeInsets.all(16.0),
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: DropdownButtonFormField<int>(
        value: _selectedSemester,
        decoration: const InputDecoration(
          labelText: 'Pilih Semester',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: _semesters.map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text('Semester $value'),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedSemester = newValue;
            });
            _fetchData();
          }
        },
      ),
    );
  }

  Widget _buildKhsContent(BuildContext context, Khs khs) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSemesterHeader(context, khs),
        const SizedBox(height: 16),
        _buildRekapitulasiCard(context, khs.rekapitulasi),
        const SizedBox(height: 16),
        _buildMataKuliahList(context, khs.mataKuliah),
      ],
    );
  }

  Widget _buildSemesterHeader(BuildContext context, Khs khs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semester ${khs.semesterKe} - ${khs.jenisSemester}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'T.A. ${khs.tahunAjaran}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRekapitulasiCard(BuildContext context, Rekapitulasi rekap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rekapitulasi",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Format: Lulus / Beban",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRekapItem("IP Semester", rekap.ipSemester),
                _buildRekapItem("SKS Semester", rekap.sksSemester),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRekapItem("IP Kumulatif", rekap.ipKumulatif),
                _buildRekapItem("SKS Kumulatif", rekap.sksKumulatif),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekapItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMataKuliahList(BuildContext context, List<KhsCourse> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Daftar Mata Kuliah",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF135EA2),
                  foregroundColor: Colors.white,
                  child: Text(
                    course.nilai,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(course.namaMataKuliah),
                subtitle: Text('${course.kodeMataKuliah} - ${course.sks} SKS'),
              ),
            );
          },
        ),
      ],
    );
  }
}
