import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../bloc/analysis_bloc.dart';
import '../bloc/analysis_event.dart';
import '../bloc/analysis_state.dart';
import '../domain/lease_analysis_models.dart';
import 'widgets/hybrid_telemetry_bar.dart';
import 'widgets/red_flag_clause_card.dart';
import 'widgets/redacted_document_viewer.dart';

/// Displays on-device PII redaction results, red-flag clause cards, and the
/// Cloud Escalation CTA ("Draft Landlord Counter-Offer").
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    required this.onDraftCounterOffer,
    this.onSaveAnonymized,
  });

  final void Function(LeaseAnalysisResult result) onDraftCounterOffer;
  final Future<void> Function(LeaseAnalysisResult result)? onSaveAnonymized;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  int _selectedSegment = 0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lease Report',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          BlocBuilder<AnalysisBloc, AnalysisState>(
            builder: (context, state) {
              if (state is! AnalysisSuccess || widget.onSaveAnonymized == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Save Anonymized Summary',
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.onSaveAnonymized!(state.result);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Saved anonymized lease summary (0 PII).',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalysisBloc, AnalysisState>(
        builder: (context, state) {
          switch (state) {
            case AnalysisInitial():
              return const Center(
                child: Text('Select or scan a lease to begin.'),
              );

            case AnalysisLoading(:final statusMessage):
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.emeraldDark,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your raw lease stays 100% on your phone.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.emeraldDark,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              );

            case AnalysisFailure(:final message):
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.crimson,
                      ),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );

            case AnalysisSuccess(:final result):
              return _buildSuccessBody(context, result);
          }
        },
      ),
    );
  }

  Widget _buildSuccessBody(BuildContext context, LeaseAnalysisResult result) {
    final theme = Theme.of(context);
    final isHighRisk = result.overallRiskScore >= 65;
    final isMediumRisk = result.overallRiskScore >= 35 && !isHighRisk;
    final riskColor = isHighRisk
        ? AppColors.crimson
        : isMediumRisk
            ? AppColors.amberDark
            : AppColors.emeraldDark;
    final riskVerdict = isHighRisk
        ? 'High Risk — Negotiate Before Signing'
        : isMediumRisk
            ? 'Moderate Risk — Review Flagged Terms'
            : 'Looks Generally Fair';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              HybridTelemetryBar(telemetry: result.telemetry),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riskVerdict,
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  result.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${result.region} • ${result.totalRedactions} personal items hidden',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.emeraldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 66,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: riskColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${result.overallRiskScore}',
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'RISK',
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: Text('Issues Found (${result.clauses.length})'),
                  ),
                  const ButtonSegment<int>(
                    value: 1,
                    icon: Icon(Icons.verified_user_outlined, size: 18),
                    label: Text('Redacted Lease'),
                  ),
                ],
                selected: {_selectedSegment},
                onSelectionChanged: (selection) {
                  setState(() => _selectedSegment = selection.first);
                },
              ),
              const SizedBox(height: 14),
              if (_selectedSegment == 0)
                if (result.clauses.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.emeraldDark,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No predatory clauses detected.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...result.clauses.map(
                    (clause) => RedFlagClauseCard(
                      clause: clause,
                      onToggleSelected: () {
                        context.read<AnalysisBloc>().add(
                              ToggleClauseSelection(clause.id),
                            );
                      },
                    ),
                  )
              else
                RedactedDocumentViewer(
                  redactedText: result.redactedText,
                  redactionCounts: result.redactionCounts,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => widget.onDraftCounterOffer(result),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      'Draft Counter-Offer (${result.selectedClauses.length} Issues)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
