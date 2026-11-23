import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 3-slide visual onboarding walkthrough explaining LeaseShield's Hybrid AI
/// privacy architecture in plain, judge-friendly language.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_pageIndex < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with brand & Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.emeraldDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LeaseShield',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: const [
                  _IntroSlide(
                    badge: 'STEP 1 • OFFLINE-FIRST OCR',
                    badgeColor: AppColors.emeraldDark,
                    title: 'Spot Unfair Lease Clauses in Seconds',
                    description:
                        'Snap a photo of any rental agreement—or try a built-in sample lease—even in Airplane Mode. LeaseShield flags hidden lock-ins, non-refundable deposits, and unfair entry terms.',
                    visual: _SlideOneVisual(),
                  ),
                  _IntroSlide(
                    badge: 'STEP 2 • 100% ON-DEVICE AI',
                    badgeColor: AppColors.emeraldDark,
                    title: 'Your Personal Data Never Leaves Your Phone',
                    description:
                        'Powered by Firebase AI Logic Hybrid Inference (Gemini Nano / Apple Foundation Models). Names, SSN/Aadhaar, phone numbers, bank accounts, and addresses are scrubbed locally.',
                    visual: _SlideTwoVisual(),
                  ),
                  _IntroSlide(
                    badge: 'STEP 3 • GLASS BOX CLOUD AI',
                    badgeColor: AppColors.indigo,
                    title: 'Negotiate With Confidence & Full Transparency',
                    description:
                        'Before drafting a landlord counter-offer with Cloud Gemini, inspect the exact JSON leaving your device—visually proving zero PII is ever transmitted.',
                    visual: _SlideThreeVisual(),
                  ),
                ],
              ),
            ),

            // Page indicator + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (idx) {
                      final active = idx == _pageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: active ? 28 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.deepNavy
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      _pageIndex == _totalPages - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _pageIndex == _totalPages - 1
                          ? 'Start Scanning Leases'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.visual,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String description;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          visual,
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedSlate,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideOneVisual extends StatelessWidget {
  const _SlideOneVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.emerald.withValues(alpha: 0.14),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: AppColors.emeraldDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apartment Lease — Page 1',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    Text(
                      'On-Device ML Kit OCR • Works Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _VisualFlagRow(
            color: AppColors.crimson,
            label: 'HIGH RISK',
            text: 'Landlord may enter without prior notice',
          ),
          const SizedBox(height: 8),
          const _VisualFlagRow(
            color: AppColors.amberDark,
            label: 'WARNING',
            text: 'Auto-renews for 12 months with 20% hike',
          ),
        ],
      ),
    );
  }
}

class _SlideTwoVisual extends StatelessWidget {
  const _SlideTwoVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.memory_rounded,
                  size: 14,
                  color: AppColors.emeraldDark,
                ),
                SizedBox(width: 6),
                Text(
                  'ON-DEVICE • Gemini Nano 4 • 340ms',
                  style: TextStyle(
                    color: AppColors.emeraldDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _RedactionPair(
            before: 'Tenant: Jordan Rivera',
            after: 'Tenant: [REDACTED_NAME]',
          ),
          const SizedBox(height: 8),
          const _RedactionPair(
            before: 'SSN: 123-45-6789',
            after: 'SSN: [REDACTED_ID]',
          ),
          const SizedBox(height: 8),
          const _RedactionPair(
            before: 'A/C: 482910384721',
            after: 'A/C: [REDACTED_BANK]',
          ),
        ],
      ),
    );
  }
}

class _SlideThreeVisual extends StatelessWidget {
  const _SlideThreeVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_done_rounded,
                  size: 14,
                  color: AppColors.indigo,
                ),
                SizedBox(width: 6),
                Text(
                  'IN-CLOUD • gemini-2.5-flash • 1,120ms',
                  style: TextStyle(
                    color: AppColors.indigo,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: AppColors.emeraldDark,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Glass Box Verified: 0 PII sent to Cloud',
                    style: TextStyle(
                      color: AppColors.emeraldDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Subject: Proposed Revisions to Rental Agreement',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dear [Landlord Name], I would love to move forward once we align the 24-hour notice and deposit return terms with local tenant norms...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedSlate,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualFlagRow extends StatelessWidget {
  const _VisualFlagRow({
    required this.color,
    required this.label,
    required this.text,
  });

  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedactionPair extends StatelessWidget {
  const _RedactionPair({
    required this.before,
    required this.after,
  });

  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            before,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedSlate,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: AppColors.emeraldDark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            after,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emeraldDark,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
