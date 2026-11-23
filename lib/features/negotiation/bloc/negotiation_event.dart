import 'package:equatable/equatable.dart';

import '../../analysis/domain/lease_analysis_models.dart';

sealed class NegotiationEvent extends Equatable {
  const NegotiationEvent();

  @override
  List<Object?> get props => [];
}

final class PrepareNegotiationContext extends NegotiationEvent {
  const PrepareNegotiationContext({
    required this.analysisResult,
    required this.region,
    this.tone = 'Polite & Collaborative',
  });

  final LeaseAnalysisResult analysisResult;
  final String region;
  final String tone;

  @override
  List<Object?> get props => [analysisResult, region, tone];
}

final class UpdateNegotiationParams extends NegotiationEvent {
  const UpdateNegotiationParams({
    this.region,
    this.tone,
  });

  final String? region;
  final String? tone;

  @override
  List<Object?> get props => [region, tone];
}

final class GenerateCounterOfferRequested extends NegotiationEvent {
  const GenerateCounterOfferRequested();
}
