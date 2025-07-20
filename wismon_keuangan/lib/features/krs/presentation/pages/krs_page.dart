// File: lib/features/krs/presentation/pages/krs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/krs.dart';
import '../bloc/krs_bloc.dart';

class KrsPage extends StatefulWidget {
  const KrsPage({super.key});

  @override
  State<KrsPage> createState() => _KrsPageState();
}

class _KrsPageState extends State<KrsPage> {
  // Hanya satu state untuk semester yang dipilih
  int _selectedSemester = 1;

  final List<int> _semesters = List.generate(14, (index) => index + 1);

  // Fungsi untuk mengambil data dari BLoC
  void _fetchData() {
    // Logika untuk menentukan jenis semester secara otomatis
    // Jika semester ganjil (1, 3, 5, ...), jenisSemester = 1 (Ganjil)
    // Jika semester genap (2, 4, 6, ...), jenisSemester = 2 (Genap)
    final int jenisSemester = (_selectedSemester % 2 == 0) ? 2 : 1;

    context.read<KrsBloc>().add(
      FetchKrsData(semesterKe: _selectedSemester, jenisSemester: jenisSemester),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Ambil data untuk semester 1 saat halaman pertama kali dibuka
        final int initialJenisSemester = (_selectedSemester % 2 == 0) ? 2 : 1;
        return di.sl<KrsBloc>()..add(
          FetchKrsData(
            semesterKe: _selectedSemester,
            jenisSemester: initialJenisSemester,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kartu Rencana Studi'),
          backgroundColor: const Color(0xFF135EA2),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: BlocBuilder<KrsBloc, KrsState>(
                builder: (context, state) {
                  if (state is KrsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is KrsLoaded) {
                    return _buildKrsContent(context, state.krs);
                  } else if (state is KrsError) {
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
        ),
        items: _semesters.map((int value) {
          // Menampilkan keterangan Ganjil/Genap di dropdown
          final String jenis = (value % 2 == 0) ? 'Genap' : 'Ganjil';
          return DropdownMenuItem<int>(
            value: value,
            child: Text('Semester $value - $jenis'),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedSemester = newValue;
            });
            _fetchData(); // Panggil fungsi untuk mengambil data
          }
        },
      ),
    );
  }

  Widget _buildKrsContent(BuildContext context, Krs krs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semester ${krs.semesterKe} - ${krs.jenisSemester}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'T.A. ${krs.tahunAjaran}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Text(
                'Total SKS: ${krs.totalSks}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: krs.mataKuliah.length,
            itemBuilder: (context, index) {
              final course = krs.mataKuliah[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF135EA2).withOpacity(0.1),
                    child: Text(
                      course.sks.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF135EA2),
                      ),
                    ),
                  ),
                  title: Text(course.namaMataKuliah),
                  subtitle: Text(
                    'Kode: ${course.kodeMataKuliah}${course.kelas != null ? " - Kelas: ${course.kelas}" : ""}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
