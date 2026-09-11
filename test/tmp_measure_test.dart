import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';

Widget wrap(Widget child) => MaterialApp(
  locale: const Locale('en'),
  theme: ThemeData(fontFamily: 'ManropeBold', useMaterial3: true),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('ManropeBold')
      ..addFont(
        File('assets/fonts/Manrope-Bold.ttf').readAsBytes().then(
          (b) => ByteData.view(b.buffer),
        ),
      );
    await loader.load();
    Hive.init(Directory.systemTemp.createTempSync('hive_measure').path);
    await Hive.openBox(AppStorage.boxName);
    await Hive.openBox(AuthStorage.boxName);
  });

  // Height of a line of text in the exact style the real cards use.
  Future<double> lineHeight(WidgetTester tester, TextStyle style) async {
    await tester.pumpWidget(
      wrap(Align(child: Text('Sample #SUB-1107', style: style))),
    );
    return tester.getSize(find.text('Sample #SUB-1107')).height;
  }

  testWidgets('real text line heights', (tester) async {
    for (final entry in {
      'number 14 bold': const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      'plan name 16 bold': const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      'status pill 12 w600': const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      'label 12': const TextStyle(fontSize: 12),
      'date chip 10': const TextStyle(fontSize: 10),
      'title 18 bold': const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      'subtitle 14': const TextStyle(fontSize: 14),
      'banner 12 bold': const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      'weekday 11 w600': const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      'legend 11': const TextStyle(fontSize: 11),
    }.entries) {
      debugPrint('${entry.key}: ${await lineHeight(tester, entry.value)}');
    }
  });

  testWidgets('app bar height with and without subtitle', (tester) async {
    for (final subtitle in ['', 'SUB-1107', 'Manage your subscriptions']) {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              CustomAppBar(
                hasBackgroundColor: true,
                isStartAligned: true,
                title: 'Subscription details',
                subtitle: subtitle,
                showBackButton: true,
                onBackTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final h = tester.getSize(find.byType(CustomAppBar)).height;
      debugPrint('subtitle "$subtitle" -> app bar height $h');
    }
  });

  testWidgets('status pill and date chip heights', (tester) async {
    await tester.pumpWidget(
      wrap(
        Align(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const Key('pill'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Active',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                key: const Key('chip'),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: const Text('10 Sep 2026', style: TextStyle(fontSize: 10)),
              ),
              Container(
                key: const Key('banner'),
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Delivered 0 of 17 orders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (final k in ['pill', 'chip', 'banner']) {
      debugPrint('$k: ${tester.getSize(find.byKey(Key(k))).height}');
    }
  });
}
