import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final ApiService _apiService;

  RegistrationBloc({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(const RegistrationInitial()) {
    on<VerifyIdentityEvent>(_onVerifyIdentity);
    on<CreateAccountEvent>(_onCreateAccount);
  }

  Future<void> _onVerifyIdentity(
    VerifyIdentityEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(const RegistrationLoading());

    try {
      final response = await _apiService.verifyIdentity(
        nama: event.nama,
        nim: event.nim,
        nrm: event.nrm,
        tglahir: event.tglahir,
      );

      if (response['success'] == true) {
        emit(IdentityVerified(studentData: response['data']));
      } else {
        emit(
          RegistrationError(message: response['message'] ?? 'Verifikasi gagal'),
        );
      }
    } catch (e) {
      emit(RegistrationError(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }

  Future<void> _onCreateAccount(
    CreateAccountEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(const RegistrationLoading());

    try {
      final response = await _apiService.createAccount(
        nama: event.nama,
        nim: event.nim,
        nrm: event.nrm,
        tglahir: event.tglahir,
        username: event.username,
        email: event.email,
        password: event.password,
      );

      if (response['success'] == true) {
        emit(
          AccountCreated(
            message:
                response['message'] ??
                'Email verifikasi anda telah dikirimkan mohon segera verifikasi',
          ),
        );
      } else {
        emit(
          RegistrationError(message: response['message'] ?? 'Registrasi gagal'),
        );
      }
    } catch (e) {
      emit(RegistrationError(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }
}
