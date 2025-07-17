// lib/features/krs/domain/usecases/get_krs.dart
import 'package:equatable/equatable.dart';
import '../entities/krs.dart';
import '../repositories/krs_repository.dart';

// --- PERUBAHAN DI SINI ---
// Use case sekarang menerima KrsParams yang berisi token dan semester
class GetKrs {
  final KrsRepository repository;
  GetKrs(this.repository);

  Future<List<Krs>> call(KrsParams params) =>
      repository.getKrs(params.token, params.semester);
}

// Kelas untuk membungkus parameter yang dibutuhkan
class KrsParams extends Equatable {
  final String token;
  final String semester;

  const KrsParams({required this.token, required this.semester});

  @override
  List<Object> get props => [token, semester];
}
// -------------------------