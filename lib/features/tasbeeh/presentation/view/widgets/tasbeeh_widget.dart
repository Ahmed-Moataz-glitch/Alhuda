import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/services/font_size_service.dart';
import 'package:alhuda/features/tasbeeh/data/repositories/tasbeeh_repository_impl.dart';
import 'package:alhuda/features/tasbeeh/domain/entities/tasbeeh_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TasbeehWidget extends StatefulWidget {
  const TasbeehWidget({super.key});

  @override
  State<TasbeehWidget> createState() => _TasbeehWidgetState();
}

class _TasbeehWidgetState extends State<TasbeehWidget> {
  late List<TasbeehItem> _items;
  int _currentIndex = 0;
  int _counter = 0;
  int _totalSessionCount = 0;
  int? _customTarget; // null means use item default, 0 means open/unlimited
  bool _vibrationEnabled = true;
  bool _isAutoTransitioning = false;

  @override
  void initState() {
    super.initState();
    _items = List<TasbeehItem>.from(TasbeehRepositoryImpl().getDefaultItems());
    FontSizeService.instance.addListener(_onFontSizeChanged);
  }

  @override
  void dispose() {
    FontSizeService.instance.removeListener(_onFontSizeChanged);
    super.dispose();
  }

  void _onFontSizeChanged() {
    if (mounted) setState(() {});
  }

  TasbeehItem get _currentItem =>
      (_items.isNotEmpty && _currentIndex >= 0 && _currentIndex < _items.length)
          ? _items[_currentIndex]
          : const TasbeehItem(id: 0, text: 'سبحان الله');

  int get _effectiveTarget {
    if (_customTarget != null) return _customTarget!;
    return _currentItem.targetCount;
  }

  void _increment() {
    if (_isAutoTransitioning) return;

    final target = _effectiveTarget;

    // حالة العداد المفتوح (بدون هدف محدد)
    if (target <= 0) {
      setState(() {
        _counter++;
        _totalSessionCount++;
      });
      if (_vibrationEnabled) {
        HapticFeedback.lightImpact();
      }
      return;
    }

    final newCount = _counter + 1;

    // التسبيح العادي قبل الوصول للهدف
    if (newCount < target) {
      setState(() {
        _counter = newCount;
        _totalSessionCount++;
      });
      if (_vibrationEnabled) {
        HapticFeedback.lightImpact();
      }
      return;
    }

    // الوصول للهدف تماماً (مثلاً 33 أو 100)
    final completedTarget = target;
    final isLastItem =
        _items.isNotEmpty && _currentIndex == _items.length - 1;
    final message = isLastItem
        ? 'أتممت بحمد الله ($completedTarget مرة) • أتممت جميع أذكار الختام!'
        : 'أتممت بحمد الله ($completedTarget مرة) • تم الانتقال للذكر التالي';

    setState(() {
      _counter = target;
      _totalSessionCount++;
      _isAutoTransitioning = true;
    });

    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13.5.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // انتقال انسيابي سريع للذكر التالي مع تصفير العداد
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _counter = 0;
        _customTarget = null;
        _isAutoTransitioning = false;
        if (_items.isNotEmpty) {
          _currentIndex = (_currentIndex + 1) % _items.length;
        }
      });
    });
  }

  void _resetCounter() {
    if (_counter == 0) return;
    setState(() {
      _counter = 0;
    });
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _nextItem() {
    if (_items.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _items.length;
      _counter = 0;
      _customTarget = null;
    });
    if (_vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _previousItem() {
    if (_items.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _items.length) % _items.length;
      _counter = 0;
      _customTarget = null;
    });
    if (_vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _selectItem(int index) {
    if (index >= 0 && index < _items.length) {
      setState(() {
        _currentIndex = index;
        _counter = 0;
        _customTarget = null;
      });
      if (_vibrationEnabled) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _showAddCustomDhikrDialog() {
    final textController = TextEditingController();
    final countController = TextEditingController(text: '33');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'إضافة ذكر مخصص',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب نص الذكر أو الدعاء هنا...',
                    hintStyle: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13.sp,
                      color: AppColors.textSecondary.withAlpha(150),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'الهدف التكراري (مثلاً: 33)',
                    labelStyle: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = textController.text.trim();
                if (txt.isNotEmpty) {
                  final target = int.tryParse(countController.text.trim()) ?? 33;
                  setState(() {
                    _items.add(
                      TasbeehItem(
                        id: _items.length + 1,
                        text: txt,
                        targetCount: target > 0 ? target : 33,
                        fadl: 'ذكر مخصص أضفته بنفسك',
                        isCustom: true,
                      ),
                    );
                    _currentIndex = _items.length - 1;
                    _counter = 0;
                    _customTarget = null;
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              ),
              child: Text(
                'إضافة',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDhikrListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DhikrListSheet(
          items: _items,
          currentIndex: _currentIndex,
          onSelect: (idx) {
            Navigator.pop(ctx);
            _selectItem(idx);
          },
          onAddCustom: () {
            Navigator.pop(ctx);
            _showAddCustomDhikrDialog();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = FontSizeService.instance.getScale(AppFeature.tasbeeh);
    final target = _effectiveTarget;
    final progress = (target > 0) ? (_counter / target).clamp(0.0, 1.0) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          children: [
            // شريط التنقل بين الأذكار
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withAlpha(25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                    tooltip: 'الذكر السابق',
                    onPressed: _previousItem,
                  ),
                  InkWell(
                    onTap: _showDhikrListModal,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 16.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'الذكر ${_currentIndex + 1} من ${_items.length}',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18.sp,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                    tooltip: 'الذكر التالي',
                    onPressed: _nextItem,
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // بطاقة نص الذكر
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -100) {
                    _nextItem();
                  } else if (details.primaryVelocity! > 100) {
                    _previousItem();
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _currentItem.text,
                        key: ValueKey<int>(_currentItem.id),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: (22 * fontScale).sp,
                          height: 1.6,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (_currentItem.fadl != null &&
                        _currentItem.fadl!.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(14),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                _currentItem.fadl!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 11.5.sp,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // أزرار اختيار الهدف
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              alignment: WrapAlignment.center,
              children: [
                if (_currentItem.targetCount != 33 &&
                    _currentItem.targetCount != 100 &&
                    _currentItem.targetCount > 0)
                  _buildTargetChip(
                    label: '${_currentItem.targetCount}',
                    isSelected: _effectiveTarget == _currentItem.targetCount,
                    onTap: () => setState(
                      () => _customTarget = _currentItem.targetCount,
                    ),
                  ),
                _buildTargetChip(
                  label: '33',
                  isSelected: _effectiveTarget == 33,
                  onTap: () => setState(() => _customTarget = 33),
                ),
                _buildTargetChip(
                  label: '100',
                  isSelected: _effectiveTarget == 100,
                  onTap: () => setState(() => _customTarget = 100),
                ),
                _buildTargetChip(
                  label: 'مفتوح',
                  isSelected: _effectiveTarget == 0,
                  onTap: () => setState(() => _customTarget = 0),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            // عداد التسبيح مع مؤشر التقدم
            Stack(
              alignment: Alignment.center,
              children: [
                if (target > 0)
                  SizedBox(
                    width: 130.w,
                    height: 130.w,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4.w,
                      backgroundColor: AppColors.primary.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _counter.toString(),
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 50.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (target > 0)
                      Text(
                        'من أصل $target',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 22.h),

            // زر التسبيح الدائري الرئيسي
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 82.w,
                height: 82.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 42.sp,
                ),
              ),
            ),
            SizedBox(height: 22.h),

            // زر إعادة التصفير للذكر الحالي
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetCounter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  elevation: 2,
                ),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                label: Text(
                  'إعادة',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // شريط الإحصائيات والإعدادات السريعة
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'إجمالي التسبيحات: $_totalSessionCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _vibrationEnabled
                              ? Icons.vibration_rounded
                              : Icons.smartphone_rounded,
                          size: 24.sp,
                          color: _vibrationEnabled
                              ? AppColors.primary
                              : AppColors.textSecondary.withAlpha(120),
                        ),
                        tooltip: _vibrationEnabled
                            ? 'الاهتزاز مفعل'
                            : 'الاهتزاز معطل',
                        onPressed: () {
                          setState(() {
                            _vibrationEnabled = !_vibrationEnabled;
                          });
                        },
                      ),
                      if (_totalSessionCount > 0)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.delete_sweep_outlined,
                            size: 24.sp,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: 'تصفير إجمالي الجلسة',
                          onPressed: () {
                            setState(() {
                              _totalSessionCount = 0;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withAlpha(40),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 11.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// نافذة سفلية منبثقة لاختيار أي ذكر من قائمة الأذكار الـ 35
class _DhikrListSheet extends StatefulWidget {
  final List<TasbeehItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddCustom;

  const _DhikrListSheet({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onAddCustom,
  });

  @override
  State<_DhikrListSheet> createState() => _DhikrListSheetState();
}

class _DhikrListSheetState extends State<_DhikrListSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('\u0640', '')
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final normQuery = _normalize(_query);
    final filtered = widget.items.where((it) {
      if (normQuery.isEmpty) return true;
      final t = _normalize(it.text);
      final f = _normalize(it.fadl ?? '');
      return t.contains(normQuery) || f.contains(normQuery);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),

            // عنوان النافذة مع زر إضافة ذكر
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'قائمة الأذكار والتسبيحات (${widget.items.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                    onPressed: widget.onAddCustom,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                    icon: Icon(Icons.add_circle_outline_rounded, size: 16.sp),
                    label: Text(
                      'إضافة ذكر',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // شريط البحث
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: 'ابحث في الأذكار والتسبيحات...',
                  hintStyle: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13.sp,
                    color: AppColors.textSecondary.withAlpha(140),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: EdgeInsets.all(10.r),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            // قائمة الأذكار
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد أذكار مطابقة لبحثك',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final origIndex = widget.items.indexOf(item);
                        final isSelected = origIndex == widget.currentIndex;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onSelect(origIndex),
                            borderRadius: BorderRadius.circular(14.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withAlpha(20)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ترقيم الذكر
                                  Container(
                                    width: 28.w,
                                    height: 28.w,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.primary.withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${origIndex + 1}',
                                      style: TextStyle(
                                        fontFamily: 'Almarai',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),

                                  // تفاصيل الذكر
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.text,
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (item.fadl != null &&
                                            item.fadl!.isNotEmpty) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            item.fadl!,
                                            style: TextStyle(
                                              fontFamily: 'Almarai',
                                              fontSize: 11.5.sp,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),

                                  // شارة الهدف + علامة الاختيار
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(20),
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          '${item.targetCount}x',
                                          style: TextStyle(
                                            fontFamily: 'Almarai',
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        SizedBox(height: 6.h),
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 18.sp,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
