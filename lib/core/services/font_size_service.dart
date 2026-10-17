import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// أقسام ومميزات التطبيق المستقلة في إعدادات الخط
enum AppFeature {
  home(
    title: 'الصفحة الرئيسية',
    key: 'home',
    icon: Icons.home_rounded,
    previewTitle: 'الهُدى • أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    previewSubtitle: 'المصحف الشريف • الأحاديث النبوية • مواقيت الصلاة • الأذكار',
    previewFontFamily: 'Almarai',
  ),
  quran(
    title: 'المصحف الشريف',
    key: 'quran',
    icon: Icons.menu_book_rounded,
    previewTitle: '﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾',
    previewSubtitle: '«سورة الإسراء - آية ٩»',
    previewFontFamily: 'Amiri',
  ),
  hadith(
    title: 'الأحاديث النبوية',
    key: 'hadith',
    icon: Icons.auto_stories_rounded,
    previewTitle:
        '«مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الْجَنَّةِ»',
    previewSubtitle: '«صحيح مسلم - كتاب الذكر والدعاء»',
    previewFontFamily: 'Amiri',
  ),
  prayerTimes(
    title: 'مواقيت الصلاة',
    key: 'prayer_times',
    icon: Icons.access_time_filled_rounded,
    previewTitle: 'الفجر ٠٤:٤٥ ص • الظهر ١١:٥٠ ص • المغرب ٠٥:٤٠ م',
    previewSubtitle: '«إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا»',
    previewFontFamily: 'Almarai',
  ),
  takweem(
    title: 'التقويم الهجري',
    key: 'takweem',
    icon: Icons.calendar_month_rounded,
    previewTitle: '١ جمادى الأولى ١٤٤٨ هـ • الأحد',
    previewSubtitle: '«متابعة المناسبات الإسلامية والتحويل بين التاريخين»',
    previewFontFamily: 'Almarai',
  ),
  tasbeeh(
    title: 'التسبيح الحر',
    key: 'tasbeeh',
    icon: Icons.fingerprint_rounded,
    previewTitle: '«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ»',
    previewSubtitle: '«كلمتان خفيفتان على اللسان ثقيلتان في الميزان»',
    previewFontFamily: 'Amiri',
  ),
  azkar(
    title: 'الأذكار',
    key: 'azkar',
    icon: Icons.auto_stories_rounded,
    previewTitle:
        '«أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ»',
    previewSubtitle: '«أذكار الصباح والمساء وحصن المسلم»',
    previewFontFamily: 'Amiri',
  ),
  allahNames(
    title: 'أسماء الله الحسنى',
    key: 'allah_names',
    icon: Icons.stars_rounded,
    previewTitle: '«الرَّحْمَٰنُ • الرَّحِيمُ • الْمَلِكُ • الْقُدُّوسُ • السَّلَامُ»',
    previewSubtitle: '«وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا»',
    previewFontFamily: 'Amiri',
  ),
  fiqh(
    title: 'الفقه الإسلامي',
    key: 'fiqh',
    icon: Icons.library_books_rounded,
    previewTitle:
        '«موسوعة الأحكام والمسائل الفقهية الميسرة في العبادات والمعاملات»',
    previewSubtitle: '«فقه العبادات: شروط وأركان الصلاة والطهارة»',
    previewFontFamily: 'Almarai',
  ),
  qibla(
    title: 'القبلة',
    key: 'qibla',
    icon: Icons.explore_rounded,
    previewTitle: '«اتجاه القبلة: ١٣٥° جنوب شرق • زاوية الكعبة المشرفة»',
    previewSubtitle: '«فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ»',
    previewFontFamily: 'Almarai',
  ),
  appGuide(
    title: 'دليل ومميزات التطبيق',
    key: 'app_guide',
    icon: Icons.smart_display_rounded,
    previewTitle: '«دليل الاستخدام بالفيديو وشرح مميزات تطبيق الهُدى»',
    previewSubtitle: '«إرشادات وخطوات استخدام كل قسم وميزة داخل التطبيق»',
    previewFontFamily: 'Almarai',
  );

  final String title;
  final String key;
  final IconData icon;
  final String previewTitle;
  final String previewSubtitle;
  final String previewFontFamily;

  const AppFeature({
    required this.title,
    required this.key,
    required this.icon,
    required this.previewTitle,
    required this.previewSubtitle,
    required this.previewFontFamily,
  });

  static AppFeature? fromKey(String key) {
    for (final f in values) {
      if (f.key == key) return f;
    }
    return null;
  }

  static AppFeature? fromTitle(String title) {
    final clean = title.trim();
    for (final f in values) {
      if (f.title == clean) return f;
    }
    if (clean.contains('رئيسية') || clean.contains('الرئيسية')) return AppFeature.home;
    if (clean.contains('قرآن') || clean.contains('مصحف')) return AppFeature.quran;
    if (clean.contains('حديث')) return AppFeature.hadith;
    if (clean.contains('صلاة') || clean.contains('مواقيت')) return AppFeature.prayerTimes;
    if (clean.contains('تقويم') || clean.contains('هجري')) return AppFeature.takweem;
    if (clean.contains('تسبيح') || clean.contains('سبحة')) return AppFeature.tasbeeh;
    if (clean.contains('أذكار') || clean.contains('اذكار')) return AppFeature.azkar;
    if (clean.contains('أسماء الله') || clean.contains('اسماء الله')) return AppFeature.allahNames;
    if (clean.contains('فقه') || clean.contains('أحكام')) return AppFeature.fiqh;
    if (clean.contains('قبلة') || clean.contains('كعبة')) return AppFeature.qibla;
    if (clean.contains('دليل')) return AppFeature.appGuide;
    return null;
  }
}

/// نطاق لتطبيق حجم الخط الخاص بالميزة على شجرة العناصر أسفله
class FeatureFontScope extends StatelessWidget {
  final AppFeature feature;
  final Widget child;

  const FeatureFontScope({
    super.key,
    required this.feature,
    required this.child,
  });

  static AppFeature? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedFeatureFontScope>()
        ?.feature;
  }

  static double scaleOf(BuildContext context) {
    final feat = of(context);
    if (feat != null) {
      return FontSizeService.instance.getScale(feat);
    }
    return FontSizeService.defaultScale;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FontSizeService.instance,
      builder: (context, _) {
        final scale = FontSizeService.instance.getScale(feature);
        final mediaQuery = MediaQuery.of(context);
        return _InheritedFeatureFontScope(
          feature: feature,
          scale: scale,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _InheritedFeatureFontScope extends InheritedWidget {
  final AppFeature feature;
  final double scale;

  const _InheritedFeatureFontScope({
    required this.feature,
    required this.scale,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedFeatureFontScope oldWidget) {
    return feature != oldWidget.feature || scale != oldWidget.scale;
  }
}

/// خدمة إدارة حجم الخط لكل ميزة على حدة بشكل منفصل
/// تدعم الحفظ المحلي والتحديث الفوري للميزة دون التأثير على باقي التطبيق
class FontSizeService extends ChangeNotifier {
  static final FontSizeService _instance = FontSizeService._internal();
  static FontSizeService get instance => _instance;

  FontSizeService._internal();

  static const double minScale = 0.80;
  static const double maxScale = 1.40;
  static const double defaultScale = 1.0;
  static const double step = 0.05;

  /// الأحجام السريعة الجاهزة للاختيار
  static const List<double> presets = [0.85, 1.0, 1.15, 1.25, 1.35];

  final Map<AppFeature, double> _featureScales = {
    for (final f in AppFeature.values) f: defaultScale,
  };

  AppFeature _activeFeature = AppFeature.home;
  File? _settingsFile;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  AppFeature get activeFeature => _activeFeature;

  void setActiveFeature(AppFeature feature) {
    if (_activeFeature != feature) {
      _activeFeature = feature;
      notifyListeners();
    }
  }

  /// مقياس الخط للميزة المحددة
  double getScale(AppFeature feature) => _featureScales[feature] ?? defaultScale;

  /// دعم رجعي للمقياس النشط
  double get fontScale => getScale(_activeFeature);

  /// هل مقياس الميزة هو الافتراضي
  bool isFeatureDefault(AppFeature feature) =>
      ((getScale(feature) - defaultScale).abs() < 0.01);

  /// هل مقياس الميزة النشطة هو الافتراضي
  bool get isDefault => isFeatureDefault(_activeFeature);

  /// هل جميع المميزات على الحجم الافتراضي
  bool get areAllDefault =>
      _featureScales.values.every((s) => (s - defaultScale).abs() < 0.01);

  /// النسبة المئوية لحجم الخط للميزة (مثال: 100% أو 115%)
  String percentageText([AppFeature? feature]) {
    final scale = getScale(feature ?? _activeFeature);
    return '${(scale * 100).round()}%';
  }

  /// وصف حجم الخط باللغة العربية للميزة
  String scaleLabel([AppFeature? feature]) {
    return scaleLabelFor(getScale(feature ?? _activeFeature));
  }

  static String scaleLabelFor(double scale) {
    if (scale <= 0.85) return 'صغير جداً';
    if (scale <= 0.95) return 'صغير';
    if (scale <= 1.05) return 'افتراضي (عادي)';
    if (scale <= 1.15) return 'متوسط';
    if (scale <= 1.25) return 'كبير';
    return 'كبير جداً';
  }

  /// اسم الحجم الجاهز
  static String presetName(double preset) {
    if (preset <= 0.85) return 'صغير';
    if (preset <= 1.02) return 'افتراضي';
    if (preset <= 1.15) return 'متوسط';
    if (preset <= 1.25) return 'كبير';
    return 'كبير جداً';
  }

  /// تحميل الإعدادات المحفوظة من الذاكرة المحلية
  Future<void> init() async {
    try {
      final appDoc = await getApplicationDocumentsDirectory()
          .timeout(const Duration(seconds: 1));
      _settingsFile = File('${appDoc.path}/alhuda_font_settings.json');

      if (await _settingsFile!.exists()) {
        final content = await _settingsFile!.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        if (data['features'] is Map) {
          final Map<String, dynamic> featMap = data['features'];
          for (final f in AppFeature.values) {
            final val = featMap[f.key];
            if (val is num) {
              _featureScales[f] = _clamp(val.toDouble());
            }
          }
        } else if (data['fontScale'] is num) {
          // ترقية من الإعداد الفردي القديم
          final val = _clamp((data['fontScale'] as num).toDouble());
          _featureScales[AppFeature.quran] = val;
        }
      }
    } catch (e) {
      debugPrint('Error loading font scale settings: $e');
      for (final f in AppFeature.values) {
        _featureScales[f] = defaultScale;
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// تعيين حجم خط مخصص لميزة معينة
  Future<void> setScale(AppFeature feature, double scale) async {
    final clamped = _clamp(scale);
    final rounded = (clamped * 100).roundToDouble() / 100.0;
    if (((_featureScales[feature] ?? defaultScale) - rounded).abs() < 0.001) return;

    _featureScales[feature] = rounded;
    _activeFeature = feature;
    notifyListeners();
    await _saveSettings();
  }

  /// تعيين حجم الخط (دعم رجعي للميزة النشطة أو المحددة)
  Future<void> setFontScale(double scale, [AppFeature? feature]) async {
    await setScale(feature ?? _activeFeature, scale);
  }

  /// إعادة تعيين حجم الميزة إلى الافتراضي (1.0)
  Future<void> resetScale(AppFeature feature) async {
    HapticFeedback.selectionClick();
    await setScale(feature, defaultScale);
  }

  /// إعادة تعيين الحجم الافتراضي (دعم رجعي للميزة النشطة أو المحددة)
  Future<void> resetFontScale([AppFeature? feature]) async {
    await resetScale(feature ?? _activeFeature);
  }

  /// إعادة تعيين كافة المميزات إلى الوضع الافتراضي
  Future<void> resetAllScales() async {
    HapticFeedback.selectionClick();
    for (final f in AppFeature.values) {
      _featureScales[f] = defaultScale;
    }
    notifyListeners();
    await _saveSettings();
  }

  /// تكبير الخط بمقدار خطوة واحدة (0.05) للميزة المحددة
  Future<void> increaseScale([AppFeature? feature]) async {
    final target = feature ?? _activeFeature;
    final current = getScale(target);
    if (current >= maxScale - 0.001) return;
    HapticFeedback.selectionClick();
    await setScale(target, current + step);
  }

  /// تصغير الخط بمقدار خطوة واحدة (0.05) للميزة المحددة
  Future<void> decreaseScale([AppFeature? feature]) async {
    final target = feature ?? _activeFeature;
    final current = getScale(target);
    if (current <= minScale + 0.001) return;
    HapticFeedback.selectionClick();
    await setScale(target, current - step);
  }

  double _clamp(double value) {
    if (value < minScale) return minScale;
    if (value > maxScale) return maxScale;
    return value;
  }

  Future<void> _saveSettings() async {
    if (_settingsFile == null && !_isInitialized) {
      return;
    }
    try {
      if (_settingsFile == null) {
        final appDoc = await getApplicationDocumentsDirectory()
            .timeout(const Duration(milliseconds: 500));
        _settingsFile = File('${appDoc.path}/alhuda_font_settings.json');
      }
      final featMap = {
        for (final entry in _featureScales.entries) entry.key.key: entry.value,
      };
      final jsonStr = jsonEncode({
        'features': featMap,
        'fontScale': getScale(AppFeature.quran),
      });
      await _settingsFile!.writeAsString(jsonStr, flush: true);
    } catch (e) {
      debugPrint('Error saving font scale settings: $e');
    }
  }
}
