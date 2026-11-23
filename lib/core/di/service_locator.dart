import 'package:get_it/get_it.dart';

import '../../features/analysis/bloc/analysis_bloc.dart';
import '../../features/history/bloc/history_bloc.dart';
import '../../features/history/data/lease_history_repository.dart';
import '../../features/negotiation/bloc/negotiation_bloc.dart';
import '../../features/scanner/data/lease_ocr_service.dart';
import '../config/firebase_bootstrap.dart';
import '../config/remote_config_service.dart';
import '../hybrid_ai/hybrid_ai_service.dart';
import '../hybrid_ai/local_clause_detector.dart';
import '../hybrid_ai/local_pii_scrubber.dart';

final GetIt sl = GetIt.instance;

/// Registers core services, repositories, and BLoCs via `get_it`.
Future<FirebaseBootstrapResult> setupServiceLocator() async {
  if (!sl.isRegistered<RemoteConfigService>()) {
    sl.registerLazySingleton<RemoteConfigService>(RemoteConfigService.new);
  }

  if (!sl.isRegistered<LocalPiiScrubber>()) {
    sl.registerLazySingleton<LocalPiiScrubber>(LocalPiiScrubber.new);
  }

  if (!sl.isRegistered<LocalClauseDetector>()) {
    sl.registerLazySingleton<LocalClauseDetector>(
      () => LocalClauseDetector(sl<LocalPiiScrubber>()),
    );
  }

  if (!sl.isRegistered<HybridAiService>()) {
    sl.registerLazySingleton<HybridAiService>(
      () => HybridAiService(
        piiScrubber: sl<LocalPiiScrubber>(),
        localClauseDetector: sl<LocalClauseDetector>(),
      ),
    );
  }

  if (!sl.isRegistered<LeaseOcrService>()) {
    sl.registerLazySingleton<LeaseOcrService>(LeaseOcrService.new);
  }

  final bootstrapResult = await FirebaseBootstrap.initialize(
    sl<RemoteConfigService>(),
  );

  if (sl.isRegistered<FirebaseBootstrapResult>()) {
    sl.unregister<FirebaseBootstrapResult>();
  }
  sl.registerSingleton<FirebaseBootstrapResult>(bootstrapResult);

  if (sl.isRegistered<LeaseHistoryRepository>()) {
    sl.unregister<LeaseHistoryRepository>();
  }
  sl.registerLazySingleton<LeaseHistoryRepository>(
    () => LeaseHistoryRepository(
      piiScrubber: sl<LocalPiiScrubber>(),
      bootstrapResult: sl<FirebaseBootstrapResult>(),
    ),
  );

  // BLoCs
  if (!sl.isRegistered<AnalysisBloc>()) {
    sl.registerFactory<AnalysisBloc>(
      () => AnalysisBloc(
        hybridAiService: sl<HybridAiService>(),
        remoteConfigService: sl<RemoteConfigService>(),
        piiScrubber: sl<LocalPiiScrubber>(),
        localClauseDetector: sl<LocalClauseDetector>(),
      ),
    );
  }

  if (!sl.isRegistered<NegotiationBloc>()) {
    sl.registerFactory<NegotiationBloc>(
      () => NegotiationBloc(
        hybridAiService: sl<HybridAiService>(),
        remoteConfigService: sl<RemoteConfigService>(),
        piiScrubber: sl<LocalPiiScrubber>(),
      ),
    );
  }

  if (!sl.isRegistered<HistoryBloc>()) {
    sl.registerLazySingleton<HistoryBloc>(
      () => HistoryBloc(repository: sl<LeaseHistoryRepository>()),
    );
  }

  return bootstrapResult;
}
