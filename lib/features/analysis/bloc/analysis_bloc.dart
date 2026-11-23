import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/remote_config_service.dart';
import '../../../core/hybrid_ai/hybrid_ai_service.dart';
import '../../../core/hybrid_ai/local_clause_detector.dart';
import '../../../core/hybrid_ai/local_pii_scrubber.dart';
import '../domain/lease_analysis_models.dart';
import 'analysis_event.dart';
import 'analysis_state.dart';

/// Orchestrates on-device PII redaction and predatory clause triage via
/// [HybridAiService] and [RemoteConfigService].
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  AnalysisBloc({
    required HybridAiService hybridAiService,
    required RemoteConfigService remoteConfigService,
    required LocalPiiScrubber piiScrubber,
    required LocalClauseDetector localClauseDetector,
  })  : _hybridAiService = hybridAiService,
        _remoteConfigService = remoteConfigService,
        _piiScrubber = piiScrubber,
        _localClauseDetector = localClauseDetector,
        super(const AnalysisInitial()) {
    on<AnalyzeLeaseRequested>(_onAnalyzeLeaseRequested);
    on<ToggleClauseSelection>(_onToggleClauseSelection);
    on<LoadSavedAnalysis>(_onLoadSavedAnalysis);
  }

  final HybridAiService _hybridAiService;
  final RemoteConfigService _remoteConfigService;
  final LocalPiiScrubber _piiScrubber;
  final LocalClauseDetector _localClauseDetector;

  Future<void> _onAnalyzeLeaseRequested(
    AnalyzeLeaseRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    if (event.rawLeaseText.trim().isEmpty) {
      emit(const AnalysisFailure('Lease text is empty. Please scan or select a lease.'));
      return;
    }

    emit(
      const AnalysisLoading(
        statusMessage: 'Redacting PII & triaging clauses on-device...',
      ),
    );

    try {
      // Pre-compute deterministic redaction stats on the raw text locally
      final localScrub = _piiScrubber.scrub(event.rawLeaseText);

      final response = await _hybridAiService.analyzeLease(
        rawLeaseText: event.rawLeaseText,
        promptTemplate: _remoteConfigService.redFlagPromptTemplate,
        mode: event.mode,
      );

      var decoded = LeaseAnalysisResult.tryDecodeJsonObject(response.text);
      // If on-device LLM returned non-JSON text, fall back to deterministic parser
      decoded ??= LeaseAnalysisResult.tryDecodeJsonObject(
        _localClauseDetector.analyzeLocallyAsJson(event.rawLeaseText),
      );

      if (decoded == null) {
        emit(const AnalysisFailure('Unable to parse lease analysis output.'));
        return;
      }

      // Belt-and-suspenders: scrub model output text as well to guarantee 0 PII
      final rawModelRedacted =
          decoded['redactedText'] as String? ?? localScrub.redactedText;
      final guaranteedRedacted = _piiScrubber.scrub(rawModelRedacted).redactedText;

      final rawClauses = (decoded['clauses'] as List<dynamic>? ?? const []);
      final clauses = rawClauses.asMap().entries.map((entry) {
        final clauseMap = Map<String, dynamic>.from(entry.value as Map);
        final safeExcerpt =
            _piiScrubber.scrub(clauseMap['excerpt'] as String? ?? '').redactedText;
        clauseMap['excerpt'] = safeExcerpt;
        return RiskyClause.fromJson(clauseMap, entry.key);
      }).toList();

      final safeSummary =
          _piiScrubber.scrub(decoded['summary'] as String? ?? '').redactedText;

      final result = LeaseAnalysisResult(
        id: 'lease_${DateTime.now().millisecondsSinceEpoch}',
        title: event.title,
        region: event.region,
        redactedText: guaranteedRedacted,
        overallRiskScore:
            ((decoded['overallRiskScore'] as num?)?.toInt() ?? 0).clamp(0, 100),
        summary: safeSummary,
        clauses: clauses,
        redactionCounts: localScrub.redactionCounts,
        telemetry: response.telemetry,
        analyzedAt: DateTime.now(),
      );

      emit(AnalysisSuccess(result));
    } catch (e) {
      emit(AnalysisFailure('Lease analysis failed: $e'));
    }
  }

  void _onToggleClauseSelection(
    ToggleClauseSelection event,
    Emitter<AnalysisState> emit,
  ) {
    final current = state;
    if (current is! AnalysisSuccess) return;

    final updatedClauses = current.result.clauses.map((clause) {
      if (clause.id == event.clauseId) {
        return clause.copyWith(
          selectedForNegotiation: !clause.selectedForNegotiation,
        );
      }
      return clause;
    }).toList();

    emit(AnalysisSuccess(current.result.copyWith(clauses: updatedClauses)));
  }

  void _onLoadSavedAnalysis(
    LoadSavedAnalysis event,
    Emitter<AnalysisState> emit,
  ) {
    emit(AnalysisSuccess(event.result));
  }
}
