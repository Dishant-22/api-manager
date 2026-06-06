import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Method colors
  static const Color getMethod = Color(0xFF61AFFE);
  static const Color postMethod = Color(0xFF49CC90);
  static const Color putMethod = Color(0xFFFCA130);
  static const Color patchMethod = Color(0xFF50E3C2);
  static const Color deleteMethod = Color(0xFFF93E3E);
  static const Color headMethod = Color(0xFF9012FE);
  static const Color optionsMethod = Color(0xFF0D5AA7);

  // Status code colors
  static const Color status1xx = Color(0xFF888888);
  static const Color status2xx = Color(0xFF49CC90);
  static const Color status3xx = Color(0xFFFCA130);
  static const Color status4xx = Color(0xFFE74C3C);
  static const Color status5xx = Color(0xFFC0392B);

  // Syntax highlighting
  static const Color jsonKey = Color(0xFF9CDCFE);
  static const Color jsonString = Color(0xFFCE9178);
  static const Color jsonNumber = Color(0xFFB5CEA8);
  static const Color jsonBoolean = Color(0xFF569CD6);
  static const Color jsonNull = Color(0xFF569CD6);

  // Dark theme surface
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkBackground = Color(0xFF181825);
  static const Color darkSidebarBg = Color(0xFF13131F);
  static const Color darkCardBg = Color(0xFF252537);

  // Light theme surface
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSidebarBg = Color(0xFFEEEEEE);
  static const Color lightCardBg = Color(0xFFFFFFFF);

  static Color methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return getMethod;
      case 'POST':
        return postMethod;
      case 'PUT':
        return putMethod;
      case 'PATCH':
        return patchMethod;
      case 'DELETE':
        return deleteMethod;
      case 'HEAD':
        return headMethod;
      case 'OPTIONS':
        return optionsMethod;
      default:
        return Colors.grey;
    }
  }

  static Color statusColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;
    if (statusCode < 200) return status1xx;
    if (statusCode < 300) return status2xx;
    if (statusCode < 400) return status3xx;
    if (statusCode < 500) return status4xx;
    return status5xx;
  }
}
