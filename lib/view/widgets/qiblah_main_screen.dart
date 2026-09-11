import 'package:flutter/material.dart';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/view/widgets/qiblah_offline_view.dart';

/// شاشة تحديد اتجاه القبلة بواسطة الشمس (طريقة فلكية أوفلاين 100% بدون نت وبدون مستشعر)
class QiblahMainScreen extends StatelessWidget {
  final bool hasScaffold;

  const QiblahMainScreen({
    super.key,
    this.hasScaffold = true,
  });

  @override
  Widget build(BuildContext context) {
    const content = QiblahOfflineView();

    if (!hasScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'القبلة بواسطة الشمس',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: content,
    );
  }
}
