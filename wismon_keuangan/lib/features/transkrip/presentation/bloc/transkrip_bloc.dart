// lib/features/transkrip/presentation/bloc/transkrip_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart'; // Import NoParams
import 'package:wismon_keuangan/features/transkrip/domain/usecases/get_transkrip_usecase.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

class TranskripBloc extends Bloc<TranskripEvent, TranskripState> {
  final GetTranskripUseCase getTranskripUseCase;

  TranskripBloc({required this.getTranskripUseCase})
    : super(TranskripInitial()) {
    on<FetchTranskrip>((event, emit) async {
      emit(TranskripLoading());

      // REVISI: Memanggil use case dengan NoParams()
      final result = await getTranskripUseCase(NoParams());

      result.fold(
        (failure) =>
            emit(TranskripError(message: _mapFailureToMessage(failure))),
        (transkrip) => emit(TranskripLoaded(transkrip: transkrip)),
      );
    });
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Tidak ada koneksi internet. Silakan periksa koneksi Anda.';
    } else {
      return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.';
    }
  }
}
