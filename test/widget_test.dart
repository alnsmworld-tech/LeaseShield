import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lease_shield/core/hybrid_ai/hybrid_ai_models.dart';
import 'package:lease_shield/core/theme/app_theme.dart';
import 'package:lease_shield/features/analysis/presentation/widgets/hybrid_telemetry_bar.dart';
import 'package:lease_shield/features/onboarding/presentation/onboarding_page.dart';

void main() {
  testWidgets('HybridTelemetryBar renders ON-DEVICE pill and fallback banner', (
    tester,
  ) async {
    const telemetry = HybridAiTelemetry(
      inferenceSource: InferenceSource.onDevice,
      latencyMs: 340,
      modelName: 'Gemini Nano 4',
      fallbackBanner: 'Verified 100% local execution.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: HybridTelemetryBar(telemetry: telemetry),
          ),
        ),
      ),
    );

    expect(find.text('ON-DEVICE • Gemini Nano 4 • 340ms'), findsOneWidget);
    expect(find.text('Verified 100% local execution.'), findsOneWidget);
  });

  testWidgets('HybridTelemetryBar renders IN-CLOUD formatted latency pill', (
    tester,
  ) async {
    const telemetry = HybridAiTelemetry(
      inferenceSource: InferenceSource.inCloud,
      latencyMs: 1120,
      modelName: 'gemini-2.5-flash',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: HybridTelemetryBar(telemetry: telemetry),
          ),
        ),
      ),
    );

    expect(find.text('IN-CLOUD • gemini-2.5-flash • 1,120ms'), findsOneWidget);
  });

  testWidgets('OnboardingPage walks through 3 slides and completes', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OnboardingPage(onComplete: () => completed = true),
      ),
    );

    expect(find.text('Spot Unfair Lease Clauses in Seconds'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
