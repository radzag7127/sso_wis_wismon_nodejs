// lib/features/krs/presentation/bloc/krs_event.dart

part of 'krs_bloc.dart';

abstract class KrsEvent extends Equatable {
  const KrsEvent();

  @override
  List<Object> get props => [];
}

class FetchKrsData extends KrsEvent {
  final int semesterKe;

  const FetchKrsData({required this.semesterKe});

  @override
  List<Object> get props => [semesterKe];
}
