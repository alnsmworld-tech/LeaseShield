import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lease_shield/core/config/app_config.dart';
import 'package:lease_shield/core/config/remote_config_service.dart';
import 'package:lease_shield/core/hybrid_ai/hybrid_ai_models.dart';
import 'package:lease_shield/core/hybrid_ai/hybrid_ai_service.dart';
import 'package:lease_shield/core/hybrid_ai/local_clause_detector.dart';
import 'package:lease_shield/core/hybrid_ai/local_pii_scrubber.dart';
import 'package:lease_shield/features/analysis/bloc/analysis_bloc.dart';
import 'package:lease_shield/features/analysis/bloc/analysis_event.dart';
import 'package:lease_shield/features/analysis/bloc/analysis_state.dart';
import 'package:mocktail/mocktail.dart';

class MockHybridAiService extends Mock implements HybridAiService {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  late MockHybridAiService mockHybridAiService;
  late MockRemoteConfigService mockRemoteConfigService;
  late LocalPiiScrubber piiScrubber;
  late LocalClauseDetector localClauseDetector;

  setUpAll(() {
    registerFallbackValue(InferenceMode.onlyOnDevice);
  });

  setUp(() {
    mockHybridAiService = MockHybridAiService();
    mockRemoteConfigService = MockRemoteConfigService();
    piiScrubber = LocalPiiScrubber();
    localClauseDetector = LocalClauseDetector(piiScrubber);

    when(() => mockRemoteConfigService.redFlagPromptTemplate)
        .thenReturn(AppConfig.defaultRedFlagPromptTemplate);
  });

  AnalysisBloc buildBloc() => AnalysisBloc(
        hybridAiService: mockHybridAiService,
        remoteConfigService: mockRemoteConfigService,
        piiScrubber: piiScrubber,
        localClauseDetector: localClauseDetector,
      );

  group('AnalysisBloc', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'emits AnalysisFailure when raw lease text is empty',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AnalyzeLeaseRequested(
          title: 'Empty Lease',
          region: 'Austin, TX',
          rawLeaseText: '   ',
          mode: InferenceMode.onlyOnDevice,
        ),
      ),
      expect: () => [isA<AnalysisFailure>()],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'parses on-device Gemini Nano JSON response, scrubs residual PII, and preserves telemetry',
      setUp: () {
        final modelJson = jsonEncode({
          'redactedText':
              'Tenant: Jordan Rivera (SSN 123-45-6789) agrees Landlord may enter without prior notice.',
          'overallRiskScore': 82,
          'summary': 'High-risk entry clause detected.',
          'clauses': [
            {
              'id': 'c1',
              'title': 'Entry Without Notice',
              'severity': 'HIGH',
              'category': 'Entry',
              'excerpt': 'Landlord may enter without prior notice.',
              'explanation': 'Violates quiet enjoyment.',
              'recommendation': 'Require 24-hour written notice.',
            },
          ],
        });

        when(
          () => mockHybridAiService.analyzeLease(
            rawLeaseText: any(named: 'rawLeaseText'),
            promptTemplate: any(named: 'promptTemplate'),
            mode: any(named: 'mode'),
          ),
        ).thenAnswer(
          (_) async => HybridAiResponse(
            text: modelJson,
            telemetry: const HybridAiTelemetry(
              inferenceSource: InferenceSource.onDevice,
              latencyMs: 340,
              modelName: 'Gemini Nano 4',
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AnalyzeLeaseRequested(
          title: 'Student Lease',
          region: 'Austin, TX',
          rawLeaseText:
              'Tenant: Jordan Rivera SSN: 123-45-6789. Landlord may enter without prior notice.',
          mode: InferenceMode.onlyOnDevice,
        ),
      ),
      expect: () => [
        isA<AnalysisLoading>(),
        isA<AnalysisSuccess>()
            .having((s) => s.result.overallRiskScore, 'riskScore', 82)
            .having((s) => s.result.clauses.length, 'clauses', 1)
            .having(
              (s) => s.result.telemetry.pillLabel,
              'telemetry pill',
              'ON-DEVICE • Gemini Nano 4 • 340ms',
            )
            .having(
              (s) => s.result.redactedText.contains('123-45-6789'),
              'zero residual SSN',
              isFalse,
            ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'falls back cleanly to LocalClauseDetector when model emits non-JSON output',
      setUp: () {
        when(
          () => mockHybridAiService.analyzeLease(
            rawLeaseText: any(named: 'rawLeaseText'),
            promptTemplate: any(named: 'promptTemplate'),
            mode: any(named: 'mode'),
          ),
        ).thenAnswer(
          (_) async => const HybridAiResponse(
            text: 'Sorry, I could not format JSON.',
            telemetry: HybridAiTelemetry(
              inferenceSource: InferenceSource.onDevice,
              latencyMs: 210,
              modelName: 'Gemini Nano 4',
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AnalyzeLeaseRequested(
          title: 'Fallback Lease',
          region: 'Austin, TX',
          rawLeaseText:
              'Landlord may enter the premises at any time without prior notice.',
          mode: InferenceMode.onlyOnDevice,
        ),
      ),
      expect: () => [
        isA<AnalysisLoading>(),
        isA<AnalysisSuccess>().having(
          (s) => s.result.clauses.isNotEmpty,
          'fallback detected clause',
          isTrue,
        ),
      ],
    );
  });
}
