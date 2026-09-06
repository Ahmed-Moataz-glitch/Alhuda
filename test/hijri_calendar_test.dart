import 'package:alhuda/view/widgets/hijri_calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:hijri_date/moon_phases.dart';
import 'package:hijri_date/religious_event.dart';

void main() {
  group('Hijri Calendar & hijri_date Tests', () {
    setUpAll(() {
      HijriDate.setLocal('ar');
    });

    test('Hijri date converts from Gregorian properly in Arabic', () {
      final gregorian = DateTime(2026, 9, 6);
      final hijri = HijriDate.fromDate(gregorian);

      expect(hijri.hYear, 1448);
      expect(hijri.hMonth, 3); // ربيع الأول
      expect(hijri.longMonthName, 'ربيع الاول');
      expect(hijri.hDay, 24);
      expect(hijri.dayWeName, 'الأحد');
    });

    test('Days in Hijri month returns 29 or 30', () {
      final days = HijriDate().getDaysInMonth(1448, 1);
      expect(days, isIn([29, 30]));
    });

    test('Conversion between Hijri and Gregorian is bidirectional', () {
      final originalGregorian = DateTime(2024, 4, 10);
      final hijri = HijriDate.fromDate(originalGregorian);
      final convertedBack =
          HijriDate().hijriToGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);

      expect(convertedBack.year, originalGregorian.year);
      expect(convertedBack.month, originalGregorian.month);
      expect(convertedBack.day, originalGregorian.day);
    });

    test('Moon phase calculation works and returns valid illumination', () {
      final hijri = HijriDate.now();
      final moon = hijri.getMoonPhase();

      expect(moon.arabicName.isNotEmpty, true);
      expect(moon.illumination, inInclusiveRange(0.0, 1.0));
      expect(moon.phase, isA<MoonPhase>());
    });

    test('IslamicEventsManager returns events and hadiths', () {
      final events = IslamicEventsManager.allEvents;
      expect(events.isNotEmpty, true);

      final ramadan = IslamicEventsManager.findEventsByType(IslamicEventType.ramadan);
      expect(ramadan.isNotEmpty, true);
      expect(ramadan.first.month, 9);
      expect(ramadan.first.hadiths.isNotEmpty, true);
    });

    testWidgets('HijriCalendarWidget renders calendar, moon phase, and events',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(411, 869),
          child: const MaterialApp(
            home: HijriCalendarWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اليوم في التقويم الهجري'), findsOneWidget);
      expect(find.text('تفاصيل اليوم المحدد'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('أهم المناسبات والأعياد الإسلامية'),
        200,
      );
      expect(find.text('أهم المناسبات والأعياد الإسلامية'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('تحويل التاريخ (هجري / ميلادي)'),
        200,
      );
      expect(find.text('تحويل التاريخ (هجري / ميلادي)'), findsOneWidget);
    });
  });
}
