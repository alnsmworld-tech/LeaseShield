import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../core/hybrid_ai/hybrid_ai_models.dart';

enum ClauseSeverity {
  high('HIGH'),
  medium('MEDIUM'),
  low('LOW');

  const ClauseSeverity(this.label);
  final String label;

  static ClauseSeverity fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'HIGH':
        return ClauseSeverity.high;
      case 'MEDIUM':
        return ClauseSeverity.medium;
      default:
        return ClauseSeverity.low;
    }
  }
}

/// A single predatory or risky lease clause identified during on-device triage.
class RiskyClause extends Equatable {
  const RiskyClause({
    required this.id,
    required this.title,
    required this.severity,
    required this.category,
    required this.excerpt,
    required this.explanation,
    required this.recommendation,
    this.selectedForNegotiation = true,
  });

  final String id;
  final String title;
  final ClauseSeverity severity;
  final String category;
  final String excerpt;
  final String explanation;
  final String recommendation;
  final bool selectedForNegotiation;

  RiskyClause copyWith({
    bool? selectedForNegotiation,
  }) {
    return RiskyClause(
      id: id,
      title: title,
      severity: severity,
      category: category,
      excerpt: excerpt,
      explanation: explanation,
      recommendation: recommendation,
      selectedForNegotiation:
          selectedForNegotiation ?? this.selectedForNegotiation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'severity': severity.label,
        'category': category,
        'excerpt': excerpt,
        'explanation': explanation,
        'recommendation': recommendation,
      };

  factory RiskyClause.fromJson(Map<String, dynamic> json, int index) {
    return RiskyClause(
      id: json['id'] as String? ?? 'clause_$index',
      title: json['title'] as String? ?? 'Flagged Clause',
      severity: ClauseSeverity.fromString(json['severity'] as String?),
      category: json['category'] as String? ?? 'Other',
      excerpt: json['excerpt'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        severity,
        category,
        excerpt,
        explanation,
        recommendation,
        selectedForNegotiation,
      ];
}

/// Complete, strictly anonymized result of analyzing a rental lease.
/// Never stores raw unredacted text.
class LeaseAnalysisResult extends Equatable {
  const LeaseAnalysisResult({
    required this.id,
    required this.title,
    required this.region,
    required this.redactedText,
    required this.overallRiskScore,
    required this.summary,
    required this.clauses,
    required this.redactionCounts,
    required this.telemetry,
    required this.analyzedAt,
  });

  final String id;
  final String title;
  final String region;
  final String redactedText;
  final int overallRiskScore;
  final String summary;
  final List<RiskyClause> clauses;
  final Map<String, int> redactionCounts;
  final HybridAiTelemetry telemetry;
  final DateTime analyzedAt;

  int get totalRedactions =>
      redactionCounts.values.fold(0, (sum, count) => sum + count);

  int get highRiskCount =>
      clauses.where((c) => c.severity == ClauseSeverity.high).length;

  List<RiskyClause> get selectedClauses =>
      clauses.where((c) => c.selectedForNegotiation).toList();

  LeaseAnalysisResult copyWith({
    List<RiskyClause>? clauses,
  }) {
    return LeaseAnalysisResult(
      id: id,
      title: title,
      region: region,
      redactedText: redactedText,
      overallRiskScore: overallRiskScore,
      summary: summary,
      clauses: clauses ?? this.clauses,
      redactionCounts: redactionCounts,
      telemetry: telemetry,
      analyzedAt: analyzedAt,
    );
  }

  /// Serializes ONLY anonymized, redacted data for Firestore storage.
  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'title': title,
        'region': region,
        'redactedText': redactedText,
        'overallRiskScore': overallRiskScore,
        'summary': summary,
        'clauses': clauses.map((c) => c.toJson()).toList(),
        'redactionCounts': redactionCounts,
        'telemetry': telemetry.toJson(),
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory LeaseAnalysisResult.fromFirestoreMap(Map<String, dynamic> map) {
    final rawClauses = (map['clauses'] as List<dynamic>? ?? const []);
    final clauses = rawClauses
        .asMap()
        .entries
        .map(
          (e) => RiskyClause.fromJson(
            Map<String, dynamic>.from(e.value as Map),
            e.key,
          ),
        )
        .toList();

    final rawCounts =
        Map<String, dynamic>.from(map['redactionCounts'] as Map? ?? const {});
    final counts = rawCounts.map((k, v) => MapEntry(k, (v as num).toInt()));

    return LeaseAnalysisResult(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Analyzed Lease',
      region: map['region'] as String? ?? 'General',
      redactedText: map['redactedText'] as String? ?? '',
      overallRiskScore: (map['overallRiskScore'] as num?)?.toInt() ?? 0,
      summary: map['summary'] as String? ?? '',
      clauses: clauses,
      redactionCounts: counts,
      telemetry: HybridAiTelemetry.fromJson(
        Map<String, dynamic>.from(map['telemetry'] as Map? ?? const {}),
      ),
      analyzedAt: DateTime.tryParse(map['analyzedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Extracts clean JSON from model output (tolerates markdown code fences).
  static Map<String, dynamic>? tryDecodeJsonObject(String rawOutput) {
    var cleaned = rawOutput.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace <= firstBrace) return null;
    try {
      final decoded = jsonDecode(cleaned.substring(firstBrace, lastBrace + 1));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        region,
        redactedText,
        overallRiskScore,
        summary,
        clauses,
        redactionCounts,
        telemetry,
        analyzedAt,
      ];
}
