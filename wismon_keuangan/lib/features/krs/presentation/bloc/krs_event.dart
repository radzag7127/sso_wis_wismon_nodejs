// File: lib/features/krs/presentation/bloc/krs_event.dart

part of 'krs_bloc.dart';

abstract class KrsEvent extends Equatable {
  const KrsEvent();

  @override
  List<Object> get props => [];
}

class FetchKrsData extends KrsEvent {
  final int semesterKe;
  final int jenisSemester;

  const FetchKrsData({required this.semesterKe, required this.jenisSemester});

  @override
  List<Object> get props => [semesterKe, jenisSemester];
}
