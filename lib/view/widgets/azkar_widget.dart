import 'package:alhuda/model/azkar_model.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AzkarWidget extends StatefulWidget {
  const AzkarWidget({super.key});

  @override
  State<AzkarWidget> createState() => _AzkarWidgetState();
}

class _AzkarWidgetState extends State<AzkarWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 48.r),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          itemCount: azkar.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            return InkWell(
              splashFactory: NoSplash.splashFactory,
              onTap: () {
                setState(() {
                  azkar[index] = azkar[index].copyWith(
                    isPressed: !azkar[index].isPressed,
                  );
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: azkar[index].isPressed
                      ? AppColors.primary.withAlpha(20)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary),
                ),
                padding: EdgeInsets.all(8.r),
                child: Column(
                  spacing: 8.h,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          azkar[index].title,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          azkar[index].isPressed
                              ? Icons.remove_rounded
                              : Icons.add_rounded,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ],
                    ),
                    azkar[index].isPressed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: AppColors.primary,
                                indent: 0,
                                endIndent: 0,
                                thickness: 1.5.sp,
                              ),
                              Text(
                                azkar[index].content,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
