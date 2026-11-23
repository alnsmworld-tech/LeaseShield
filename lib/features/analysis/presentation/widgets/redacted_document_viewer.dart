import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Displays the redacted lease text with emerald-highlighted `[REDACTED_*]` tokens
/// so judges and users can visually verify zero PII remains.
class RedactedDocumentViewer extends StatelessWidget {
  const RedactedDocumentViewer({
    super.key,
    required this.redactedText,
    required this.redactionCounts,
  });

  final String redactedText;
  final Map<String, int> redactionCounts;

  static final RegExp _tokenRegex = RegExp(r'\[REDACTED_[A-Z_]+\]');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _tokenRegex.allMatches(redactedText)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: redactedText.substring(lastEnd, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              fontFamily: 'monospace',
            ),
          ),
        );
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              match.group(0)!,
              style: const TextStyle(
                color: AppColors.emerald,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < redactedText.length) {
      spans.add(
        TextSpan(
          text: redactedText.substring(lastEnd),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (redactionCounts.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: redactionCounts.entries.map((entry) {
              return Chip(
                avatar: const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: AppColors.emerald,
                ),
                label: Text('${entry.value} ${entry.key} Redacted'),
                backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                side: BorderSide(
                  color: AppColors.emerald.withValues(alpha: 0.4),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText.rich(TextSpan(children: spans)),
          ),
        ),
      ],
    );
  }
}
