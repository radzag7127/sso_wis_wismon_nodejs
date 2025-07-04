import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String namam;
  final String nrm;
  final String? email;
  final String? phone;

  const User({required this.namam, required this.nrm, this.email, this.phone});

  @override
  List<Object?> get props => [namam, nrm, email, phone];
}
