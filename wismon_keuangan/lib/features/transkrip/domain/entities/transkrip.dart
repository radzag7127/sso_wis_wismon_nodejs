// lib/features/transkrip/domain/entities/transkrip.dart

import 'package:equatable/equatable.dart';

class Transkrip extends Equatable {
  final String ipk;
  final int totalSks;
  final List<Course> courses;

  const Transkrip({
    required this.ipk,
    required this.totalSks,
    required this.courses,
  });

  @override
  List<Object?> get props => [ipk, totalSks, courses];
}

class Course extends Equatable {
  final String namamk;
  final int sks;
  final String? nilai;
  final double? bobotNilai;
  // --- PERUBAHAN 1: Menggunakan camelCase agar konsisten ---
  final int semesterKe;

  const Course({
    required this.namamk,
    required this.sks,
    this.nilai,
    this.bobotNilai,
    required this.semesterKe,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      namamk: json['namamk'],
      sks: json['sks'],
      nilai: json['nilai'],
      bobotNilai: (json['bobotnilai'] as num?)?.toDouble(),
      // --- PERUBAHAN 2: Membaca key 'semesterKe' dari JSON ---
      semesterKe: json['semesterKe'],
    );
  }

  @override
  // --- PERUBAHAN 3: Memperbarui props ---
  List<Object?> get props => [namamk, sks, nilai, bobotNilai, semesterKe];
}
