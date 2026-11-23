import 'package:flutter/material.dart';

import '../../../../core/hybrid_ai/hybrid_ai_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Glass Box Live Hybrid Telemetry Bar shown on every AI screen.
///
/// - Emerald green `#10B981` when running `ON-DEVICE` (Gemini Nano 4 / Apple Foundation Models)
/// - Indigo `#6366F1` when running `IN-CLOUD` (Cloud Gemini)
/// - Displays an amber transparency banner whenever a privacy-preserving fallback occurs.
class HybridTelemetryBar extends StatelessWidget {
  const HybridTelemetryBar({
    super.key,
    required this.telemetry,
  });

  final HybridAiTelemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accentColor = telemetry.isOnDevice
        ? (isLight ? AppColors.emeraldDark : AppColors.emerald)
        : AppColors.indigo;
    final amberColor = isLight ? AppColors.amberDark : AppColors.amber;
    final icon =
        telemetry.isOnDevice ? Icons.memory_rounded : Icons.cloud_done_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accentColor.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  telemetry.pillLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (telemetry.fallbackBanner != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: amberColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    telemetry.fallbackBanner!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: amberColor,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
