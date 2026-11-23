import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Typed access layer over Firebase Remote Config with guaranteed local fallbacks.
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    try {
      _remoteConfig ??= FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval:
              kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 1),
        ),
      );
      await _remoteConfig!.setDefaults(AppConfig.remoteConfigDefaults);
      await _remoteConfig!.fetchAndActivate();
      _initialized = true;
    } catch (e) {
      debugPrint('[LeaseShield] Remote Config fallback to local defaults: $e');
      _initialized = false;
    }
  }

  String get redFlagPromptTemplate {
    if (!_initialized || _remoteConfig == null) {
      return AppConfig.defaultRedFlagPromptTemplate;
    }
    final value = _remoteConfig!.getString(AppConfig.rcRedFlagPromptKey);
    return value.trim().isEmpty ? AppConfig.defaultRedFlagPromptTemplate : value;
  }

  String get negotiationPromptTemplate {
    if (!_initialized || _remoteConfig == null) {
      return AppConfig.defaultNegotiationPromptTemplate;
    }
    final value = _remoteConfig!.getString(AppConfig.rcNegotiationPromptKey);
    return value.trim().isEmpty
        ? AppConfig.defaultNegotiationPromptTemplate
        : value;
  }

  String get defaultTriageMode {
    if (!_initialized || _remoteConfig == null) {
      return AppConfig.defaultTriageMode;
    }
    final value = _remoteConfig!.getString(AppConfig.rcDefaultTriageModeKey);
    if (value == 'ONLY_ON_DEVICE' || value == 'PREFER_ON_DEVICE') {
      return value;
    }
    return AppConfig.defaultTriageMode;
  }
}
