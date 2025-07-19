// lib/features/transkrip/presentation/bloc/transkrip_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/error/failures.dart'; // Pastikan import ini ada
import 'package:wismon_keuangan/features/transkrip/domain/usecases/get_transkrip_usecase.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

class TranskripBloc extends Bloc<TranskripEvent, TranskripState> {
  final GetTranskripUseCase getTranskripUseCase;

  TranskripBloc({required this.getTranskripUseCase})
    : super(TranskripInitial()) {
    on<FetchTranskrip>((event, emit) async {
      emit(TranskripLoading());
      final result = await getTranskripUseCase(event.nrm);
      result.fold(
        // --- PERUBAHAN DI SINI ---
        // Kita akan memetakan jenis kegagalan ke pesan yang lebih baik
        (failure) =>
            emit(TranskripError(message: _mapFailureToMessage(failure))),
        (transkrip) => emit(TranskripLoaded(transkrip: transkrip)),
      );
    });
  }

  // Method helper untuk mengubah Failure menjadi pesan String yang mudah dibaca
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message; // Langsung gunakan pesan dari server
    } else if (failure is NetworkFailure) {
      return 'Tidak ada koneksi internet. Silakan periksa koneksi Anda.';
    } else {
      return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.';
    }
  }
}
