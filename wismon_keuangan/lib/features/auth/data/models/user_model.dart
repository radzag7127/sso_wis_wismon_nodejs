import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.namam,
    required super.nrm,
    super.email,
    super.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      namam: json['namam'] ?? '',
      nrm: json['nrm'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'namam': namam, 'nrm': nrm, 'email': email, 'phone': phone};
  }
}
