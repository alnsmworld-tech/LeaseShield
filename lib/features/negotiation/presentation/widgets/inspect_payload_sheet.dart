import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/negotiation_models.dart';

/// Glass Box transparency modal showing the exact JSON payload leaving the
/// device before Cloud Gemini escalation, proving zero PII is transmitted.
class InspectPayloadSheet extends StatelessWidget {
  const InspectPayloadSheet({
    super.key,
    required this.payload,
  });

  final OutboundCloudPayload payload;

  static Future<void> show(
    BuildContext context,
    OutboundCloudPayload payload,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => InspectPayloadSheet(payload: payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditColor =
        payload.piiAuditPassed ? AppColors.emerald : AppColors.crimson;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Outbound Cloud Payload Inspector',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: auditColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: auditColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      payload.piiAuditPassed
                          ? Icons.verified_user_rounded
                          : Icons.warning_amber_rounded,
                      color: auditColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        payload.piiAuditPassed
                            ? 'ZERO PII VERIFIED: Only redacted clause excerpts and city/region are sent to Cloud Gemini.'
                            : 'Warning: Potential sensitive string detected. Review before sending.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: auditColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(
                      payload.toPrettyJson(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close Inspector'),
              ),
            ],
          ),
        );
      },
    );
  }
}
