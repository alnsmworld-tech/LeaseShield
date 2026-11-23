import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lease_shield/core/config/app_config.dart';
import 'package:lease_shield/core/config/remote_config_service.dart';
import 'package:lease_shield/core/hybrid_ai/hybrid_ai_models.dart';
import 'package:lease_shield/core/hybrid_ai/hybrid_ai_service.dart';
import 'package:lease_shield/core/hybrid_ai/local_pii_scrubber.dart';
import 'package:lease_shield/features/analysis/domain/lease_analysis_models.dart';
import 'package:lease_shield/features/negotiation/bloc/negotiation_bloc.dart';
import 'package:lease_shield/features/negotiation/bloc/negotiation_event.dart';
import 'package:lease_shield/features/negotiation/bloc/negotiation_state.dart';
import 'package:mocktail/mocktail.dart';

class MockHybridAiService extends Mock implements HybridAiService {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  late MockHybridAiService mockHybridAiService;
  late MockRemoteConfigService mockRemoteConfigService;
  late LocalPiiScrubber piiScrubber;

  final sampleAnalysis = LeaseAnalysisResult(
    id: 'lease_1',
    title: 'Student Lease',
    region: 'Austin, TX',
    redactedText: 'Tenant: [REDACTED_NAME]. Landlord may enter without notice.',
    overallRiskScore: 78,
    summary: 'Flagged entry clause.',
    clauses: const [
      RiskyClause(
        id: 'c1',
        title: 'Entry Without Notice',
        severity: ClauseSeverity.high,
        category: 'Entry',
        excerpt: 'Landlord may enter without prior notice (contact 512-555-0199).',
        explanation: 'Violates quiet enjoyment.',
        recommendation: 'Require 24-hour written notice.',
      ),
    ],
    redactionCounts: const {'Names': 1},
    telemetry: const HybridAiTelemetry(
      inferenceSource: InferenceSource.onDevice,
      latencyMs: 320,
      modelName: 'Gemini Nano 4',
    ),
    analyzedAt: DateTime(2026, 11, 22),
  );

  setUp(() {
    mockHybridAiService = MockHybridAiService();
    mockRemoteConfigService = MockRemoteConfigService();
    piiScrubber = LocalPiiScrubber();

    when(() => mockRemoteConfigService.negotiationPromptTemplate)
        .thenReturn(AppConfig.defaultNegotiationPromptTemplate);
  });

  NegotiationBloc buildBloc() => NegotiationBloc(
        hybridAiService: mockHybridAiService,
        remoteConfigService: mockRemoteConfigService,
        piiScrubber: piiScrubber,
      );

  group('NegotiationBloc', () {
    blocTest<NegotiationBloc, NegotiationState>(
      'builds zero-PII inspectable outbound payload on PrepareNegotiationContext',
      build: buildBloc,
      act: (bloc) => bloc.add(
        PrepareNegotiationContext(
          analysisResult: sampleAnalysis,
          region: 'Austin, TX',
        ),
      ),
      expect: () => [
        isA<NegotiationState>()
            .having((s) => s.status, 'status', NegotiationStatus.ready)
            .having(
              (s) => s.outboundPayload?.piiAuditPassed,
              'piiAuditPassed',
              isTrue,
            )
            .having(
              (s) => s.outboundPayload?.toPrettyJson().contains('512-555-0199'),
              'scrubbed phone from outbound payload',
              isFalse,
            ),
      ],
    );

    blocTest<NegotiationBloc, NegotiationState>(
      'generates Cloud Gemini counter-offer draft and preserves IN-CLOUD telemetry',
      setUp: () {
        when(
          () => mockHybridAiService.generateNegotiationDraft(
            prompt: any(named: 'prompt'),
            region: any(named: 'region'),
            clauseTitles: any(named: 'clauseTitles'),
          ),
        ).thenAnswer(
          (_) async => HybridAiResponse(
            text: jsonEncode({
              'subject': 'Requested Lease Revisions — Austin, TX',
              'body': 'Dear [Landlord Name], please add 24h notice.',
              'regionalNorms': ['24-hour notice for non-emergency entry'],
              'toneSummary': 'Polite and firm.',
            }),
            telemetry: const HybridAiTelemetry(
              inferenceSource: InferenceSource.inCloud,
              latencyMs: 1120,
              modelName: 'gemini-2.5-flash',
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(
            PrepareNegotiationContext(
              analysisResult: sampleAnalysis,
              region: 'Austin, TX',
            ),
          )
          ..add(const GenerateCounterOfferRequested());
      },
      expect: () => [
        isA<NegotiationState>()
            .having((s) => s.status, 'status', NegotiationStatus.ready),
        isA<NegotiationState>()
            .having((s) => s.status, 'status', NegotiationStatus.generating),
        isA<NegotiationState>()
            .having((s) => s.status, 'status', NegotiationStatus.generated)
            .having(
              (s) => s.draft?.subject,
              'subject',
              'Requested Lease Revisions — Austin, TX',
            )
            .having(
              (s) => s.draft?.telemetry.pillLabel,
              'cloud telemetry',
              'IN-CLOUD • gemini-2.5-flash • 1,120ms',
            ),
      ],
    );
  });
}
