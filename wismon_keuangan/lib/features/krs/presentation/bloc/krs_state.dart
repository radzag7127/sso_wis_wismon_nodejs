// lib/features/krs/presentation/bloc/krs_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/krs.dart';

abstract class KrsState extends Equatable {
  const KrsState();

  @override
  List<Object?> get props => [];
}

class KrsInitial extends KrsState {}

class KrsLoading extends KrsState {}

class KrsLoaded extends KrsState {
  final List<Krs> krsList;
  final List<String> availableSemesters;
  final String selectedSemester;
  final int totalSks;
  final bool isLoading; // --- TAMBAHKAN PROPERTI INI ---

  const KrsLoaded({
    required this.krsList,
    required this.availableSemesters,
    required this.selectedSemester,
    required this.totalSks,
    this.isLoading = false, // --- TAMBAHKAN NILAI DEFAULT ---
  });

  @override
  List<Object?> get props => [
    krsList,
    availableSemesters,
    selectedSemester,
    totalSks,
    isLoading, // --- TAMBAHKAN KE PROPS ---
  ];

  KrsLoaded copyWith({
    List<Krs>? krsList,
    List<String>? availableSemesters,
    String? selectedSemester,
    int? totalSks,
    bool? isLoading, // --- TAMBAHKAN PARAMETER INI ---
  }) {
    return KrsLoaded(
      krsList: krsList ?? this.krsList,
      availableSemesters: availableSemesters ?? this.availableSemesters,
      selectedSemester: selectedSemester ?? this.selectedSemester,
      totalSks: totalSks ?? this.totalSks,
      isLoading: isLoading ?? this.isLoading, // --- TAMBAHKAN LOGIKA INI ---
    );
  }
}

class KrsError extends KrsState {
  final String message;
  const KrsError(this.message);

  @override
  List<Object> get props => [message];
}
