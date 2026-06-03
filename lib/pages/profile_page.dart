import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the newly split files directly so this page can see the classes and colors
import 'dashboard_user/opportunity_model.dart';
import 'dashboard_user/theme_constants.dart';
import 'dashboard_user/glass_container.dart';
import 'dashboard_user/app_dialogs.dart';

// ===========================================================================
// DATATRICKS AI — PROFILE PAGE
// ===========================================================================

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userEmail;

  const ProfilePage({
    super.key,
    required this.userData,
    required this.userEmail,
  });

  String _fieldVal(String key) {
    final v = userData[key];
    if (v == null) return '—';
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _fieldVal('firstName');
    final lastName  = _fieldVal('lastName');
    final initials  =
        '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
    final status = userData['status'] ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero Card ────────────────────────────────────────────────────
          _ProfileHeroCard(
            firstName: firstName,
            lastName: lastName,
            initials: initials,
            userEmail: userEmail,
            status: status,
          ),
          const SizedBox(height: 20),

          // ── Password Reset Button ─────────────────────────────────────────
          _ResetPasswordCard(userEmail: userEmail),
          const SizedBox(height: 20),

          // ── Personal Details ─────────────────────────────────────────────
          _ProfileSection(
            title: 'Personal Details',
            icon: Icons.person_outline_rounded,
            iconColor: primary,
            iconBg: primaryLight,
            children: [
              _PRow(label: 'First Name',  value: _fieldVal('firstName')),
              _PRow(label: 'Last Name',   value: _fieldVal('lastName')),
              _PRow(label: 'Email',       value: _fieldVal('email')),
              _PRow(label: 'Phone',       value: _fieldVal('phone')),
              _PRow(label: 'Country',     value: _fieldVal('country'), isLast: true),
            ],
          ),
          const SizedBox(height: 16),

          // ── Professional Details ──────────────────────────────────────────
          _ProfileSection(
            title: 'Professional Details',
            icon: Icons.work_outline_rounded,
            iconColor: secondary,
            iconBg: secondaryLight,
            children: [
              _PRow(label: 'Skills',      value: _fieldVal('skills')),
              _PRow(label: 'Experience',  value: _fieldVal('experience')),
              _PRow(label: 'Applied',     value: _fieldVal('submittedAt'), isLast: true),
            ],
          ),
          const SizedBox(height: 16),

          // ── Persona Verification ──────────────────────────────────────────
          _VerificationCard(),
        ],
      ),
    );
  }
}

// ── HERO CARD ────────────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String initials;
  final String userEmail;
  final String status;

  const _ProfileHeroCard({
    required this.firstName,
    required this.lastName,
    required this.initials,
    required this.userEmail,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        children: [
          // Gradient banner
          Container(
            width: double.infinity,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          // Avatar + name row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar overlapping the banner
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primary, secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$firstName $lastName',
                                style: const TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                userEmail,
                                style: const TextStyle(color: textMuted, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status chip below avatar (cancel the translate offset space)
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _ProfileStatusChip(status: status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── RESET PASSWORD CARD ───────────────────────────────────────────────────────

class _ResetPasswordCard extends StatelessWidget {
  final String userEmail;
  const _ResetPasswordCard({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withOpacity(0.20), width: 1.2),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password & Security',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Send a reset link to your registered email',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => showResetPasswordDialog(context, userEmail),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withOpacity(0.25), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_reset_rounded, color: primary, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SECTION WRAPPER ───────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: glassBorder, height: 1, thickness: 1),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

// ── PROFILE ROW ───────────────────────────────────────────────────────────────

class _PRow extends StatelessWidget {
  final String label, value;
  final bool isLast;

  const _PRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: textMuted, fontSize: 13),
                ),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) const Divider(color: glassBorder, height: 1, thickness: 1),
        ],
      );
}

// ── VERIFICATION CARD ─────────────────────────────────────────────────────────

class _VerificationCard extends StatelessWidget {
  const _VerificationCard();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amberLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: amber, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persona Verification',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                SizedBox(height: 3),
                Text(
                  'Your identity verification is pending review',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => showPendingReviewPopup(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: amber.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timelapse_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Pending Review',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PROFILE STATUS CHIP (self-contained, no cross-file dependency) ────────────

class _ProfileStatusChip extends StatelessWidget {
  final String status;
  const _ProfileStatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'approved':  return green;
      case 'rejected':  return red;
      case 'reviewing': return amber;
      default:          return primary;
    }
  }

  Color get _bg {
    switch (status) {
      case 'approved':  return greenLight;
      case 'rejected':  return redLight;
      case 'reviewing': return amberLight;
      default:          return primaryLight;
    }
  }

  String get _label {
    switch (status) {
      case 'approved':  return 'Approved';
      case 'rejected':  return 'Not Selected';
      case 'reviewing': return 'Under Review';
      default:          return 'Pending Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}