// lib/features/krs/presentation/bloc/krs_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/krs_repository.dart';
import '../../domain/usecases/get_krs.dart';
import 'krs_state.dart';

class KrsCubit extends Cubit<KrsState> {
  final KrsRepository krsRepository;
  final GetKrs getKrs;

  KrsCubit({required this.krsRepository, required this.getKrs})
    : super(KrsInitial());

  Future<void> fetchInitialData(String token) async {
    emit(KrsLoading());
    try {
      final semesters = await krsRepository.getAvailableSemesters(token);
      if (semesters.isEmpty) {
        emit(
          const KrsLoaded(
            krsList: [],
            availableSemesters: [],
            selectedSemester: '',
            totalSks: 0,
          ),
        );
        return;
      }

      final latestSemester = semesters.first;
      final krsResult = await getKrs(
        KrsParams(token: token, semester: latestSemester),
      );
      final totalSks = krsResult.fold(0, (sum, item) => sum + item.sks);

      emit(
        KrsLoaded(
          krsList: krsResult,
          availableSemesters: semesters,
          selectedSemester: latestSemester,
          totalSks: totalSks,
        ),
      );
    } catch (e) {
      emit(KrsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> fetchKrsForSemester(String token, String semester) async {
    final currentState = state;
    if (currentState is KrsLoaded) {
      // Set isLoading menjadi true untuk menampilkan loading indicator di UI
      emit(currentState.copyWith(isLoading: true));
    }

    try {
      final krsResult = await getKrs(
        KrsParams(token: token, semester: semester),
      );
      final totalSks = krsResult.fold(0, (sum, item) => sum + item.sks);

      if (currentState is KrsLoaded) {
        emit(
          currentState.copyWith(
            krsList: krsResult,
            selectedSemester: semester,
            totalSks: totalSks,
            isLoading:
                false, // Set isLoading menjadi false setelah data didapat
          ),
        );
      }
    } catch (e) {
      emit(KrsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
