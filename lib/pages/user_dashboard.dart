import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard_page.dart';
import 'explore_page.dart';
import 'onboarding_exam_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

// ===========================================================================
// DATATRICKS AI — PORTAL  (Glassmorphism / White Theme)
// Nav: Jobs · Explore · Onboarding · Profile · Settings
// ===========================================================================

// ── COLOUR PALETTE ──────────────────────────────────────────────────────────
const bgGradientTop = Color(0xFFF8FAFC);
const bgGradientBot = Color(0xFFE2E8F0);
const glassWhite    = Color(0xB3FFFFFF);
const glassBorder   = Color(0xFFFFFFFF);

const primary       = Color(0xFF3B82F6);
const primaryLight  = Color(0xFFEFF6FF);
const primaryMid    = Color(0xFF93C5FD);
const secondary     = Color(0xFF10B981);
const secondaryLight= Color(0xFFD1FAE5);
const green         = Color(0xFF10B981);
const greenLight    = Color(0xFFD1FAE5);
const amber         = Color(0xFFF59E0B);
const amberLight    = Color(0xFFFEF3C7);
const red           = Color(0xFFEF4444);
const redLight      = Color(0xFFFEE2E2);
const textPrimary   = Color(0xFF0F172A);
const textSecondary = Color(0xFF475569);
const textMuted     = Color(0xFF94A3B8);

// ── NAV ─────────────────────────────────────────────────────────────────────
enum AppNav { jobs, explore, payments, onboarding, profile, settings }

// ===========================================================================
// OPPORTUNITY MODEL
// ===========================================================================

class Opp {
  final String id, title, rate, meta, earning;
  final String? description;
  bool submitted;

  Opp({
    required this.id,
    required this.title,
    required this.rate,
    required this.meta,
    required this.earning,
    this.description,
    this.submitted = false,
  });
}

List<Opp> buildOpps() => [
  Opp(id:'music',   title:'Music Projects Interest Form',                     rate:'\$50–85/hr',  meta:'Remote · Contract', earning:'+ 6K more earning',  submitted: true),
  Opp(id:'qgis',    title:'Geospatial Analysis (QGIS) Specialists',            rate:'\$125/hr',    description:'Use your expertise and creativity in QGIS to create projects to help train AI',                                                                                         meta:'Remote · Contract', earning:'+ 8K more earning'),
  Opp(id:'medical', title:'Medical Imaging & 3D Analysis (3D Slicer)',          rate:'\$125/hr',    description:'Use your expertise and creativity in 3D Slicer to create projects to help train AI',                                                                                   meta:'Remote · Contract', earning:'+ 6K more earning'),
  Opp(id:'para',    title:'Scientific Visualization (ParaView) Specialists',    rate:'\$125/hr',    description:'Use your expertise and creativity in ParaView to create projects to help train AI',                                                                                     meta:'Remote · Contract', earning:'+ 5K more earning',  submitted: true),
  Opp(id:'video',   title:'Video Production Specialists',                       rate:'\$125/hr',    description:'Use your expertise and creativity in Lightworks, Shotcut, or OpenShot to create projects to help train AI',                                                              meta:'Remote · Contract', earning:'+ 11K more earning', submitted: true),
  Opp(id:'game',    title:'Game Development Specialists',                       rate:'\$125/hr',    description:'Use your expertise and creativity in Godot, Defold, Solar 3D, Panda 3D or Stride (Xenko) to create projects to help train AI',                                          meta:'Remote · Contract', earning:'+ 13K more earning'),
  Opp(id:'media',   title:'2D & 3D Digital Media Specialists',                  rate:'\$125/hr',    description:'Use your expertise and creativity in GIMP, Inkscape, Krita, Libresprite, or Blender to create projects to help train AI',                                               meta:'Remote · Contract', earning:'+ 7K more earning'),
  Opp(id:'eda',     title:'Electronics Design & Simulation (EDA Tools)',        rate:'\$125/hr',    description:'Use your experience and creativity in KiCAD, LibrePCB, Qucs-s and Ngspice tools to help train AI',                                                                     meta:'Remote · Contract', earning:'+ 3K more earning'),
  Opp(id:'llm',     title:'LLM Response Quality Evaluator',                     rate:'\$18–25/hr',  description:'Evaluate AI-generated responses for quality, accuracy, and helpfulness to improve model performance.',                                                                  meta:'Remote · Contract', earning:'+ 9K more earning'),
  Opp(id:'annot',   title:'Data Annotation Specialist',                         rate:'\$15–20/hr',  description:'Label and categorize datasets to train machine learning models with high precision.',                                                                                   meta:'Remote · Contract', earning:'+ 4K more earning'),
  Opp(id:'safety',  title:'AI Safety & Alignment Reviewer',                     rate:'\$25–35/hr',  description:'Identify harmful, biased, or unsafe AI outputs to improve model safety and alignment.',                                                                                meta:'Remote · Contract', earning:'+ 5K more earning'),
  Opp(id:'write',   title:'Creative Writing Quality Reviewer',                  rate:'\$20–30/hr',  description:'Assess AI-generated creative content for originality, style, and overall coherence.',                                                                                  meta:'Remote · Contract', earning:'+ 6K more earning'),
];

// ===========================================================================
// GLASSMORPHISM HELPER COMPONENT
// ===========================================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: BackdropFilter + ClipRRect on Flutter Web (dart2js / DDC) throws
    // "Unexpected null value" because the engine cannot obtain a compositing
    // layer for the blur in every layout context (e.g. inside Expanded ->
    // SingleChildScrollView).  On web we skip the blur entirely and use a
    // slightly more opaque solid background that preserves the glass look
    // without crashing.
    final innerBox = Container(
      padding: padding,
      decoration: BoxDecoration(
        // On web use a solid semi-transparent white; on native keep the
        // translucent glass colour so BackdropFilter shows through.
        color: color ?? (kIsWeb ? const Color(0xF2FFFFFF) : glassWhite),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (kIsWeb) {
      // No blur on web — just clip and return the box.
      return Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: innerBox,
        ),
      );
    }

    // Native: full glassmorphism with BackdropFilter blur.
    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: innerBox,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// SHARE & EARN — REFERRAL COPY POPUP
// ===========================================================================

const careersUrl = 'https://datatricksai.us/careers';

String buildReferralMessage(String userEmail) =>
    '🚀 Exciting Opportunity — Join DataTricks AI!\n\n'
    'I\'m working on cutting-edge AI data projects with DataTricks AI and thought you\'d be a great fit. '
    'They\'re hiring talented professionals for remote contract roles with competitive hourly rates.\n\n'
    '👉 Apply here: $careersUrl\n\n'
    '📝 IMPORTANT: When filling out the application form, please enter my DataTricks account email '
    'in the referral field — this ensures we\'re both recognised for the partnership.\n\n'
    'My referral email: $userEmail\n\n'
    'Looking forward to working alongside you!';

void shareCareerLink(BuildContext context, String userEmail) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.60),
    transitionDuration: const Duration(milliseconds: 340),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.80, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => ReferralDialog(userEmail: userEmail),
  );
}

class ReferralDialog extends StatefulWidget {
  final String userEmail;
  const ReferralDialog({super.key, required this.userEmail});

  @override
  State<ReferralDialog> createState() => _ReferralDialogState();
}

class _ReferralDialogState extends State<ReferralDialog> {
  bool _copied = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: buildReferralMessage(widget.userEmail)));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenW  = MediaQuery.of(context).size.width;
    final screenH  = MediaQuery.of(context).size.height;
    final isMobile = screenW < 600;
    final dialogW  = isMobile ? screenW * 0.94 : 400.0;
    final hPad     = isMobile ? 18.0 : 24.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogW, maxHeight: screenH * 0.88),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.20), blurRadius: 40, spreadRadius: 2, offset: const Offset(0, 14)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient Header ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -8, top: -8,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Share & Earn',
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('\$300 per successful referral',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ──
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REFERRAL TERMS',
                          style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 10),
                        ReferralTerm(
                          icon: Icons.monetization_on_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFD1FAE5),
                          title: '\$300 reward',
                          body: 'Earned for every person you refer who qualifies.',
                        ),
                        const SizedBox(height: 8),
                        ReferralTerm(
                          icon: Icons.timer_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBg: const Color(0xFFEFF6FF),
                          title: '10 hrs minimum',
                          body: 'Referral qualifies after account creation + 10 hours of paid work.',
                        ),
                        const SizedBox(height: 8),
                        ReferralTerm(
                          icon: Icons.alternate_email_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          iconBg: const Color(0xFFF5F3FF),
                          title: 'Add your email',
                          body: 'Referee must enter your DataTricks account email on the application form.',
                        ),
                        const SizedBox(height: 20),

                        // ── Copy Button ──
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _copied ? null : _handleCopy,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _copied
                                    ? const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_copied ? const Color(0xFF10B981) : const Color(0xFF4F46E5)).withValues(alpha: 0.30),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                      color: Colors.white,
                                      size: 17,
                                      key: ValueKey(_copied),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _copied ? 'Copied!' : 'Copy Invite Link',
                                      key: ValueKey(_copied),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReferralTerm extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, body;

  const ReferralTerm({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE8ECF0), width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title  ',
                  style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                TextSpan(
                  text: body,
                  style: const TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ===========================================================================
// STATUS CHIP HELPERS
// ===========================================================================

Color statusColor(String? s) {
  switch (s) {
    case 'approved': return green;
    case 'rejected': return red;
    case 'reviewing': return amber;
    default: return primary;
  }
}

Color statusBg(String? s) {
  switch (s) {
    case 'approved': return greenLight;
    case 'rejected': return redLight;
    case 'reviewing': return amberLight;
    default: return primaryLight;
  }
}

String statusLabel(String? s) {
  switch (s) {
    case 'approved': return 'Approved';
    case 'rejected': return 'Not Selected';
    case 'reviewing': return 'Under Review';
    default: return 'Pending Review';
  }
}

// ===========================================================================
// STATUS POPUP  (context-aware: different content per status)
// ===========================================================================

void showStatusPopup(BuildContext context, String status) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _StatusPopup(status: status),
  );
}

class _StatusPopup extends StatelessWidget {
  final String status;
  const _StatusPopup({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _popupConfig(status);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: cfg.accentColor.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cfg.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    Container(width: 80, height: 80, decoration: BoxDecoration(color: cfg.accentColor.withValues(alpha: 0.15), shape: BoxShape.circle)),
                    Container(width: 62, height: 62, decoration: BoxDecoration(color: cfg.accentColor.withValues(alpha: 0.25), shape: BoxShape.circle)),
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: cfg.accentColor, shape: BoxShape.circle),
                      child: Icon(cfg.icon, color: Colors.white, size: 24),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(cfg.title, style: TextStyle(color: cfg.titleColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                ]),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cfg.infoBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cfg.accentColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline_rounded, color: cfg.accentColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cfg.infoText, style: TextStyle(color: cfg.titleColor, fontSize: 14, fontWeight: FontWeight.w700, height: 1.4))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text(cfg.body, textAlign: TextAlign.center, style: const TextStyle(color: textSecondary, fontSize: 13, height: 1.6)),
                  if (cfg.steps.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ...cfg.steps.asMap().entries.map((e) => Padding(
                      padding: EdgeInsets.only(bottom: e.key < cfg.steps.length - 1 ? 10 : 0),
                      child: PopupStep(number: '${e.key + 1}', label: e.value, color: cfg.accentColor),
                    )),
                  ],
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: cfg.accentColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: cfg.accentColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopupConfig {
  final Color accentColor;
  final List<Color> headerGradient;
  final Color titleColor;
  final Color infoBg;
  final IconData icon;
  final String title;
  final String infoText;
  final String body;
  final List<String> steps;

  const _PopupConfig({
    required this.accentColor,
    required this.headerGradient,
    required this.titleColor,
    required this.infoBg,
    required this.icon,
    required this.title,
    required this.infoText,
    required this.body,
    this.steps = const [],
  });
}

_PopupConfig _popupConfig(String status) {
  switch (status) {
    case 'approved':
      return const _PopupConfig(
        accentColor: green,
        headerGradient: [Color(0xFFE8FDF1), Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
        titleColor: Color(0xFF065F46),
        infoBg: Color(0xFFECFDF5),
        icon: Icons.verified_rounded,
        title: 'Account Approved',
        infoText: 'You are fully verified and ready to work',
        body: 'Your account has been approved by our HR team. You now have full access to all jobs and earning opportunities.',
      );
    case 'reviewing':
      return const _PopupConfig(
        accentColor: primary,
        headerGradient: [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
        titleColor: Color(0xFF1E40AF),
        infoBg: Color(0xFFEFF6FF),
        icon: Icons.manage_search_rounded,
        title: 'Under Review',
        infoText: 'Our HR team is currently reviewing your profile',
        body: 'Your application is being actively reviewed. This typically takes 1–3 business days. We\'ll notify you once a decision has been made.',
        steps: [
          'Ensure your profile information is complete',
          'For urgent enquiries contact hr@datatricksai.us',
        ],
      );
    case 'rejected':
      return const _PopupConfig(
        accentColor: red,
        headerGradient: [Color(0xFFFEF2F2), Color(0xFFFEE2E2), Color(0xFFFECACA)],
        titleColor: Color(0xFF991B1B),
        infoBg: Color(0xFFFEF2F2),
        icon: Icons.cancel_outlined,
        title: 'Not Selected',
        infoText: 'Your application was not successful this time',
        body: 'Unfortunately your application was not approved. You may reapply in the future or reach out to our team for feedback.',
        steps: [
          'Contact hr@datatricksai.us for feedback',
          'You may reapply after 30 days',
        ],
      );
    default: // pending
      return const _PopupConfig(
        accentColor: amber,
        headerGradient: [Color(0xFFFFF7E6), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        titleColor: Color(0xFF92400E),
        infoBg: Color(0xFFFFF7ED),
        icon: Icons.shield_outlined,
        title: 'Pending Review',
        infoText: 'Persona Verification is Missing',
        body: 'Your account is currently under review. To unlock full access and start earning, please complete your persona verification.',
        steps: [
          'Complete persona verification',
          'Await approval from our HR team. For any approval enquiries, please contact hr@datatricksai.us',
        ],
      );
  }
}

// Keep old name as alias so any other callers still compile
void showPendingReviewPopup(BuildContext context) => showStatusPopup(context, 'pending');

class PopupStep extends StatelessWidget {
  final String number, label;
  final Color color;
  const PopupStep({super.key, required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(child: Text(number, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12))),
    ),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
  ]);
}

// ===========================================================================
// RESET PASSWORD DIALOG
// ===========================================================================

void showResetPasswordDialog(BuildContext context, String email) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => ResetPasswordDialog(email: email),
  );
}

class ResetPasswordDialog extends StatefulWidget {
  final String email;
  const ResetPasswordDialog({super.key, required this.email});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  late TextEditingController _emailCtrl;
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() { _message = 'Please enter an email address.'; _isSuccess = false; });
      return;
    }
    setState(() { _isLoading = true; _message = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _message = 'Success! A password reset link has been sent to $email.';
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() { _message = e.message ?? 'Failed to send reset link.'; _isSuccess = false; });
    } catch (_) {
      setState(() { _message = 'An unexpected error occurred. Please try again.'; _isSuccess = false; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: primary.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 2, offset: const Offset(0, 14)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('Reset Password',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text("We'll send a reset link to your email",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _isSuccess ? greenLight : redLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: (_isSuccess ? green : red).withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: Row(children: [
                          Icon(_isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                              color: _isSuccess ? green : red, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_message!,
                                style: TextStyle(color: _isSuccess ? green : red, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      ),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Email address',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          icon: Icon(Icons.email_outlined, color: primary, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isLoading ? null : _sendReset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primary, Color(0xFF6366F1)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Send Reset Link',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Text('Cancel', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ROOT WIDGET
// ===========================================================================

class UserDashboard extends StatefulWidget {
  final String userEmail;
  const UserDashboard({super.key, required this.userEmail});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  String? _docId;                          // ← store Firestore document ID
  bool _isLoading = true;
  String? _error;

  StreamSubscription<QuerySnapshot>? _userSub; // ← real-time subscription

  AppNav _active = AppNav.jobs;
  bool _navExpanded = true;

  late AnimationController _navAnim;
  late Animation<double>   _navWidth;

  late List<Opp> _opps;

  @override
  void initState() {
    super.initState();
    _opps = buildOpps();
    _navAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _navWidth = Tween<double>(begin: 60, end: 220).animate(
      CurvedAnimation(parent: _navAnim, curve: Curves.easeInOut),
    );
    _navAnim.forward();
    _subscribeUser();
  }

  @override
  void dispose() {
    _userSub?.cancel();  // ← cancel stream to avoid memory leaks
    _navAnim.dispose();
    super.dispose();
  }

  void _toggleNav() {
    setState(() {
      _navExpanded = !_navExpanded;
      _navExpanded ? _navAnim.forward() : _navAnim.reverse();
    });
  }

  // Real-time listener — status chip updates instantly when admin verifies
  void _subscribeUser() {
    _userSub = FirebaseFirestore.instance
        .collection('applications')
        .where('email', isEqualTo: widget.userEmail)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _docId    = snapshot.docs.first.id;      // ← store doc ID for writes
            _userData = snapshot.docs.first.data();
            _isLoading = false;
            _error     = null;
          });
        } else {
          setState(() { _error = 'No application found.'; _isLoading = false; });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() { _error = 'Failed to load profile.'; _isLoading = false; });
      },
    );
  }

  void _logout() => Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);

  void _submitInterest(Opp opp) {
    setState(() => opp.submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Interest submitted for "${opp.title}"'),
      backgroundColor: primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const _Loader();
    if (_error != null) return _ErrorView(error: _error!, onBack: _logout);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientTop, bgGradientBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _navWidth,
            builder: (_, __) => _Sidebar(
              width: _navWidth.value,
              expanded: _navExpanded,
              active: _active,
              onTap: (n) {
                // Block navigation to onboarding if payment is not complete
                final paymentComplete = (_userData?['paymentInfo']?['isComplete'] ?? false) == true;
                if (n == AppNav.onboarding && !paymentComplete) return;
                setState(() => _active = n);
              },
              onToggle: _toggleNav,
              userData: _userData,
              onLogout: _logout,
              userEmail: widget.userEmail,
              paymentComplete: (_userData?['paymentInfo']?['isComplete'] ?? false) == true,
            ),
          ),
          Expanded(child: Column(children: [
            _TopBar(active: _active, userData: _userData, docId: _docId, onMenuTap: _toggleNav),
            Expanded(child: _body()),
          ])),
        ]),
      ),
    );
  }

  Widget _body() {
    final paymentComplete = (_userData?['paymentInfo']?['isComplete'] ?? false) == true;

    switch (_active) {
      case AppNav.jobs:
        final isVerified = (_userData?['status'] ?? '') == 'approved';
        final examPassed = (_userData?['examPassed'] ?? false) == true;
        return JobsPage(
          opps: _opps,
          onSubmit: _submitInterest,
          userEmail: widget.userEmail,
          onGoToOnboarding: () => setState(() => _active = AppNav.onboarding),
          isVerified: isVerified,
          examPassed: examPassed,
          paymentComplete: paymentComplete,
        );
      case AppNav.explore:
        final examPassedExplore = (_userData?['examPassed'] ?? false) == true;
        return ExplorePage(
          opps: _opps,
          onSubmit: _submitInterest,
          examPassed: examPassedExplore,
          paymentComplete: paymentComplete,
          onGoToOnboarding: () => setState(() => _active = AppNav.onboarding),
        );
      case AppNav.payments:
        return const PaymentInfoPage();
      case AppNav.onboarding:
        return OnboardingExamPage(userEmail: widget.userEmail);
      case AppNav.profile:
        return ProfilePage(userData: _userData ?? {}, userEmail: widget.userEmail);
      case AppNav.settings:
        return SettingsPage(
          userData: _userData,
          userEmail: widget.userEmail,
          onLogout: _logout,
        );
    }
  }
}

// ===========================================================================
// SIDEBAR
// ===========================================================================

class _Sidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final AppNav active;
  final ValueChanged<AppNav> onTap;
  final VoidCallback onToggle;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final String userEmail;
  final bool paymentComplete;

  const _Sidebar({
    required this.width,
    required this.expanded,
    required this.active,
    required this.onTap,
    required this.onToggle,
    required this.userData,
    required this.onLogout,
    required this.userEmail,
    required this.paymentComplete,
  });

  static const _items = [
    (AppNav.jobs,        Icons.work_outline_rounded,              'Jobs'),
    (AppNav.explore,     Icons.explore_outlined,                  'Explore'),
    (AppNav.payments,    Icons.account_balance_wallet_outlined,   'Payments'),
    (AppNav.onboarding,  Icons.school_outlined,                   'Onboarding Exam'),
    (AppNav.profile,     Icons.person_outline_rounded,            'Profile'),
    (AppNav.settings,    Icons.settings_outlined,                 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = userData?['firstName'] ?? '';
    final initials  = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          width: width,
          decoration: BoxDecoration(
            color: glassWhite,
            border: const Border(right: BorderSide(color: glassBorder, width: 1.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(2, 0))
            ],
          ),
          child: Column(children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: glassBorder, width: 1.5)),
                ),
                child: Row(children: [
                  Image.asset('assets/images/logo.png', height: 36, width: 36, fit: BoxFit.contain),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'DATATRICKS AI',
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                      ),
                    ),
                  ],
                ]),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                children: [
                  ..._items.map((item) {
                    final isActive = active == item.$1;
                    final isOnboarding = item.$1 == AppNav.onboarding;
                    final isLocked = isOnboarding && !paymentComplete;
                    return _SidebarItem(
                      icon: isLocked ? Icons.lock_outline_rounded : item.$2,
                      label: item.$3,
                      isActive: isActive,
                      expanded: expanded,
                      isLocked: isLocked,
                      onTap: isLocked ? () {} : () => onTap(item.$1),
                    );
                  }),
                  const SizedBox(height: 12),
                  // ── Onboarding Exam Banner ──
                  _OnboardingExamBannerCard(
                    expanded: expanded,
                    isActive: active == AppNav.onboarding,
                    paymentComplete: paymentComplete,
                    onTap: paymentComplete ? () => onTap(AppNav.onboarding) : () {},
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (ctx) => GestureDetector(
                    onTap: () => shareCareerLink(ctx, userEmail),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_rounded, color: Colors.white, size: 17),
                          if (expanded) ...[
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Share & Earn',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),

            const Divider(color: glassBorder, height: 1, thickness: 1.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(firstName,
                          style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(userData?['email'] ?? '',
                          style: const TextStyle(color: textMuted, fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, color: textMuted, size: 16),
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, expanded;
  final bool isLocked;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.expanded,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 10),
      decoration: BoxDecoration(
        color: isLocked
            ? amberLight.withValues(alpha: 0.5)
            : isActive ? primaryLight.withValues(alpha: 0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isLocked
            ? Border.all(color: amber.withValues(alpha: 0.35), width: 1)
            : null,
      ),
      child: Row(children: [
        Icon(icon,
            color: isLocked ? amber : isActive ? primary : textMuted,
            size: 20),
        if (expanded) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(
              color: isLocked ? amber : isActive ? primary : textSecondary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            )),
          ),
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: amber.withValues(alpha: 0.4), width: 1),
              ),
              child: const Text(
                'Locked',
                style: TextStyle(color: amber, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
            ),
        ],
      ]),
    ),
  );
}

// ===========================================================================
// TOP BAR
// ===========================================================================

class _TopBar extends StatelessWidget {
  final AppNav active;
  final Map<String, dynamic>? userData;
  final String? docId;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.active,
    required this.userData,
    required this.docId,
    required this.onMenuTap,
  });

  static const _titles = {
    AppNav.jobs:        'Jobs',
    AppNav.explore:     'Explore',
    AppNav.payments:    'Payments',   // FIX: was missing — caused null crash on !
    AppNav.onboarding:  'Onboarding Exam',
    AppNav.profile:     'My Profile',
    AppNav.settings:    'Settings',
  };

  @override
  Widget build(BuildContext context) {
    final status = userData?['status'] ?? 'pending';
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: glassWhite,
            border: Border(bottom: BorderSide(color: glassBorder, width: 1.5)),
          ),
          child: Row(children: [
            Text(_titles[active]!, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
            const Spacer(),
            GestureDetector(
              onTap: () => showStatusPopup(context, status),
              child: _StatusChip(status: status),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => showResetPasswordDialog(context, userData?['email'] ?? ''),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.2),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_reset_rounded, color: primary, size: 15),
                  SizedBox(width: 6),
                  Text('Reset Password', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            _IBtn(icon: Icons.notifications_none_rounded, onTap: () {}),
          ]),
        ),
      ),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: glassWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glassBorder, width: 1.5),
      ),
      child: Icon(icon, color: textSecondary, size: 17),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final bg    = statusBg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(statusLabel(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ===========================================================================
// LOADERS AND ERROR VIEWS
// ===========================================================================

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [bgGradientTop, bgGradientBot], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primary, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: textSecondary, fontSize: 14)),
          ],
        ),
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onBack;

  const _ErrorView({required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [bgGradientTop, bgGradientBot], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54, height: 54,
              decoration: const BoxDecoration(color: redLight, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: red, size: 26),
            ),
            const SizedBox(height: 14),
            Text(error, style: const TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ===========================================================================
// ONBOARDING EXAM BANNER CARD (Sidebar)
// ===========================================================================

class _OnboardingExamBannerCard extends StatelessWidget {
  final bool expanded;
  final bool isActive;
  final bool paymentComplete;
  final VoidCallback onTap;

  const _OnboardingExamBannerCard({
    required this.expanded,
    required this.isActive,
    required this.paymentComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      // Collapsed: just show a glowing icon button (locked when payment incomplete)
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: !paymentComplete
                ? const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
            boxShadow: [
              BoxShadow(
                color: (!paymentComplete
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6366F1))
                    .withValues(alpha: isActive ? 0.35 : 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              paymentComplete ? Icons.quiz_rounded : Icons.lock_outline_rounded,
              color: !paymentComplete
                  ? const Color(0xFFD97706)
                  : isActive ? Colors.white : const Color(0xFF6366F1),
              size: 20,
            ),
          ),
        ),
      );
    }

    // Expanded: full beautiful banner card
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : const Color(0xFF6366F1).withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: isActive ? 0.30 : 0.08),
              blurRadius: isActive ? 16 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative background circles
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (isActive ? Colors.white : const Color(0xFF6366F1))
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: -6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (isActive ? Colors.white : const Color(0xFF0EA5E9))
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.22)
                              : const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.quiz_rounded,
                          color: isActive ? Colors.white : const Color(0xFF6366F1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Onboarding Exam',
                              style: TextStyle(
                                color: isActive ? Colors.white : const Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFF059669),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your exam to unlock full access.',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF4338CA),
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: !paymentComplete
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                                : isActive
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(8),
                            border: !paymentComplete
                                ? Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : null,
                            boxShadow: (!paymentComplete || isActive)
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.30),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                !paymentComplete
                                    ? Icons.lock_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                color: !paymentComplete
                                    ? const Color(0xFFD97706)
                                    : Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                !paymentComplete
                                    ? 'Pay Info Required'
                                    : isActive ? 'In Progress' : 'Start Exam',
                                style: TextStyle(
                                  color: !paymentComplete
                                      ? const Color(0xFFD97706)
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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