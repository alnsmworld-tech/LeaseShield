import 'package:equatable/equatable.dart';

import '../../analysis/domain/lease_analysis_models.dart';
import '../../negotiation/domain/negotiation_models.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class LoadHistoryRequested extends HistoryEvent {
  const LoadHistoryRequested();
}

final class SaveAnalysisToHistory extends HistoryEvent {
  const SaveAnalysisToHistory(this.analysis);

  final LeaseAnalysisResult analysis;

  @override
  List<Object?> get props => [analysis];
}

final class SaveDraftToHistory extends HistoryEvent {
  const SaveDraftToHistory({
    required this.analysis,
    required this.draft,
  });

  final LeaseAnalysisResult analysis;
  final NegotiationDraft draft;

  @override
  List<Object?> get props => [analysis, draft];
}

final class DeleteHistoryRecord extends HistoryEvent {
  const DeleteHistoryRecord(this.leaseId);

  final String leaseId;

  @override
  List<Object?> get props => [leaseId];
}
