import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Explicit hybrid inference routing modes passed across the MethodChannel.
enum InferenceMode {
  onlyOnDevice('ONLY_ON_DEVICE'),
  preferOnDevice('PREFER_ON_DEVICE'),
  onlyInCloud('ONLY_IN_CLOUD');

  const InferenceMode(this.wireValue);
  final String wireValue;

  static InferenceMode fromWireValue(String value) {
    return InferenceMode.values.firstWhere(
      (mode) => mode.wireValue == value,
      orElse: () => InferenceMode.onlyOnDevice,
    );
  }
}

/// Actual execution target reported back by Firebase AI Logic or local fallback.
enum InferenceSource {
  onDevice('ON_DEVICE'),
  inCloud('IN_CLOUD'),
  localFallback('ON_DEVICE');

  const InferenceSource(this.wireValue);
  final String wireValue;

  bool get isOnDevice =>
      this == InferenceSource.onDevice || this == InferenceSource.localFallback;

  static InferenceSource fromWireValue(String value) {
    if (value == 'IN_CLOUD') return InferenceSource.inCloud;
    return InferenceSource.onDevice;
  }
}

/// Live telemetry metadata rendered in the Glass Box Hybrid Telemetry Bar.
class HybridAiTelemetry extends Equatable {
  const HybridAiTelemetry({
    required this.inferenceSource,
    required this.latencyMs,
    required this.modelName,
    this.fallbackBanner,
  });

  final InferenceSource inferenceSource;
  final int latencyMs;
  final String modelName;
  final String? fallbackBanner;

  bool get isOnDevice => inferenceSource.isOnDevice;

  String get badgePrefix => isOnDevice ? 'ON-DEVICE' : 'IN-CLOUD';

  String get formattedLatency {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(latencyMs)}ms';
  }

  String get pillLabel => '$badgePrefix • $modelName • $formattedLatency';

  Map<String, dynamic> toJson() => {
        'inferenceSource': inferenceSource.wireValue,
        'latencyMs': latencyMs,
        'modelName': modelName,
        if (fallbackBanner != null) 'fallbackBanner': fallbackBanner,
      };

  factory HybridAiTelemetry.fromJson(Map<String, dynamic> json) {
    return HybridAiTelemetry(
      inferenceSource: InferenceSource.fromWireValue(
        json['inferenceSource'] as String? ?? 'ON_DEVICE',
      ),
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      modelName: json['modelName'] as String? ?? 'On-Device Engine',
      fallbackBanner: json['fallbackBanner'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        inferenceSource,
        latencyMs,
        modelName,
        fallbackBanner,
      ];
}

/// Typed response returned by [HybridAiService].
class HybridAiResponse extends Equatable {
  const HybridAiResponse({
    required this.text,
    required this.telemetry,
  });

  final String text;
  final HybridAiTelemetry telemetry;

  @override
  List<Object?> get props => [text, telemetry];
}

/// Native device capability summary returned by `getCapabilities`.
class DeviceAiCapabilities extends Equatable {
  const DeviceAiCapabilities({
    required this.platform,
    required this.onDeviceSupported,
    required this.onDeviceModelName,
  });

  final String platform;
  final bool onDeviceSupported;
  final String onDeviceModelName;

  @override
  List<Object?> get props => [platform, onDeviceSupported, onDeviceModelName];
}
