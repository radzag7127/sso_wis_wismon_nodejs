abstract class RegistrationState {
  const RegistrationState();
}

class RegistrationInitial extends RegistrationState {
  const RegistrationInitial();
}

class RegistrationLoading extends RegistrationState {
  const RegistrationLoading();
}

class IdentityVerified extends RegistrationState {
  final Map<String, dynamic> studentData;

  const IdentityVerified({required this.studentData});
}

class AccountCreated extends RegistrationState {
  final String message;

  const AccountCreated({required this.message});
}

class RegistrationError extends RegistrationState {
  final String message;

  const RegistrationError({required this.message});
}
