// File: lib/features/krs/presentation/bloc/krs_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart'; // Pastikan ini diimpor
import '../../domain/entities/krs.dart';
import '../../domain/usecases/get_krs_usecase.dart';

part 'krs_event.dart';
part 'krs_state.dart';

class KrsBloc extends Bloc<KrsEvent, KrsState> {
  final GetKrsUseCase getKrsUseCase;

  KrsBloc({required this.getKrsUseCase}) : super(KrsInitial()) {
    on<FetchKrsData>(_onFetchKrsData);
  }

  Future<void> _onFetchKrsData(
    FetchKrsData event,
    Emitter<KrsState> emit,
  ) async {
    emit(KrsLoading());
    final result = await getKrsUseCase(
      KrsParams(
        semesterKe: event.semesterKe,
        jenisSemester: event.jenisSemester,
      ),
    );

    result.fold(
      // PERBAIKAN: Gunakan helper function untuk mendapatkan pesan error
      (failure) => emit(KrsError(message: _mapFailureToMessage(failure))),
      (krs) => emit(KrsLoaded(krs: krs)),
    );
  }

  // PENAMBAHAN: Helper function untuk memetakan Failure ke pesan String
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      default:
        return 'Terjadi kesalahan yang tidak terduga';
    }
  }
}
