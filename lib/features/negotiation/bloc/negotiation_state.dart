import 'package:equatable/equatable.dart';

import '../../analysis/domain/lease_analysis_models.dart';
import '../domain/negotiation_models.dart';

enum NegotiationStatus { initial, ready, generating, generated, failure }

class NegotiationState extends Equatable {
  const NegotiationState({
    this.status = NegotiationStatus.initial,
    this.analysisResult,
    this.region = '',
    this.tone = 'Polite & Collaborative',
    this.outboundPayload,
    this.draft,
    this.errorMessage,
  });

  final NegotiationStatus status;
  final LeaseAnalysisResult? analysisResult;
  final String region;
  final String tone;
  final OutboundCloudPayload? outboundPayload;
  final NegotiationDraft? draft;
  final String? errorMessage;

  NegotiationState copyWith({
    NegotiationStatus? status,
    LeaseAnalysisResult? analysisResult,
    String? region,
    String? tone,
    OutboundCloudPayload? outboundPayload,
    NegotiationDraft? draft,
    String? errorMessage,
  }) {
    return NegotiationState(
      status: status ?? this.status,
      analysisResult: analysisResult ?? this.analysisResult,
      region: region ?? this.region,
      tone: tone ?? this.tone,
      outboundPayload: outboundPayload ?? this.outboundPayload,
      draft: draft ?? this.draft,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        analysisResult,
        region,
        tone,
        outboundPayload,
        draft,
        errorMessage,
      ];
}
