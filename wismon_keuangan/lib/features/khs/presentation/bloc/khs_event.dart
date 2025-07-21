// lib/features/khs/presentation/bloc/khs_event.dart

part of 'khs_bloc.dart';

abstract class KhsEvent extends Equatable {
  const KhsEvent();

  @override
  List<Object> get props => [];
}

class FetchKhsData extends KhsEvent {
  final int semesterKe;

  const FetchKhsData({required this.semesterKe});

  @override
  List<Object> get props => [semesterKe];
}
