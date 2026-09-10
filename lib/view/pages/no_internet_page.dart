import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NoInternetPage extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetPage({super.key, this.onRetry});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> {
  bool _isChecking = false;

  Future<void> _checkConnection() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    widget.onRetry?.call();

    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (!mounted) return;

      if (!isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ما زال الاتصال بالإنترنت غير متاح، يرجى المحاولة بعد قليل.',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 13.sp,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.brown.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // أيقونة انقطاع الاتصال
                  Container(
                    width: 140.w,
                    height: 140.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 2.w,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 70.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // عنوان الصفحة
                  Text(
                    'لا يوجد اتصال بالإنترنت',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),

                  // وصف المشكلة
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'يرجى التأكد من اتصالك بشبكة الواي فاي (Wi-Fi) أو تفعيل بيانات الهاتف والمحاولة مرة أخرى.',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 36.h),

                  // زر إعادة المحاولة
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                      ),
                      child: _isChecking
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'إعادة المحاولة',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // تنبيه العودة التلقائية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16.sp,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'ستتم العودة تلقائياً فور توفر الاتصال',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
