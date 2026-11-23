import 'dart:convert';

import 'local_pii_scrubber.dart';

/// Deterministic, offline rule-based red-flag detector used as a zero-crash
/// fallback when running offline on devices without Gemini Nano / Apple Foundation Models.
class LocalClauseDetector {
  LocalClauseDetector(this._scrubber);

  final LocalPiiScrubber _scrubber;

  /// Produces a valid JSON string matching LeaseShield's structured triage schema.
  String analyzeLocallyAsJson(String rawLeaseText) {
    final scrubbed = _scrubber.scrub(rawLeaseText);
    final text = scrubbed.redactedText;
    final clauses = <Map<String, dynamic>>[];

    final rules = <_ClauseRule>[
      _ClauseRule(
        id: 'entry_without_notice',
        title: 'Landlord Entry Without Notice',
        severity: 'HIGH',
        category: 'Entry',
        pattern: RegExp(
          r'[^.\n]*(?:enter|entry|access)[^.\n]*(?:without\s+(?:prior\s+)?notice|at\s+any\s+time|unannounced)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Allows the landlord to enter the rental unit without reasonable advance notice, violating standard quiet-enjoyment protections.',
        recommendation:
            'Require at least 24–48 hours written notice before non-emergency entry during reasonable daytime hours.',
      ),
      _ClauseRule(
        id: 'non_refundable_deposit',
        title: 'Non-Refundable Deposit or Arbitrary Forfeiture',
        severity: 'HIGH',
        category: 'Deposit',
        pattern: RegExp(
          r'[^.\n]*(?:security\s+deposit|deposit)[^.\n]*(?:non-refundable|forfeit|sole\s+discretion|90\s+days|60\s+days|3\s+months|three\s+months)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Excessive deposit amounts, non-refundable clauses, or delayed return timelines expose the tenant to unfair withholding.',
        recommendation:
            'Cap security deposit at local statutory limits and require itemized return within 14–30 days of move-out.',
      ),
      _ClauseRule(
        id: 'lock_in_penalty',
        title: 'Punitive Lock-In / Early Termination Penalty',
        severity: 'HIGH',
        category: 'Lock-In',
        pattern: RegExp(
          r'[^.\n]*(?:lock-in|early\s+termination|vacate\s+early|break\s+the\s+lease)[^.\n]*(?:forfeit|remaining\s+months|full\s+balance|penalty|liquidated\s+damages)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Requires paying the entire remaining lease balance or forfeiting deposits without requiring the landlord to mitigate damages.',
        recommendation:
            'Add a reasonable break-lease cap (e.g., 1 month rent) and require landlord duty to re-rent and mitigate damages.',
      ),
      _ClauseRule(
        id: 'auto_renewal_trap',
        title: 'Automatic Renewal Trap',
        severity: 'MEDIUM',
        category: 'Renewal',
        pattern: RegExp(
          r'[^.\n]*(?:automatically\s+renew|auto-renew)[^.\n]*(?:90\s+days|60\s+days|another\s+12\s+months|full\s+year|15%|20%)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Locks the tenant into another full term (often with a steep rent hike) unless notice is given months in advance.',
        recommendation:
            'Convert post-term tenancy to month-to-month with a 30-day mutual notice window and explicit rent-increase cap.',
      ),
      _ClauseRule(
        id: 'liability_waiver',
        title: 'Habitability / Liability Waiver',
        severity: 'HIGH',
        category: 'Liability',
        pattern: RegExp(
          r'[^.\n]*(?:waives?\s+(?:all\s+)?(?:rights?|claims?|liability)|as-is|not\s+responsible\s+for\s+(?:repairs?|structural|plumbing|mold|negligence)|sole\s+expense\s+of\s+tenant)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Attempts to shift structural maintenance or landlord negligence onto the tenant, which is often unenforceable under habitability laws.',
        recommendation:
            'Confirm landlord responsibility for structural, plumbing, electrical, and HVAC repairs and remove negligence waivers.',
      ),
      _ClauseRule(
        id: 'excessive_late_fee',
        title: 'Punitive Late Fee / Grace Period',
        severity: 'MEDIUM',
        category: 'Fees',
        pattern: RegExp(
          r'[^.\n]*(?:late\s+fee|per\s+day|daily\s+penalty|compounding|10%|15%)[^.\n]*(?:rent|overdue|late|due\s+date)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Daily compounding or high percentage late fees with no grace period can rapidly escalate into punitive charges.',
        recommendation:
            'Request a 5-day grace period and a flat, capped late fee (typically 3–5% of monthly rent).',
      ),
      _ClauseRule(
        id: 'unilateral_modification',
        title: 'Unilateral Rules / Rent Modification',
        severity: 'MEDIUM',
        category: 'Termination',
        pattern: RegExp(
          r'[^.\n]*(?:modify|change|increase\s+rent|amend)[^.\n]*(?:sole\s+discretion|without\s+consent|at\s+any\s+time|7\s+days)[^.\n]*\.?',
          caseSensitive: false,
        ),
        explanation:
            'Permits the landlord to alter house rules or charges mid-lease without mutual written agreement.',
        recommendation:
            'Require mutual written consent for any material amendment to lease terms or fees during the fixed term.',
      ),
    ];

    for (final rule in rules) {
      final match = rule.pattern.firstMatch(text);
      if (match != null) {
        final excerpt = match.group(0)?.trim() ?? '';
        clauses.add({
          'id': rule.id,
          'title': rule.title,
          'severity': rule.severity,
          'category': rule.category,
          'excerpt': excerpt,
          'explanation': rule.explanation,
          'recommendation': rule.recommendation,
        });
      }
    }

    final highCount = clauses.where((c) => c['severity'] == 'HIGH').length;
    final medCount = clauses.where((c) => c['severity'] == 'MEDIUM').length;
    final score = (highCount * 24 + medCount * 12).clamp(8, 96);

    final summary = clauses.isEmpty
        ? 'No major predatory patterns were flagged by the offline rule engine. Review standard dates and deposit terms carefully before signing.'
        : 'Flagged ${clauses.length} risky clause(s) ($highCount high-risk, $medCount medium-risk) locally on-device with ${scrubbed.totalRedactions} PII item(s) scrubbed.';

    return jsonEncode({
      'redactedText': text,
      'overallRiskScore': score,
      'summary': summary,
      'clauses': clauses,
    });
  }
}

class _ClauseRule {
  const _ClauseRule({
    required this.id,
    required this.title,
    required this.severity,
    required this.category,
    required this.pattern,
    required this.explanation,
    required this.recommendation,
  });

  final String id;
  final String title;
  final String severity;
  final String category;
  final RegExp pattern;
  final String explanation;
  final String recommendation;
}
