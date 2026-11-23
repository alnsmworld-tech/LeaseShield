import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/lease_analysis_models.dart';

/// Material 3 card presenting a single flagged predatory/risky lease clause.
class RedFlagClauseCard extends StatelessWidget {
  const RedFlagClauseCard({
    super.key,
    required this.clause,
    required this.onToggleSelected,
  });

  final RiskyClause clause;
  final VoidCallback onToggleSelected;

  Color get _severityColor {
    switch (clause.severity) {
      case ClauseSeverity.high:
        return AppColors.crimson;
      case ClauseSeverity.medium:
        return AppColors.amber;
      case ClauseSeverity.low:
        return AppColors.emerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _severityColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${clause.severity.label} • ${clause.category.toUpperCase()}',
                    style: TextStyle(
                      color: _severityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onToggleSelected,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: clause.selectedForNegotiation,
                        onChanged: (_) => onToggleSelected(),
                        activeColor: AppColors.indigo,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'Negotiate',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              clause.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (clause.excerpt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: _severityColor, width: 3),
                  ),
                ),
                child: Text(
                  '"${clause.excerpt}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              clause.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (clause.recommendation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suggested Ask: ${clause.recommendation}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
