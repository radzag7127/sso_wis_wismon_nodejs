// lib/features/krs/presentation/pages/krs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/krs_cubit.dart';
import '../bloc/krs_state.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;

class KrsPage extends StatelessWidget {
  final String token;
  const KrsPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<KrsCubit>()..fetchInitialData(token),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kartu Rencana Studi'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<KrsCubit, KrsState>(
          builder: (context, state) {
            if (state is KrsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is KrsError) {
              return Center(child: Text('Gagal memuat data: ${state.message}'));
            } else if (state is KrsLoaded) {
              return Column(
                children: [
                  _buildSemesterDropdown(context, state),
                  _buildTotalSks(context, state.totalSks),
                  Expanded(
                    child: state.krsList.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada mata kuliah untuk semester ini.',
                            ),
                          )
                        : _buildKrsListView(state.krsList),
                  ),
                ],
              );
            }
            return const Center(child: Text('Silakan pilih semester.'));
          },
        ),
      ),
    );
  }

  Widget _buildSemesterDropdown(BuildContext context, KrsLoaded state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: state.selectedSemester.isEmpty ? null : state.selectedSemester,
        hint: const Text('Pilih Semester'),
        isExpanded: true,
        items: state.availableSemesters.map((String semester) {
          return DropdownMenuItem<String>(
            value: semester,
            child: Text('Tahun Ajaran $semester'),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            context.read<KrsCubit>().fetchKrsForSemester(token, newValue);
          }
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSks(BuildContext context, int totalSks) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        'Total SKS: $totalSks',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildKrsListView(List<dynamic> krsList) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: krsList.length,
      itemBuilder: (context, index) {
        final matkul = krsList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColorLight,
              child: Text(
                matkul.sks.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ),
            title: Text(matkul.nama),
            subtitle: Text("Kode: ${matkul.kode}"),
          ),
        );
      },
    );
  }
}
