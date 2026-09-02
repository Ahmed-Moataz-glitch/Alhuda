import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/tasbeeh_widget.dart';
import 'package:alhuda/view/widgets/azkar_widget.dart';
import 'package:alhuda/view/widgets/qibla_widget.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'الهُدى',
          style: TextStyle(
            fontSize: 24.sp,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            SizedBox(height: size.height * 0.04),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ButtonsTabBar(
                contentCenter: true,
                controller: tabController,
                tabs: const [
                  Tab(text: 'التسبيح الحر'),
                  Tab(text: 'الاذكار'),
                  Tab(text: 'القبلة'),
                ],
                labelStyle: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                ),
                contentPadding: EdgeInsets.all(8.r),
                buttonMargin: EdgeInsets.symmetric(horizontal: 16.r),
                backgroundColor: AppColors.primary,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: const [
                  TasbeehWidget(),
                  AzkarWidget(),
                  QiblaWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
