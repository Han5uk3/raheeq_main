import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/common_widgets/sign_in_required_dialog.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

/// Wraps [child] in the app's localization stack so `AppLocalizations` resolves.
Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('ar')],
  home: Scaffold(body: child),
);

/// Resolves the localizations for [locale] without going through a widget.
Future<AppLocalizations> _l10n(Locale locale) =>
    AppLocalizations.delegate.load(locale);

/// The explanatory sentence the panel is showing — the one line that changes
/// from action to action.
String _messageShown(WidgetTester tester, AppLocalizations l10n) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where((t) => t != l10n.sign_in_required && t != l10n.sign_in);
  return texts.single;
}

void main() {
  group('guest sign-in prompt', () {
    testWidgets('every action explains itself in its own words', (
      tester,
    ) async {
      final l10n = await _l10n(const Locale('en'));
      final seen = <String>{};

      for (final action in GuestAction.values) {
        await tester.pumpWidget(_app(GuestSignInPanel(action: action)));

        expect(find.text(l10n.sign_in_required), findsOneWidget);
        expect(find.text(l10n.sign_in), findsOneWidget);

        final message = _messageShown(tester, l10n);
        expect(
          message,
          contains('Sign in to your Rahiq account'),
          reason: '$action should say why signing in is needed',
        );

        // The whole point of the enum: no two actions share a sentence, so the
        // ask always reads as being about what the user just tapped.
        expect(
          seen.add(message),
          isTrue,
          reason: '$action reuses a message another action already shows',
        );
      }
    });

    testWidgets('every action is translated into Arabic', (tester) async {
      final l10n = await _l10n(const Locale('ar'));

      for (final action in GuestAction.values) {
        await tester.pumpWidget(
          _app(GuestSignInPanel(action: action), locale: const Locale('ar')),
        );

        expect(
          find.text(l10n.sign_in_required),
          findsOneWidget,
          reason: 'the Arabic title should render for $action',
        );
        // A missing Arabic ARB entry falls back to the English template, so
        // English text surviving here means the translation was never added.
        expect(
          find.textContaining('Sign in to your Rahiq account'),
          findsNothing,
          reason: '$action is missing its Arabic translation',
        );
      }
    });
  });
}
