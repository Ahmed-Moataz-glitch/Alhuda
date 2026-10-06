import 'package:flutter/material.dart';

/// نموذج بيانات يمثل ميزة من مميزات التطبيق
class AppFeatureInfo {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String badge;
  final List<String> highlights;
  final Widget Function(BuildContext context)? navigationBuilder;

  const AppFeatureInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.badge,
    required this.highlights,
    this.navigationBuilder,
  });
}
