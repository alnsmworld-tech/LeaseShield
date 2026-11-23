import 'package:equatable/equatable.dart';

import '../../../core/hybrid_ai/hybrid_ai_models.dart';
import '../domain/lease_analysis_models.dart';

sealed class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

final class AnalyzeLeaseRequested extends AnalysisEvent {
  const AnalyzeLeaseRequested({
    required this.title,
    required this.region,
    required this.rawLeaseText,
    required this.mode,
  });

  final String title;
  final String region;
  final String rawLeaseText;
  final InferenceMode mode;

  @override
  List<Object?> get props => [title, region, rawLeaseText, mode];
}

final class ToggleClauseSelection extends AnalysisEvent {
  const ToggleClauseSelection(this.clauseId);

  final String clauseId;

  @override
  List<Object?> get props => [clauseId];
}

final class LoadSavedAnalysis extends AnalysisEvent {
  const LoadSavedAnalysis(this.result);

  final LeaseAnalysisResult result;

  @override
  List<Object?> get props => [result];
}
