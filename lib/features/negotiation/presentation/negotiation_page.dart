import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../analysis/presentation/widgets/hybrid_telemetry_bar.dart';
import '../bloc/negotiation_bloc.dart';
import '../bloc/negotiation_event.dart';
import '../bloc/negotiation_state.dart';
import '../domain/negotiation_models.dart';
import 'widgets/inspect_payload_sheet.dart';

/// Clean 3-step Cloud Escalation screen:
/// 1. Pick City & Tone -> 2. Inspect Zero-PII Payload -> 3. Draft with Cloud Gemini.
class NegotiationPage extends StatefulWidget {
  const NegotiationPage({
    super.key,
    this.onSaveDraft,
  });

  final Future<void> Function(NegotiationDraft draft)? onSaveDraft;

  @override
  State<NegotiationPage> createState() => _NegotiationPageState();
}

class _NegotiationPageState extends State<NegotiationPage> {
  static const List<String> _tones = [
    'Polite & Collaborative',
    'Firm & Statutory',
    'Concise & Direct',
  ];

  late final TextEditingController _regionController;
  bool _savingDraft = false;

  @override
  void initState() {
    super.initState();
    final initialRegion = context.read<NegotiationBloc>().state.region;
    _regionController = TextEditingController(text: initialRegion);
  }

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Draft Counter-Offer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<NegotiationBloc, NegotiationState>(
        builder: (context, state) {
          final payload = state.outboundPayload;
          final draft = state.draft;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              // Privacy Guarantee Pill
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.emeraldDark,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Zero PII leaves your phone. Only redacted clause excerpts and your city are sent to Cloud Gemini.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step 1: City & Tone
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Customize for Your City & Tone',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _regionController,
                        decoration: const InputDecoration(
                          labelText: 'City / Region',
                          prefixIcon: Icon(Icons.location_city_rounded),
                        ),
                        onChanged: (value) {
                          context.read<NegotiationBloc>().add(
                                UpdateNegotiationParams(region: value),
                              );
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tones.map((tone) {
                          final selected = state.tone == tone;
                          return ChoiceChip(
                            label: Text(tone),
                            selected: selected,
                            selectedColor:
                                AppColors.indigo.withValues(alpha: 0.18),
                            onSelected: (_) {
                              context.read<NegotiationBloc>().add(
                                    UpdateNegotiationParams(tone: tone),
                                  );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Step 2 & 3: Glass Box Inspect + Cloud Gemini Generate
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: payload == null
                          ? null
                          : () => InspectPayloadSheet.show(context, payload),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Inspect Payload'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.status == NegotiationStatus.generating
                          ? null
                          : () {
                              context.read<NegotiationBloc>().add(
                                    const GenerateCounterOfferRequested(),
                                  );
                            },
                      icon: state.status == NegotiationStatus.generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        draft == null ? 'Generate Email' : 'Regenerate',
                      ),
                    ),
                  ),
                ],
              ),

              if (state.status == NegotiationStatus.failure &&
                  state.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.crimson),
                ),
              ],

              if (draft != null) ...[
                const SizedBox(height: 20),
                HybridTelemetryBar(telemetry: draft.telemetry),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMAIL SUBJECT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.indigo,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          draft.subject,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Divider(height: 24),
                        SelectableText(
                          draft.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (draft.regionalNorms.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.gavel_rounded,
                                size: 18,
                                color: AppColors.emeraldDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Local Tenant Norms (${draft.region})',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...draft.regionalNorms.map(
                            (norm) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(norm)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: draft.fullShareableEmail),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copied to clipboard.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Share.share(
                            draft.fullShareableEmail,
                            subject: draft.subject,
                          );
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                if (widget.onSaveDraft != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _savingDraft
                        ? null
                        : () async {
                            setState(() => _savingDraft = true);
                            try {
                              await widget.onSaveDraft!(draft);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Saved anonymized draft to History.',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _savingDraft = false);
                            }
                          },
                    icon: _savingDraft
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_done_outlined),
                    label: const Text('Save Draft to History'),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
