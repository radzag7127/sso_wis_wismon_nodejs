import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String namam; // Student full name
  final String nrm; // Student registration number
  final String? nim; // Student identification number
  final String? email; // Email (optional)
  final String? phone; // Phone (optional)
  final String? tgdaftar; // Registration date
  final String? tplahir; // Birth place

  const User({
    required this.namam,
    required this.nrm,
    this.nim,
    this.email,
    this.phone,
    this.tgdaftar,
    this.tplahir,
  });

  @override
  List<Object?> get props => [namam, nrm, nim, email, phone, tgdaftar, tplahir];
}
