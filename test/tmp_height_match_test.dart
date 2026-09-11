import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/home/pages/recurring_donations_page.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:shimmer/shimmer.dart';

ThemeData appTheme() => ThemeData(
  fontFamily: 'ManropeBold',
  fontFamilyFallback: const ['SaudiRiyal', 'SF Pro', 'NotoNaskhArabicBold'],
  useMaterial3: true,
);

Widget wrap(Widget child, Locale locale) => MaterialApp(
  locale: locale,
  theme: appTheme(),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final font in {
      'ManropeBold': 'assets/fonts/Manrope-Bold.ttf',
      'NotoNaskhArabicBold': 'assets/fonts/NotoNaskhArabic-Bold.ttf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          File(font.value).readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      await loader.load();
    }
    Hive.init(Directory.systemTemp.createTempSync('hive_h').path);
    await Hive.openBox(AppStorage.boxName);
    await Hive.openBox(AuthStorage.boxName);
  });

  /// Rebuilds the real card's vertical metrics from the same pieces the real
  /// card is made of, with the strings that locale actually shows.
  Future<double> expectedCardHeight(WidgetTester tester, Locale locale) async {
    final ar = locale.languageCode == 'ar';

    final parts = <String, Widget>{
      // "#SUB-1107" stays Latin in both locales.
      'number': const Text(
        '#SUB-1107',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      // Status pill: a localized label with 6px of vertical padding.
      'pill': Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              ar ? 'نشط' : 'Active',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      // Plan name, beside the 40px image.
      'plan': Text(
        ar ? 'مرتان أسبوعيا' : 'Gold Subscription',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      // start_date / expires_on labels.
      'label': Text(
        ar ? 'تاريخ البدء' : 'Start date',
        style: const TextStyle(fontSize: 12),
      ),
      // Date chip: a formatted date with 4px of vertical padding.
      'chip': Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          ar ? '١٠ سبتمبر ٢٠٢٦' : '10 Sep 2026',
          style: const TextStyle(fontSize: 10),
        ),
      ),
    };

    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Align(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in parts.entries)
                  KeyedSubtree(key: Key(e.key), child: e.value),
              ],
            ),
          ),
        ),
        locale,
      ),
    );

    double h(String k) => tester.getSize(find.byKey(Key(k))).height;
    double max2(double a, double b) => a > b ? a : b;

    final header = 16 + max2(h('number'), h('pill'));
    final body =
        16 + // Padding(all: 8)
        max2(40, h('plan')) +
        8 +
        1 + // divider
        8 +
        h('label') +
        8 +
        10 + // progress bar
        12 +
        h('chip');

    debugPrint(
      '${locale.languageCode} parts: number ${h('number')} pill ${h('pill')} '
      'plan ${h('plan')} label ${h('label')} chip ${h('chip')}',
    );

    return header + 1 /* header divider */ + body;
  }

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'subscriptions skeleton matches the real card height '
      '(${locale.languageCode})',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final expected = await expectedCardHeight(tester, locale);

        await tester.pumpWidget(wrap(const RecurringDonationsPage(), locale));
        await tester.pump();

        final skeleton = tester
            .getSize(
              find
                  .ancestor(
                    of: find.byType(Shimmer).first,
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .height;

        debugPrint(
          '${locale.languageCode}: skeleton $skeleton vs real $expected',
        );
        expect(skeleton, expected);

        await tester.pump(const Duration(seconds: 10));
        tester.takeException();
      },
    );
  }
}
