import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/formatters.dart';

/// Digits the app must never render: Arabic-Indic (٠-٩) and their extended
/// Persian variants (۰-۹).
final _nonWesternDigits = RegExp(r'[\u0660-\u0669\u06F0-\u06F9]');

/// Pumps [builder] under the same localization stack as the app and returns
/// what it produced for [locale].
Future<String> _format(
  WidgetTester tester,
  Locale locale,
  String Function(BuildContext context) builder,
) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Builder(
        builder: (context) {
          result = builder(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

/// Pumps [builder] with the [MaterialLocalizations] the app installs, so the
/// assertions cover what Flutter's own widgets render — the calendar grid in
/// `showDatePicker`, for one — and not only [Formatters].
Future<T> _withMaterialLocalizations<T>(
  WidgetTester tester,
  Locale locale,
  T Function(MaterialLocalizations l10n) builder,
) async {
  late T result;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Builder(
        builder: (context) {
          result = builder(MaterialLocalizations.of(context));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  // 20 June 2026 was a Saturday; 12:30 in the afternoon.
  final date = DateTime(2026, 6, 20, 12, 30);
  const english = Locale('en');
  const arabic = Locale('ar');

  group('English', () {
    testWidgets('formats the date, time and month in English words', (
      tester,
    ) async {
      expect(
        await _format(tester, english, (c) => Formatters.formatDate(c, date)),
        '20 June 2026',
      );
      expect(
        await _format(tester, english, (c) => Formatters.formatTime(c, date)),
        '12:30 PM',
      );
      expect(
        await _format(
          tester,
          english,
          (c) => Formatters.formatMonthYear(c, date),
        ),
        'June 2026',
      );
      expect(
        await _format(
          tester,
          english,
          (c) => Formatters.formatDateWithWeekday(c, date),
        ),
        'Saturday, 20 June 2026',
      );
      expect(
        await _format(
          tester,
          english,
          (c) => Formatters.formatDateTime(c, date),
        ),
        '20 June 2026, 12:30 PM',
      );
    });
  });

  group('Arabic', () {
    testWidgets('translates the words but keeps Western digits', (
      tester,
    ) async {
      expect(
        await _format(tester, arabic, (c) => Formatters.formatDate(c, date)),
        '20 يونيو 2026',
      );
      expect(
        await _format(tester, arabic, (c) => Formatters.formatTime(c, date)),
        '12:30 م',
      );
      expect(
        await _format(
          tester,
          arabic,
          (c) => Formatters.formatMonthYear(c, date),
        ),
        'يونيو 2026',
      );
      expect(
        await _format(
          tester,
          arabic,
          (c) => Formatters.formatDateWithWeekday(c, date),
        ),
        'السبت، 20 يونيو 2026',
      );
      expect(
        await _format(tester, arabic, (c) => Formatters.formatDateTime(c, date)),
        '20 يونيو 2026، 12:30 م',
      );
    });

    testWidgets('renders no Arabic-Indic digits for any month or hour', (
      tester,
    ) async {
      for (var month = 1; month <= 12; month++) {
        for (final hour in <int>[0, 9, 13, 23]) {
          final sample = DateTime(2026, month, 15, hour, 45);
          final rendered = await _format(
            tester,
            arabic,
            (c) =>
                '${Formatters.formatDateWithWeekday(c, sample)} '
                '${Formatters.formatDateTime(c, sample)} '
                '${Formatters.formatMonthYear(c, sample)}',
          );
          expect(
            _nonWesternDigits.hasMatch(rendered),
            isFalse,
            reason: 'month $month hour $hour rendered as "$rendered"',
          );
        }
      }
    });

    testWidgets('keeps prices in Western digits with comma grouping', (
      tester,
    ) async {
      expect(Formatters.formatPrice(1234567.89), '1,234,567.89');
      expect(Formatters.formatPrice(100), '100');
      expect(_nonWesternDigits.hasMatch(Formatters.formatPrice(12345)), isFalse);
    });

    testWidgets('leaves the Material date picker in Western digits', (
      tester,
    ) async {
      final rendered = await _withMaterialLocalizations(
        tester,
        arabic,
        (l10n) => [
          l10n.formatMediumDate(date),
          l10n.formatMonthYear(date),
          l10n.formatYear(date),
          for (var day = 1; day <= 31; day++) l10n.formatDecimal(day),
        ].join(' '),
      );
      expect(
        _nonWesternDigits.hasMatch(rendered),
        isFalse,
        reason: 'the calendar rendered as "$rendered"',
      );
      expect(rendered, contains('يونيو'));
    });
  });
}
