import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_constants.dart';

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
// STATUS POPUP
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
    default:
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