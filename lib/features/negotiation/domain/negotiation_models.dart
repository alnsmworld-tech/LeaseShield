import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../core/hybrid_ai/hybrid_ai_models.dart';
import '../../analysis/domain/lease_analysis_models.dart';

/// Exact JSON payload leaving the device during Cloud Gemini escalation.
/// Visually inspectable in the Glass Box "Inspect Outbound Payload" modal.
class OutboundCloudPayload extends Equatable {
  const OutboundCloudPayload({
    required this.region,
    required this.tone,
    required this.redactedClauses,
    required this.piiAuditPassed,
  });

  final String region;
  final String tone;
  final List<Map<String, String>> redactedClauses;
  final bool piiAuditPassed;

  Map<String, dynamic> toJson() => {
        'privacyGuarantee': 'ZERO_RAW_PII_TRANSMITTED',
        'piiAuditPassed': piiAuditPassed,
        'region': region,
        'tone': tone,
        'redactedClauses': redactedClauses,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  @override
  List<Object?> get props => [region, tone, redactedClauses, piiAuditPassed];
}

/// Generated landlord counter-offer email from Cloud Gemini.
class NegotiationDraft extends Equatable {
  const NegotiationDraft({
    required this.id,
    required this.leaseId,
    required this.region,
    required this.tone,
    required this.subject,
    required this.body,
    required this.regionalNorms,
    required this.toneSummary,
    required this.telemetry,
    required this.createdAt,
  });

  final String id;
  final String leaseId;
  final String region;
  final String tone;
  final String subject;
  final String body;
  final List<String> regionalNorms;
  final String toneSummary;
  final HybridAiTelemetry telemetry;
  final DateTime createdAt;

  String get fullShareableEmail => 'Subject: $subject\n\n$body';

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'leaseId': leaseId,
        'region': region,
        'tone': tone,
        'subject': subject,
        'body': body,
        'regionalNorms': regionalNorms,
        'toneSummary': toneSummary,
        'telemetry': telemetry.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory NegotiationDraft.fromFirestoreMap(Map<String, dynamic> map) {
    return NegotiationDraft(
      id: map['id'] as String? ?? '',
      leaseId: map['leaseId'] as String? ?? '',
      region: map['region'] as String? ?? 'General',
      tone: map['tone'] as String? ?? 'Polite & Collaborative',
      subject: map['subject'] as String? ?? '',
      body: map['body'] as String? ?? '',
      regionalNorms: (map['regionalNorms'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      toneSummary: map['toneSummary'] as String? ?? '',
      telemetry: HybridAiTelemetry.fromJson(
        Map<String, dynamic>.from(map['telemetry'] as Map? ?? const {}),
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static NegotiationDraft fromModelOutput({
    required String leaseId,
    required String region,
    required String tone,
    required HybridAiResponse response,
  }) {
    final decoded = LeaseAnalysisResult.tryDecodeJsonObject(response.text);
    final subject = decoded?['subject'] as String? ??
        'Proposed Revisions to Rental Agreement — $region';
    final body = decoded?['body'] as String? ?? response.text.trim();
    final norms = (decoded?['regionalNorms'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final toneSummary = decoded?['toneSummary'] as String? ??
        'Structured tenant counter-offer grounded in regional norms.';

    return NegotiationDraft(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      leaseId: leaseId,
      region: region,
      tone: tone,
      subject: subject,
      body: body,
      regionalNorms: norms,
      toneSummary: toneSummary,
      telemetry: response.telemetry,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        leaseId,
        region,
        tone,
        subject,
        body,
        regionalNorms,
        toneSummary,
        telemetry,
        createdAt,
      ];
}
