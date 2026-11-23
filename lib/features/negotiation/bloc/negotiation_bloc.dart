import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/remote_config_service.dart';
import '../../../core/hybrid_ai/hybrid_ai_service.dart';
import '../../../core/hybrid_ai/local_pii_scrubber.dart';
import '../../analysis/domain/lease_analysis_models.dart';
import '../domain/negotiation_models.dart';
import 'negotiation_event.dart';
import 'negotiation_state.dart';

/// Manages the Cloud Gemini counter-offer escalation flow and builds the
/// inspectable zero-PII outbound payload.
class NegotiationBloc extends Bloc<NegotiationEvent, NegotiationState> {
  NegotiationBloc({
    required HybridAiService hybridAiService,
    required RemoteConfigService remoteConfigService,
    required LocalPiiScrubber piiScrubber,
  })  : _hybridAiService = hybridAiService,
        _remoteConfigService = remoteConfigService,
        _piiScrubber = piiScrubber,
        super(const NegotiationState()) {
    on<PrepareNegotiationContext>(_onPrepareContext);
    on<UpdateNegotiationParams>(_onUpdateParams);
    on<GenerateCounterOfferRequested>(_onGenerateCounterOffer);
  }

  final HybridAiService _hybridAiService;
  final RemoteConfigService _remoteConfigService;
  final LocalPiiScrubber _piiScrubber;

  void _onPrepareContext(
    PrepareNegotiationContext event,
    Emitter<NegotiationState> emit,
  ) {
    final payload = _buildOutboundPayload(
      analysis: event.analysisResult,
      region: event.region,
      tone: event.tone,
    );

    emit(
      NegotiationState(
        status: NegotiationStatus.ready,
        analysisResult: event.analysisResult,
        region: event.region,
        tone: event.tone,
        outboundPayload: payload,
      ),
    );
  }

  void _onUpdateParams(
    UpdateNegotiationParams event,
    Emitter<NegotiationState> emit,
  ) {
    final analysis = state.analysisResult;
    if (analysis == null) return;

    final updatedRegion = event.region ?? state.region;
    final updatedTone = event.tone ?? state.tone;

    emit(
      state.copyWith(
        region: updatedRegion,
        tone: updatedTone,
        outboundPayload: _buildOutboundPayload(
          analysis: analysis,
          region: updatedRegion,
          tone: updatedTone,
        ),
      ),
    );
  }

  Future<void> _onGenerateCounterOffer(
    GenerateCounterOfferRequested event,
    Emitter<NegotiationState> emit,
  ) async {
    final analysis = state.analysisResult;
    final payload = state.outboundPayload;
    if (analysis == null || payload == null) return;

    emit(state.copyWith(status: NegotiationStatus.generating));

    try {
      final clausesJson = const JsonEncoder.withIndent('  ')
          .convert(payload.redactedClauses);

      final prompt = _remoteConfigService.negotiationPromptTemplate
          .replaceAll('{{REGION}}', payload.region)
          .replaceAll('{{TONE}}', payload.tone)
          .replaceAll('{{REDACTED_CLAUSES}}', clausesJson);

      final clauseTitles = payload.redactedClauses
          .map((c) => c['title'] ?? 'Flagged Clause')
          .toList();

      final response = await _hybridAiService.generateNegotiationDraft(
        prompt: prompt,
        region: payload.region,
        clauseTitles: clauseTitles,
      );

      final draft = NegotiationDraft.fromModelOutput(
        leaseId: analysis.id,
        region: payload.region,
        tone: payload.tone,
        response: response,
      );

      emit(
        state.copyWith(
          status: NegotiationStatus.generated,
          draft: draft,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NegotiationStatus.failure,
          errorMessage: 'Failed to generate counter-offer: $e',
        ),
      );
    }
  }

  OutboundCloudPayload _buildOutboundPayload({
    required LeaseAnalysisResult analysis,
    required String region,
    required String tone,
  }) {
    final clauses = analysis.selectedClauses.isNotEmpty
        ? analysis.selectedClauses
        : analysis.clauses;

    final redactedClauses = clauses.map((c) {
      final safeExcerpt = _piiScrubber.scrub(c.excerpt).redactedText;
      final safeExplanation = _piiScrubber.scrub(c.explanation).redactedText;
      final safeRecommendation =
          _piiScrubber.scrub(c.recommendation).redactedText;
      return <String, String>{
        'title': c.title,
        'severity': c.severity.label,
        'category': c.category,
        'redactedExcerpt': safeExcerpt,
        'concern': safeExplanation,
        'requestedChange': safeRecommendation,
      };
    }).toList();

    final serialized = jsonEncode({
      'region': region,
      'tone': tone,
      'redactedClauses': redactedClauses,
    });
    final piiAuditPassed = !_piiScrubber.containsPotentialPii(serialized);

    return OutboundCloudPayload(
      region: region.trim().isEmpty ? 'General' : region.trim(),
      tone: tone,
      redactedClauses: redactedClauses,
      piiAuditPassed: piiAuditPassed,
    );
  }
}
