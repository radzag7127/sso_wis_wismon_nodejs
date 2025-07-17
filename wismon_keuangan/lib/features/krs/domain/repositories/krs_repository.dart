// lib/features/krs/domain/repositories/krs_repository.dart
import '../entities/krs.dart';

abstract class KrsRepository {
  // Method baru untuk mengambil daftar semester
  Future<List<String>> getAvailableSemesters(String token);

  // Method lama diubah untuk menerima semester
  Future<List<Krs>> getKrs(String token, String semester);
}
