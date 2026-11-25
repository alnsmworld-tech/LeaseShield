import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/remote_config_service.dart';
import '../../../core/hybrid_ai/hybrid_ai_models.dart';
import '../../../core/hybrid_ai/hybrid_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/lease_document_service.dart';
import '../data/lease_ocr_service.dart';
import '../data/sample_leases.dart';

/// Simple, high-trust Lease Scanner & Instant Demo Home Screen.
class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    required this.ocrService,
    required this.documentService,
    required this.hybridAiService,
    required this.remoteConfigService,
    required this.onAnalyzeLease,
  });

  final LeaseOcrService ocrService;
  final LeaseDocumentService documentService;
  final HybridAiService hybridAiService;
  final RemoteConfigService remoteConfigService;
  final void Function({
    required String title,
    required String region,
    required String rawLeaseText,
    required InferenceMode mode,
  }) onAnalyzeLease;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late InferenceMode _selectedMode;
  DeviceAiCapabilities? _capabilities;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = InferenceMode.fromWireValue(
      widget.remoteConfigService.defaultTriageMode,
    );
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    final caps = await widget.hybridAiService.getCapabilities();
    if (mounted) setState(() => _capabilities = caps);
  }

  Future<void> _handleImageScan(ImageSource source) async {
    setState(() => _scanning = true);
    try {
      final extracted = await widget.ocrService.scanFromSource(source);
      if (!mounted) return;
      if (extracted == null || extracted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text recognized. Try a clearer photo of the lease.'),
          ),
        );
        return;
      }
      widget.onAnalyzeLease(
        title: source == ImageSource.camera
            ? 'Scanned Lease Page'
            : 'Uploaded Lease Photo',
        region: 'United States',
        rawLeaseText: extracted,
        mode: _selectedMode,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('On-device OCR error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _handleDocumentUpload() async {
    setState(() => _scanning = true);
    try {
      final doc = await widget.documentService.pickAndExtractDocument();
      if (!mounted || doc == null) return;
      if (doc.extractedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No selectable text found in this PDF. Try taking a photo or screenshot with Scan Camera / Pick Photo.',
            ),
          ),
        );
        return;
      }
      widget.onAnalyzeLease(
        title: doc.fileName,
        region: 'United States',
        rawLeaseText: doc.extractedText,
        mode: _selectedMode,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document read error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _openPasteLeaseDialog() async {
    final titleCtrl = TextEditingController(text: 'Custom Rental Agreement');
    final regionCtrl = TextEditingController(text: 'Austin, TX');
    final textCtrl = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste Lease Text',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Processed 100% locally on your device first.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppColors.emeraldDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Lease Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regionCtrl,
                decoration: const InputDecoration(labelText: 'City / Region'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Paste lease clauses here...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.shield_rounded),
                label: const Text('Redact & Analyze Locally'),
              ),
            ],
          ),
        );
      },
    );

    if (submitted == true && textCtrl.text.trim().isNotEmpty) {
      widget.onAnalyzeLease(
        title: titleCtrl.text.trim().isEmpty
            ? 'Custom Rental Agreement'
            : titleCtrl.text.trim(),
        region: regionCtrl.text.trim().isEmpty
            ? 'General'
            : regionCtrl.text.trim(),
        rawLeaseText: textCtrl.text.trim(),
        mode: _selectedMode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsLabel = _capabilities == null
        ? 'Checking device AI...'
        : '${_capabilities!.onDeviceModelName} • '
            '${_capabilities!.onDeviceSupported ? "On-Device Ready" : "Local Engine Ready"}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // Simple 3-Step Visual Explainer Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: AppColors.emeraldDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            capsLabel,
                            style: const TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Check your lease before you sign.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Personal info is redacted locally on your phone before any cloud negotiation draft.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedSlate,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    _MiniStep(number: '1', label: 'Scan'),
                    _StepConnector(),
                    _MiniStep(number: '2', label: 'Redact Locally'),
                    _StepConnector(),
                    _MiniStep(number: '3', label: 'Counter-Offer'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Primary Scan Actions
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _scanning
                    ? null
                    : () => _handleImageScan(ImageSource.camera),
                icon: _scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.document_scanner_rounded),
                label: const Text('Scan Camera'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanning
                    ? null
                    : () => _handleImageScan(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick Photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanning ? null : _handleDocumentUpload,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload PDF / TXT'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanning ? null : _openPasteLeaseDialog,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Paste Text'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Clean AI Mode Selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hybrid AI Mode',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<InferenceMode>(
                    segments: const [
                      ButtonSegment<InferenceMode>(
                        value: InferenceMode.onlyOnDevice,
                        icon: Icon(Icons.offline_bolt_rounded, size: 16),
                        label: Text('On-Device Only'),
                      ),
                      ButtonSegment<InferenceMode>(
                        value: InferenceMode.preferOnDevice,
                        icon: Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text('Hybrid Auto'),
                      ),
                    ],
                    selected: {_selectedMode},
                    onSelectionChanged: (selected) {
                      setState(() => _selectedMode = selected.first);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedMode == InferenceMode.onlyOnDevice
                      ? '100% offline. Runs strictly on your device—zero network calls.'
                      : 'Tries on-device AI first. If unsupported, scrubs PII locally before Cloud Gemini.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedSlate,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Instant Demo Leases
        Row(
          children: [
            Text(
              'Try an Instant Demo Lease',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Works Offline',
                style: TextStyle(
                  color: AppColors.emeraldDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pre-loaded with realistic fake PII so you can test in 1 tap.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedSlate,
          ),
        ),
        const SizedBox(height: 12),
        ...SampleLeases.all.map(
          (sample) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                widget.onAnalyzeLease(
                  title: sample.title,
                  region: sample.region,
                  rawLeaseText: sample.rawText,
                  mode: _selectedMode,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppColors.crimson,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sample.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sample.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedSlate,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${sample.region} • ${sample.tag}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.emeraldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mutedSlate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStep extends StatelessWidget {
  const _MiniStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: AppColors.deepNavy,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.lightBorder,
      ),
    );
  }
}
