import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1E40AF); // rich blue
  static const Color primaryDark  = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryGrad1 = Color(0xFF0F172A); // gradient start
  static const Color primaryGrad2 = Color(0xFF1E3A8A); // gradient end

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color online    = Color(0xFF16A34A); // vendor online
  static const Color offline   = Color(0xFF6B7280);
  static const Color accent    = Color(0xFF16A34A); // earnings / success
  static const Color warning   = Color(0xFFF59E0B);
  static const Color error     = Color(0xFFDC2626);
  static const Color newOrder  = Color(0xFFEA580C); // urgent new order orange

  // ── Surface ────────────────────────────────────────────────────────────────
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color background  = Color(0xFFF1F5F9);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color divider     = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint      = Color(0xFF94A3B8);

  // ── Order status ───────────────────────────────────────────────────────────
  static const Color statusPending   = Color(0xFFF59E0B);
  static const Color statusActive    = Color(0xFF2563EB);
  static const Color statusCompleted = Color(0xFF16A34A);
  static const Color statusCancelled = Color(0xFFDC2626);

  // ── Gradient helpers ───────────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGrad1, primaryGrad2],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15803D), Color(0xFF16A34A)],
  );
}
