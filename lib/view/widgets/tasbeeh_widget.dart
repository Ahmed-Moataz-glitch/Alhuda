import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TasbeehWidget extends StatefulWidget {
  const TasbeehWidget({super.key});

  @override
  State<TasbeehWidget> createState() => _TasbeehWidgetState();
}

class _TasbeehWidgetState extends State<TasbeehWidget> {
  int counter = 0;
  List<String> tasbeeh = [
    'سبحان الله وبحمده سبحان الله العظيم\n',
    'لا حول ولا قوة إلا بالله\n',
    'سبحان الله والحمد لله ولا إله إلا الله والله أكبر\n',
    'أستغفر الله وأتوب إليه\n',
    'اللهم صلي وسلم على نبينا محمد صلى الله عليه وسلم\n',
    'سبحان الله\n',
    'الحمد لله\n',
    'لا إله إلا الله\n',
    'الله أكبر\n',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        spacing: 16.h,
        children: [
          SizedBox(height: size.height * 0.02),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     ElevatedButton(
          //       onPressed: () {},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: AppColors.primary,
          //         shape: const CircleBorder(),
          //         padding: EdgeInsets.all(12.r),
          //       ),
          //       child: Icon(
          //         Icons.arrow_back_ios_rounded,
          //         color: AppColors.background,
          //       ),
          //     ),
          //     Expanded(
          //       child: ,
          //     ),
          //     ElevatedButton(
          //       onPressed: () {},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: AppColors.primary,
          //         shape: const CircleBorder(),
          //         padding: EdgeInsets.all(12.r),
          //       ),
          //       child: Icon(
          //         Icons.arrow_forward_ios_rounded,
          //         color: AppColors.background,
          //       ),
          //     ),
          //   ],
          // ),
          Text(
            textAlign: TextAlign.center,
            tasbeeh[counter % tasbeeh.length],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 24.sp, color: AppColors.primary),
          ),
          SizedBox(height: 24.h),
          Text(
            counter.toString(),
            style: TextStyle(fontSize: 48.sp, color: AppColors.primary),
          ),
          SizedBox(height: 36.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                counter++;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(12.r),
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 36.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      counter = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(12.r),
                    ),
                    padding: EdgeInsets.all(12.r),
                  ),
                  child: Text(
                    'إعادة',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
