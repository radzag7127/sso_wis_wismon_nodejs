import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await checkAuthStatusUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (kDebugMode) {
      print('🔑 [AuthBloc] Login requested for: ${event.namamNim}');
    }
    
    emit(const AuthLoading());

    final result = await loginUseCase(
      LoginParams(namamNim: event.namamNim, nrm: event.nrm),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [AuthBloc] Login failed: ${_mapFailureToMessage(failure)}');
        }
        emit(AuthError(message: _mapFailureToMessage(failure)));
      },
      (user) {
        if (kDebugMode) {
          print('✅ [AuthBloc] Login successful! User: ${user.namam}');
          print('🚀 [AuthBloc] Emitting AuthAuthenticated state');
        }
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case AuthFailure:
        return (failure as AuthFailure).message;
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      default:
        return 'Unexpected error occurred';
    }
  }
}
