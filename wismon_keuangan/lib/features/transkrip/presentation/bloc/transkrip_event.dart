// lib/features/transkrip/presentation/bloc/transkrip_event.dart
import 'package:equatable/equatable.dart';

abstract class TranskripEvent extends Equatable {
  const TranskripEvent();

  @override
  List<Object> get props => [];
}

class FetchTranskrip extends TranskripEvent {
  final String nrm;

  const FetchTranskrip({required this.nrm});

  @override
  List<Object> get props => [nrm];
}
