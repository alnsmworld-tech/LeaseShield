import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/firebase_bootstrap.dart';
import '../../../core/hybrid_ai/local_pii_scrubber.dart';
import '../../analysis/domain/lease_analysis_models.dart';
import '../../negotiation/domain/negotiation_models.dart';

/// Combined anonymized record stored under `users/{uid}/leases/{leaseId}`.
class SavedLeaseRecord extends Equatable {
  const SavedLeaseRecord({
    required this.analysis,
    this.draft,
  });

  final LeaseAnalysisResult analysis;
  final NegotiationDraft? draft;

  @override
  List<Object?> get props => [analysis, draft];
}

/// Persists ONLY redacted lease analyses and counter-offer drafts to Cloud Firestore
/// under `users/{uid}/leases/{leaseId}`, with automatic offline/local fallback.
class LeaseHistoryRepository {
  LeaseHistoryRepository({
    required LocalPiiScrubber piiScrubber,
    required FirebaseBootstrapResult bootstrapResult,
  })  : _piiScrubber = piiScrubber,
        _bootstrapResult = bootstrapResult;

  final LocalPiiScrubber _piiScrubber;
  final FirebaseBootstrapResult _bootstrapResult;
  final List<SavedLeaseRecord> _localCache = [];

  bool get isCloudSyncActive =>
      _bootstrapResult.firebaseReady && FirebaseAuth.instance.currentUser != null;

  String? get currentUid =>
      _bootstrapResult.firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;

  CollectionReference<Map<String, dynamic>>? _userLeasesCollection() {
    if (!isCloudSyncActive) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('leases');
  }

  /// Saves an anonymized [LeaseAnalysisResult]. Defense-in-depth scrubbing
  /// guarantees raw unredacted text is never written to Firestore.
  Future<void> saveAnalysis(LeaseAnalysisResult analysis) async {
    final safeAnalysis = LeaseAnalysisResult(
      id: analysis.id,
      title: analysis.title,
      region: analysis.region,
      redactedText: _piiScrubber.scrub(analysis.redactedText).redactedText,
      overallRiskScore: analysis.overallRiskScore,
      summary: _piiScrubber.scrub(analysis.summary).redactedText,
      clauses: analysis.clauses,
      redactionCounts: analysis.redactionCounts,
      telemetry: analysis.telemetry,
      analyzedAt: analysis.analyzedAt,
    );

    _upsertLocal(SavedLeaseRecord(analysis: safeAnalysis));

    final col = _userLeasesCollection();
    if (col != null) {
      try {
        await col.doc(safeAnalysis.id).set(
          {
            'analysis': safeAnalysis.toFirestoreMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('[LeaseShield] Firestore saveAnalysis fallback: $e');
      }
    }
  }

  /// Attaches an anonymized [NegotiationDraft] to an existing lease document.
  Future<void> saveDraft(
    LeaseAnalysisResult analysis,
    NegotiationDraft draft,
  ) async {
    final safeDraft = NegotiationDraft(
      id: draft.id,
      leaseId: draft.leaseId,
      region: draft.region,
      tone: draft.tone,
      subject: _piiScrubber.scrub(draft.subject).redactedText,
      body: _piiScrubber.scrub(draft.body).redactedText,
      regionalNorms: draft.regionalNorms,
      toneSummary: draft.toneSummary,
      telemetry: draft.telemetry,
      createdAt: draft.createdAt,
    );

    _upsertLocal(SavedLeaseRecord(analysis: analysis, draft: safeDraft));

    final col = _userLeasesCollection();
    if (col != null) {
      try {
        await col.doc(analysis.id).set(
          {
            'analysis': analysis.toFirestoreMap(),
            'draft': safeDraft.toFirestoreMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('[LeaseShield] Firestore saveDraft fallback: $e');
      }
    }
  }

  Future<List<SavedLeaseRecord>> fetchHistory() async {
    final col = _userLeasesCollection();
    if (col != null) {
      try {
        final snapshot =
            await col.orderBy('updatedAt', descending: true).limit(30).get();
        final remote = snapshot.docs.map((doc) {
          final data = doc.data();
          final analysisMap =
              Map<String, dynamic>.from(data['analysis'] as Map? ?? const {});
          final draftMap = data['draft'] as Map?;
          return SavedLeaseRecord(
            analysis: LeaseAnalysisResult.fromFirestoreMap(analysisMap),
            draft: draftMap == null
                ? null
                : NegotiationDraft.fromFirestoreMap(
                    Map<String, dynamic>.from(draftMap),
                  ),
          );
        }).toList();
        if (remote.isNotEmpty) {
          _localCache
            ..clear()
            ..addAll(remote);
        }
      } catch (e) {
        debugPrint('[LeaseShield] Firestore fetchHistory fallback: $e');
      }
    }
    return List.unmodifiable(_localCache);
  }

  Future<void> deleteRecord(String leaseId) async {
    _localCache.removeWhere((r) => r.analysis.id == leaseId);
    final col = _userLeasesCollection();
    if (col != null) {
      try {
        await col.doc(leaseId).delete();
      } catch (e) {
        debugPrint('[LeaseShield] Firestore deleteRecord warning: $e');
      }
    }
  }

  void _upsertLocal(SavedLeaseRecord record) {
    final idx =
        _localCache.indexWhere((r) => r.analysis.id == record.analysis.id);
    if (idx >= 0) {
      _localCache[idx] = SavedLeaseRecord(
        analysis: record.analysis,
        draft: record.draft ?? _localCache[idx].draft,
      );
    } else {
      _localCache.insert(0, record);
    }
  }
}
