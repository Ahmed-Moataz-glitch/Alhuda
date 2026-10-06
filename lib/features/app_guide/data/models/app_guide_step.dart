import 'package:flutter/material.dart';

/// نموذج بيانات يمثل دليلاً إرشادياً أو خطوة استخدام داخل التطبيق
class AppGuideStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> steps;
  final String? tip;
  final String category;

  const AppGuideStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.steps,
    this.tip,
    required this.category,
  });
}
