/// Folder: krs/data/models/krs_model.dart
class KrsModel {
  final String kode;
  final String nama;
  final int sks;

  KrsModel({required this.kode, required this.nama, required this.sks});

  factory KrsModel.fromJson(Map<String, dynamic> json) {
    return KrsModel(kode: json['kode'], nama: json['nama'], sks: json['sks']);
  }
}
