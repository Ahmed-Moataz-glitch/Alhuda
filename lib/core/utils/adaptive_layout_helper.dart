import 'package:flutter/material.dart';

/// تصنيف نوع الجهاز بناءً على عرض الشاشة أو القيود المتاحة
enum AdaptiveDeviceType {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == AdaptiveDeviceType.mobile;
  bool get isTablet => this == AdaptiveDeviceType.tablet;
  bool get isDesktop => this == AdaptiveDeviceType.desktop;
}

/// نقاط التوقف القياسية للتصميم المتكيف (Responsive Breakpoints)
class AdaptiveBreakpoints {
  AdaptiveBreakpoints._();

  static const double tabletMin = 600.0;
  static const double desktopMin = 1024.0;
  static const double largeDesktopMin = 1440.0;

  static AdaptiveDeviceType getDeviceType(double width) {
    if (width >= desktopMin) {
      return AdaptiveDeviceType.desktop;
    } else if (width >= tabletMin) {
      return AdaptiveDeviceType.tablet;
    } else {
      return AdaptiveDeviceType.mobile;
    }
  }

  static bool isMobile(double width) => width < tabletMin;
  static bool isTablet(double width) =>
      width >= tabletMin && width < desktopMin;
  static bool isDesktop(double width) => width >= desktopMin;
}

/// ودجت LayoutBuilder متكيفة ذكية لتسهيل بناء واجهات تدعم الهواتف والتابلت والشاشات الكبيرة
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    AdaptiveDeviceType deviceType,
  ) builder;

  const AdaptiveLayout({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = AdaptiveBreakpoints.getDeviceType(constraints.maxWidth);
        return builder(context, constraints, deviceType);
      },
    );
  }
}

/// حاوية محتوى متكيفة تقوم بتوسيط المحتوى وحمايته من التمدد المفرط على شاشات التابلت وسطح المكتب
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1100.0,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentWidth = constraints.maxWidth;
        final isWideScreen = currentWidth >= AdaptiveBreakpoints.tabletMin;

        // حساب الحواشي الذاتية لتوفير مساحة راحة بصرية على الشاشات الكبيرة
        final effectivePadding = padding ??
            EdgeInsets.symmetric(
              horizontal: currentWidth >= AdaptiveBreakpoints.desktopMin
                  ? 32.0
                  : (isWideScreen ? 24.0 : 16.0),
            );

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: Padding(
              padding: effectivePadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// مساعد حساب الأعمدة والنسب للشبكات (SliverGrid & GridView) بناءً على LayoutBuilder
class AdaptiveGridHelper {
  AdaptiveGridHelper._();

  /// حساب عدد الأعمدة المناسب لعرض الشاشة الحالي
  static int getColumns(
    double width, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
    int largeDesktop = 5,
    double itemMinWidth = 180.0,
  }) {
    if (width >= AdaptiveBreakpoints.largeDesktopMin) {
      return largeDesktop;
    } else if (width >= AdaptiveBreakpoints.desktopMin) {
      return desktop;
    } else if (width >= AdaptiveBreakpoints.tabletMin) {
      return tablet;
    } else {
      // للهواتف الصغيرة جداً
      if (width < 340 && mobile > 1) {
        return 1;
      }
      return mobile;
    }
  }

  /// حساب نسبة العرض إلى الارتفاع للبطاقات بحيث تكون متناسقة ولا تفيض على الشاشات الكبيرة
  static double getCardAspectRatio({
    required double width,
    required int columns,
    double fontScale = 1.0,
    double baseMobileRatio = 1.15,
  }) {
    final columnWidth = width / columns;

    // إذا كان العمود عريضاً جداً (مثل التابلت أو الشاشات الكبيرة)
    double ratio = baseMobileRatio;
    if (columnWidth > 260) {
      ratio = 1.35;
    } else if (columnWidth > 200) {
      ratio = 1.25;
    } else if (columnWidth > 160) {
      ratio = 1.15;
    } else {
      ratio = 1.05;
    }

    // تكييف النسبة مع حجم الخط لتجنب أخطاء overflow
    if (fontScale > 1.05) {
      ratio = (ratio - (fontScale - 1.0) * 0.35).clamp(0.85, 1.4);
    } else if (fontScale < 0.95) {
      ratio = (ratio + 0.1).clamp(0.85, 1.45);
    }

    return ratio;
  }
}

/// غلاف للنافذة السفلية (Bottom Sheet) ليظهر بشكل منسق على التابلت بدون أن يتمدد على كامل عرض الشاشة
class AdaptiveSheetWrapper extends StatelessWidget {
  final Widget child;
  final double maxSheetWidth;

  const AdaptiveSheetWrapper({
    super.key,
    required this.child,
    this.maxSheetWidth = 620.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= AdaptiveBreakpoints.tabletMin;
        if (!isTablet) {
          return child;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxSheetWidth,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
