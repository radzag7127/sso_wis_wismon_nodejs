// lib/features/transkrip/presentation/bloc/transkrip_event.dart

import 'package:equatable/equatable.dart';

abstract class TranskripEvent extends Equatable {
  const TranskripEvent();

  @override
  List<Object> get props => [];
}

// REVISI: Event FetchTranskrip tidak lagi membawa NRM
class FetchTranskrip extends TranskripEvent {
  const FetchTranskrip();
}
