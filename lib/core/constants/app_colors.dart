import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF00897B);
  static const Color primaryDark = Color(0xFF00695C);
  static const Color accent = Color(0xFF4DB6AC);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);

  // Status
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4D4F);
  static const Color overdue = Color(0xFFFF4D4F);

  // Loan type colors
  static const Color home = Color(0xFF1E6FFF);
  static const Color vehicle = Color(0xFF7C3AED);
  static const Color personal = Color(0xFFFF6B35);
  static const Color appliance = Color(0xFF00C896);
  static const Color creditCard = Color(0xFFFFB020);

  // Score bands
  static const Color scoreExcellent = Color(0xFF00C896);
  static const Color scoreGood = Color(0xFF1E6FFF);
  static const Color scoreFair = Color(0xFFFFB020);
  static const Color scorePoor = Color(0xFFFF4D4F);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D23);
  static const Color darkCard = Color(0xFF252830);

  static Color loanTypeColor(String type) {
    switch (type) {
      case 'Home Loan':        return home;
      case 'Vehicle Loan':     return vehicle;
      case 'Personal Loan':    return personal;
      case 'Consumer Durable': return appliance;
      case 'Education Loan':   return primary;
      case 'Business Loan':    return creditCard;
      default:                 return primary;
    }
  }

  static IconData loanTypeIcon(String type) {
    switch (type) {
      case 'Home Loan':        return Icons.home_outlined;
      case 'Vehicle Loan':     return Icons.directions_car_outlined;
      case 'Personal Loan':    return Icons.person_outline;
      case 'Consumer Durable': return Icons.devices_outlined;
      case 'Education Loan':   return Icons.school_outlined;
      case 'Business Loan':    return Icons.business_outlined;
      default:                 return Icons.account_balance_outlined;
    }
  }
}
