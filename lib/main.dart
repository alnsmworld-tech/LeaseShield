import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/config/remote_config_service.dart';
import 'core/di/service_locator.dart';
import 'core/hybrid_ai/hybrid_ai_models.dart';
import 'core/hybrid_ai/hybrid_ai_service.dart';
import 'core/theme/app_theme.dart';
import 'features/analysis/bloc/analysis_bloc.dart';
import 'features/analysis/bloc/analysis_event.dart';
import 'features/analysis/domain/lease_analysis_models.dart';
import 'features/analysis/presentation/analysis_page.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/history/bloc/history_event.dart';
import 'features/history/presentation/history_page.dart';
import 'features/negotiation/bloc/negotiation_bloc.dart';
import 'features/negotiation/bloc/negotiation_event.dart';
import 'features/negotiation/presentation/negotiation_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/scanner/data/lease_document_service.dart';
import 'features/scanner/data/lease_ocr_service.dart';
import 'features/scanner/presentation/scanner_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  sl<HistoryBloc>().add(const LoadHistoryRequested());
  runApp(const LeaseShieldApp());
}

class LeaseShieldApp extends StatefulWidget {
  const LeaseShieldApp({super.key});

  @override
  State<LeaseShieldApp> createState() => _LeaseShieldAppState();
}

class _LeaseShieldAppState extends State<LeaseShieldApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _showOnboarding = true;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _finishOnboarding() {
    setState(() => _showOnboarding = false);
  }

  void _replayOnboarding() {
    setState(() => _showOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryBloc>.value(
      value: sl<HistoryBloc>(),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: _showOnboarding
            ? OnboardingPage(onComplete: _finishOnboarding)
            : _LeaseShieldShell(
                isDark: _themeMode == ThemeMode.dark,
                onToggleTheme: _toggleTheme,
                onReplayOnboarding: _replayOnboarding,
              ),
      ),
    );
  }
}

class _LeaseShieldShell extends StatefulWidget {
  const _LeaseShieldShell({
    required this.isDark,
    required this.onToggleTheme,
    required this.onReplayOnboarding,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onReplayOnboarding;

  @override
  State<_LeaseShieldShell> createState() => _LeaseShieldShellState();
}

class _LeaseShieldShellState extends State<_LeaseShieldShell> {
  int _tabIndex = 0;

  void _startAnalysis({
    required String title,
    required String region,
    required String rawLeaseText,
    required InferenceMode mode,
  }) {
    final bloc = sl<AnalysisBloc>()
      ..add(
        AnalyzeLeaseRequested(
          title: title,
          region: region,
          rawLeaseText: rawLeaseText,
          mode: mode,
        ),
      );
    _pushAnalysisPage(bloc);
  }

  void _openSavedAnalysis(LeaseAnalysisResult analysis) {
    final bloc = sl<AnalysisBloc>()..add(LoadSavedAnalysis(analysis));
    _pushAnalysisPage(bloc);
  }

  void _pushAnalysisPage(AnalysisBloc analysisBloc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<AnalysisBloc>(
          create: (_) => analysisBloc,
          child: AnalysisPage(
            onSaveAnonymized: (result) async {
              sl<HistoryBloc>().add(SaveAnalysisToHistory(result));
            },
            onDraftCounterOffer: (result) {
              _openNegotiationPage(result);
            },
          ),
        ),
      ),
    );
  }

  void _openNegotiationPage(LeaseAnalysisResult analysis) {
    final negotiationBloc = sl<NegotiationBloc>()
      ..add(
        PrepareNegotiationContext(
          analysisResult: analysis,
          region: analysis.region,
        ),
      );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<NegotiationBloc>(
          create: (_) => negotiationBloc,
          child: NegotiationPage(
            onSaveDraft: (draft) async {
              sl<HistoryBloc>().add(
                SaveDraftToHistory(analysis: analysis, draft: draft),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = sl<FirebaseBootstrapResult>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.emeraldDark),
            const SizedBox(width: 8),
            const Text(
              AppConfig.appName,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (bootstrap.appCheckReady
                        ? AppColors.emerald
                        : AppColors.amber)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                bootstrap.appCheckReady ? 'App Check' : 'Offline Mode',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: bootstrap.appCheckReady
                      ? AppColors.emeraldDark
                      : AppColors.amberDark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'How LeaseShield Works',
            onPressed: widget.onReplayOnboarding,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: widget.isDark ? 'Light Theme' : 'Dark Theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          ScannerPage(
            ocrService: sl<LeaseOcrService>(),
            documentService: sl<LeaseDocumentService>(),
            hybridAiService: sl<HybridAiService>(),
            remoteConfigService: sl<RemoteConfigService>(),
            onAnalyzeLease: _startAnalysis,
          ),
          HistoryPage(
            onOpenAnalysis: _openSavedAnalysis,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
