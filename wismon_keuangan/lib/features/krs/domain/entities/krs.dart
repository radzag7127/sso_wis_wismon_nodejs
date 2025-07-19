// lib/features/krs/domain/entities/krs.dart

class Krs {
  final String kode;
  final String nama;
  final int sks;

  Krs({required this.kode, required this.nama, required this.sks});

  // TAMBAHKAN FACTORY CONSTRUCTOR INI
  factory Krs.fromJson(Map<String, dynamic> json) {
    return Krs(
      kode: json['kode'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      sks: json['sks'] as int? ?? 0,
    );
  }
}
