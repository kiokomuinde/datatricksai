import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the split files directly so this page can see the helper functions, styling, and widgets
import 'dashboard_user/opportunity_model.dart';
import 'dashboard_user/theme_constants.dart';
import 'dashboard_user/glass_container.dart';
import 'dashboard_user/app_dialogs.dart';

// ===========================================================================
// DATATRICKS AI — SETTINGS PAGE
// ===========================================================================

class SettingsPage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String userEmail;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.userData,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 20),

          // ── Notifications ────────────────────────────────────────────────
          _SSection(title: 'Notifications', children: const [
            _STgl(
              label: 'Email Alerts',
              subtitle: 'Receive daily updates on new opportunities',
              initial: true,
            ),
            _STgl(
              label: 'Push Notifications',
              subtitle: 'Instant alerts for application status changes',
              initial: true,
            ),
            _STgl(
              label: 'Payment Notifications',
              subtitle: 'Get notified when a payout is processed',
              initial: true,
            ),
          ]),
          const SizedBox(height: 16),

          // ── Privacy ──────────────────────────────────────────────────────
          _SSection(title: 'Privacy', children: const [
            _STgl(
              label: 'Profile Visibility',
              subtitle: 'Allow recruiters to view your full profile',
              initial: true,
            ),
            _STgl(
              label: 'Online Status',
              subtitle: "Let others see when you're active",
              initial: false,
            ),
            _STgl(
              label: 'Data Analytics',
              subtitle: 'Allow anonymised usage data to improve the platform',
              initial: true,
            ),
          ]),
          const SizedBox(height: 16),

          // ── Security ─────────────────────────────────────────────────────
          _SSection(title: 'Security', children: [
            _SActionRow(
              icon: Icons.lock_reset_rounded,
              iconColor: primary,
              iconBg: primaryLight,
              label: 'Reset Password',
              subtitle: 'Send a password reset link to your email',
              onTap: () => showResetPasswordDialog(context, userEmail),
            ),
            _SActionRow(
              icon: Icons.verified_user_outlined,
              iconColor: amber,
              iconBg: amberLight,
              label: 'Persona Verification',
              subtitle: 'Complete identity verification to unlock full access',
              onTap: () => showPendingReviewPopup(context),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Account ──────────────────────────────────────────────────────
          _SSection(title: 'Account', children: [
            _SInfoRow(
              label: 'Email Address',
              value: userEmail,
            ),
            _SInfoRow(
              label: 'Account Status',
              value: statusLabel(userData?['status']),
              valueColor: statusColor(userData?['status']),
            ),
            _SActionRow(
              icon: Icons.logout_rounded,
              iconColor: red,
              iconBg: redLight,
              label: 'Sign Out',
              subtitle: 'Log out of your DataTricks AI account',
              onTap: onLogout,
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 24),

          // ── App Info ─────────────────────────────────────────────────────
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 32, width: 32, fit: BoxFit.contain),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DataTricks AI Portal',
                        style: TextStyle(
                            color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Version 1.0.0 · datatricksai.us',
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SECTION WRAPPER ──────────────────────────────────────────────────────────

class _SSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

// ── TOGGLE ROW ───────────────────────────────────────────────────────────────

class _STgl extends StatefulWidget {
  final String label, subtitle;
  final bool initial;

  const _STgl({
    required this.label,
    required this.subtitle,
    required this.initial,
  });

  @override
  State<_STgl> createState() => _STglState();
}

class _STglState extends State<_STgl> {
  late bool val;

  @override
  void initState() {
    super.initState();
    val = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                        color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Switch(
              value: val,
              onChanged: (v) => setState(() => val = v),
              activeColor: primary,
            ),
          ],
        ),
      );
}

// ── ACTION ROW ───────────────────────────────────────────────────────────────

class _SActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDestructive ? red : textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive ? red.withOpacity(0.6) : textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      );
}

// ── INFO ROW ─────────────────────────────────────────────────────────────────

class _SInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}