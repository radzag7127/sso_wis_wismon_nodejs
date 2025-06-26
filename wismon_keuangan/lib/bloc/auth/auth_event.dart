import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String namamNim;
  final String nrm;

  const LoginRequested({required this.namamNim, required this.nrm});

  @override
  List<Object> get props => [namamNim, nrm];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoadProfile extends AuthEvent {
  const LoadProfile();
}
