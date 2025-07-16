abstract class RegistrationEvent {
  const RegistrationEvent();
}

class VerifyIdentityEvent extends RegistrationEvent {
  final String nama;
  final String nim;
  final String nrm;
  final String tglahir;

  const VerifyIdentityEvent({
    required this.nama,
    required this.nim,
    required this.nrm,
    required this.tglahir,
  });
}

class CreateAccountEvent extends RegistrationEvent {
  final String nama;
  final String nim;
  final String nrm;
  final String tglahir;
  final String username;
  final String email;
  final String password;

  const CreateAccountEvent({
    required this.nama,
    required this.nim,
    required this.nrm,
    required this.tglahir,
    required this.username,
    required this.email,
    required this.password,
  });
}
