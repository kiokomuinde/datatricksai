import 'package:flutter/material.dart';

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