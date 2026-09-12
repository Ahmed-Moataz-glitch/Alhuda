import 'package:flutter/material.dart';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/features/qibla/presentation/view/widgets/qiblah_offline_view.dart';

/// شاشة تحديد اتجاه القبلة بواسطة الشمس (طريقة فلكية أوفلاين 100% بدون نت وبدون مستشعر)
class QiblahPage extends StatelessWidget {
  final bool hasScaffold;

  const QiblahPage({super.key, this.hasScaffold = true});

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
