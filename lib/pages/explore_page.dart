import 'package:flutter/material.dart';
import 'user_dashboard.dart';
import 'dashboard_page.dart' show OppGrid;

// ===========================================================================
// EXPLORE PAGE
// ===========================================================================

class ExplorePage extends StatefulWidget {
  final List<Opp> opps;
  final void Function(Opp) onSubmit;
  final bool examPassed;
  final bool paymentComplete;
  final VoidCallback onGoToOnboarding;

  const ExplorePage({
    super.key,
    required this.opps,
    required this.onSubmit,
    required this.examPassed,
    required this.paymentComplete,
    required this.onGoToOnboarding,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.opps
        .where((o) =>
            o.title.toLowerCase().contains(_q.toLowerCase()) ||
            (o.description?.toLowerCase().contains(_q.toLowerCase()) ?? false))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Explore opportunities',
          style: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 14),

        // ── Payment incomplete warning banner ──────────────────────────────
        if (!widget.paymentComplete) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update your payment information to unlock the onboarding exam and all opportunities.',
                  style: TextStyle(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // Search bar
        GlassContainer(
          padding: EdgeInsets.zero,
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(color: textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Search opportunities...',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search_rounded, color: textMuted, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        OppGrid(
          opps: filtered,
          onSubmit: widget.onSubmit,
          examPassed: widget.examPassed,
          onGoToOnboarding: widget.onGoToOnboarding,
        ),
      ]),
    );
  }
}