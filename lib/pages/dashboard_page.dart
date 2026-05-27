import 'package:flutter/material.dart';
import 'user_dashboard.dart';

// ===========================================================================
// JOBS PAGE
// ===========================================================================

class JobsPage extends StatelessWidget {
  final List<Opp> opps;
  final void Function(Opp) onSubmit;
  final String userEmail;
  final VoidCallback onGoToOnboarding;
  final bool isVerified;
  final bool examPassed;
  final bool paymentComplete;

  const JobsPage({
    super.key,
    required this.opps,
    required this.onSubmit,
    required this.userEmail,
    required this.onGoToOnboarding,
    required this.isVerified,
    required this.examPassed,
    required this.paymentComplete,
  });

  @override
  Widget build(BuildContext context) {
    final open = opps.take(8).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Status banner: changes based on payment + verification + exam state ──
        _StatusBanner(
          isVerified: isVerified,
          examPassed: examPassed,
          paymentComplete: paymentComplete,
          onGoToOnboarding: onGoToOnboarding,
        ),
        const SizedBox(height: 20),
        ShareBanner(userEmail: userEmail),
        const SizedBox(height: 28),
        Row(
          children: [
            const Text(
              'Open opportunities',
              style: TextStyle(
                  color: textPrimary, fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(width: 10),
            // Lock badge when jobs are inactive
            if (!examPassed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Color(0xFFF59E0B), size: 11),
                    SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        OppGrid(
          opps: open,
          onSubmit: onSubmit,
          examPassed: examPassed,
          onGoToOnboarding: onGoToOnboarding,
        ),
      ]),
    );
  }
}

// ===========================================================================
// STATUS BANNER  — adapts to payment + verification + exam state
// ===========================================================================

class _StatusBanner extends StatelessWidget {
  final bool isVerified;
  final bool examPassed;
  final bool paymentComplete;
  final VoidCallback onGoToOnboarding;

  const _StatusBanner({
    required this.isVerified,
    required this.examPassed,
    required this.paymentComplete,
    required this.onGoToOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    // ── 1. Exam passed + verified → success state ──
    if (examPassed && isVerified) {
      return _BannerShell(
        gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
        shadowColor: Color(0xFF10B981),
        icon: Icons.verified_rounded,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re All Set!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Onboarding complete. All opportunities are unlocked.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── 2. Exam passed but NOT verified ──
    if (examPassed && !isVerified) {
      return _BannerShell(
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        shadowColor: Color(0xFFF59E0B),
        icon: Icons.hourglass_top_rounded,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exam Passed — Awaiting Verification',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your account is being reviewed by our team. Opportunities will unlock once approved.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── 3. Payment NOT complete — exam is blocked until payment is done ──
    if (!paymentComplete) {
      return _BannerShell(
        gradientColors: const [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFF59E0B)],
        shadowColor: Color(0xFFF59E0B),
        icon: Icons.payment_rounded,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Complete Payment Info First',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You must update your payment details before you can take the onboarding exam.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Inactive / disabled exam button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.45), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Exam Locked',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── 4. Payment complete, exam NOT passed — active Start Exam state ──
    return GestureDetector(
      onTap: onGoToOnboarding,
      child: _BannerShell(
        gradientColors: const [
          Color(0xFF4F46E5),
          Color(0xFF7C3AED),
          Color(0xFF06B6D4)
        ],
        shadowColor: Color(0xFF6366F1),
        icon: Icons.quiz_rounded,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Complete Onboarding Exam',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pass the exam to unlock full access to all opportunities.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFF4F46E5), size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Start Exam',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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

// ── Reusable gradient shell for all banner states ──
class _BannerShell extends StatelessWidget {
  final List<Color> gradientColors;
  final Color shadowColor;
  final IconData icon;
  final Widget child;

  const _BannerShell({
    required this.gradientColors,
    required this.shadowColor,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SHARE BANNER
// ===========================================================================

class ShareBanner extends StatelessWidget {
  final String userEmail;
  const ShareBanner({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -28,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share with Friends & Earn',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Invite friends to apply for AI projects',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => shareCareerLink(context, userEmail),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          color: Color(0xFF6366F1), size: 15),
                      SizedBox(width: 6),
                      Text('Refer & Earn',
                          style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// OPPORTUNITY GRID & CARD
// ===========================================================================

class OppGrid extends StatelessWidget {
  final List<Opp> opps;
  final void Function(Opp) onSubmit;
  final bool examPassed;
  final VoidCallback onGoToOnboarding;

  const OppGrid({
    super.key,
    required this.opps,
    required this.onSubmit,
    required this.examPassed,
    required this.onGoToOnboarding,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final cols = c.maxWidth > 700 ? 2 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: opps.map((opp) {
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return SizedBox(
              width: w,
              child: OppCard(
                opp: opp,
                onSubmit: () => onSubmit(opp),
                examPassed: examPassed,
                onGoToOnboarding: onGoToOnboarding,
              ),
            );
          }).toList(),
        );
      });
}

class OppCard extends StatelessWidget {
  final Opp opp;
  final VoidCallback onSubmit;
  final bool examPassed;
  final VoidCallback onGoToOnboarding;

  const OppCard({
    super.key,
    required this.opp,
    required this.onSubmit,
    required this.examPassed,
    required this.onGoToOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !examPassed;

    return Stack(
      children: [
        // ── Card body (always rendered, dimmed when locked) ──
        AnimatedOpacity(
          opacity: locked ? 0.45 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(opp.title,
                        style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  Text(opp.rate,
                      style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Text(opp.meta,
                  style: const TextStyle(color: textMuted, fontSize: 12)),
              if (opp.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  opp.description!,
                  style: const TextStyle(
                      color: textSecondary, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              const Divider(color: glassBorder, thickness: 1.5),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(
                  width: 64,
                  height: 24,
                  child: Stack(children: [
                    for (int i = 0; i < 3; i++)
                      Positioned(
                        left: i * 18.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: [
                              primaryMid,
                              secondaryLight,
                              greenLight
                            ][i],
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(width: 6),
                Text(opp.earning,
                    style:
                        const TextStyle(color: textMuted, fontSize: 12)),
                const Spacer(),
                // ── Action button — locked or active ──
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFCBD5E1), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: Color(0xFF94A3B8), size: 13),
                        SizedBox(width: 5),
                        Text(
                          'Locked',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (opp.submitted)
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_rounded, color: primary, size: 15),
                    SizedBox(width: 4),
                    Text('Submitted',
                        style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ])
                else
                  GestureDetector(
                    onTap: onSubmit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Text('Submit interest',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ),
              ]),
            ]),
          ),
        ),

        // ── Lock overlay — tappable to go to exam ──
        if (locked)
          Positioned.fill(
            child: GestureDetector(
              onTap: onGoToOnboarding,
              behavior: HitTestBehavior.translucent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: Color(0xFF6366F1), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Complete exam to unlock',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}