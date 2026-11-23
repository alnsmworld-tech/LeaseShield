import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../analysis/domain/lease_analysis_models.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';

/// Displays Firestore-synced (or offline-cached) anonymized lease summaries and
/// saved negotiation drafts. Raw PII is never stored.
class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.onOpenAnalysis,
  });

  final void Function(LeaseAnalysisResult analysis) onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<HistoryBloc>().add(const LoadHistoryRequested());
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Sync & Anonymous Auth Status Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (state.cloudSyncActive
                          ? AppColors.emerald
                          : AppColors.amber)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (state.cloudSyncActive
                            ? AppColors.emerald
                            : AppColors.amber)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.cloudSyncActive
                          ? Icons.cloud_done_rounded
                          : Icons.offline_pin_rounded,
                      color: state.cloudSyncActive
                          ? AppColors.emerald
                          : AppColors.amber,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.cloudSyncActive
                                ? 'Firestore Sync Active (Anonymous Auth)'
                                : 'Local Session History (Offline / Unconfigured)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.cloudSyncActive
                                ? 'Path: users/${state.uid?.substring(0, 8)}.../leases • Redacted data only.'
                                : 'Only anonymized summaries are ever persisted. Run flutterfire configure to enable Firestore sync.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (state.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.records.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_edu_rounded,
                          size: 44,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Saved Analyses Yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan a lease or tap a sample lease, then tap the bookmark icon or save a counter-offer draft to build your anonymized history.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...state.records.map((record) {
                  final analysis = record.analysis;
                  final dateLabel = DateFormat('MMM d, h:mm a')
                      .format(analysis.analyzedAt);
                  final riskColor = analysis.overallRiskScore >= 65
                      ? AppColors.crimson
                      : analysis.overallRiskScore >= 35
                          ? AppColors.amber
                          : AppColors.emerald;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: riskColor.withValues(alpha: 0.16),
                        child: Text(
                          '${analysis.overallRiskScore}',
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        analysis.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${analysis.region} • ${analysis.clauses.length} flags • ${analysis.totalRedactions} PII redacted',
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  dateLabel,
                                  style: theme.textTheme.labelSmall,
                                ),
                                if (record.draft != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.indigo
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Draft Saved',
                                      style: TextStyle(
                                        color: AppColors.indigo,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete record',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () {
                          context.read<HistoryBloc>().add(
                                DeleteHistoryRecord(analysis.id),
                              );
                        },
                      ),
                      onTap: () => onOpenAnalysis(analysis),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
