// lib/features/krs/data/repositories/krs_repository_impl.dart
import '../../domain/entities/krs.dart';
import '../../domain/repositories/krs_repository.dart';
import '../models/krs_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KrsRepositoryImpl implements KrsRepository {
  final String baseUrl;
  KrsRepositoryImpl({required this.baseUrl});

  @override
  Future<List<String>> getAvailableSemesters(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/akademik/krs-semesters'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true && body['data'] is List) {
        return List<String>.from(body['data']);
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil daftar semester.');
      }
    } else {
      throw Exception('Gagal terhubung ke server untuk mengambil semester.');
    }
  }

  @override
  Future<List<Krs>> getKrs(String token, String semester) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/akademik/krs/$semester'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true && body['data'] is List) {
        final List data = body['data'];
        // --- PERBAIKAN DI SINI ---
        // Mapping dari List<dynamic> (JSON) ke List<Krs> (Entity)
        return data.map((item) {
          final model = KrsModel.fromJson(item as Map<String, dynamic>);
          // KrsModel adalah kelas data, Krs adalah entitas domain.
          // Kita konversi di sini.
          return Krs(kode: model.kode, nama: model.nama, sks: model.sks);
        }).toList();
        // -------------------------
      } else {
        throw Exception(body['message'] ?? 'Gagal memuat data KRS.');
      }
    } else {
      throw Exception('Gagal memuat KRS (Status: ${response.statusCode})');
    }
  }
}
