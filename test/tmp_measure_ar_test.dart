import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

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
  });

  testWidgets('arabic line heights', (tester) async {
    for (final size in [10.0, 11.0, 12.0, 14.0, 16.0, 18.0]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          theme: ThemeData(
            fontFamily: 'ManropeBold',
            fontFamilyFallback: const [
              'SaudiRiyal',
              'SF Pro',
              'NotoNaskhArabicBold',
            ],
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              child: Text('مرتان أسبوعيا', style: TextStyle(fontSize: size)),
            ),
          ),
        ),
      );
      debugPrint('ar $size -> ${tester.getSize(find.byType(Text).first).height}');
    }
  });
}
