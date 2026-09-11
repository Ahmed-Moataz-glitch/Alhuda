import 'package:flutter/material.dart';

/// Utility class for displaying RTL SnackBars with consistent styling across the application.
class AppSnackBar {
  AppSnackBar._();

  /// Creates a SnackBar with explicit RTL directionality.
  static SnackBar create({
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    ShapeBorder? shape,
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return SnackBar(
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
      shape: shape,
      action: action,
      margin: margin,
      padding: padding,
    );
  }

  /// Shows an RTL SnackBar using ScaffoldMessenger.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    ShapeBorder? shape,
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      create(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: behavior,
        shape: shape,
        action: action,
        margin: margin,
        padding: padding,
      ),
    );
  }
}
