import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

/// The snackbar's distance from the bottom of the window.
double snackbarBottom(WidgetTester tester) {
  final positioned = tester.widgetList<Positioned>(
    find.ancestor(of: find.text('hello'), matching: find.byType(Positioned)),
  );
  return positioned.map((p) => p.bottom ?? 0).reduce((a, b) => a > b ? a : b);
}

Future<void> pumpWithKeyboard(WidgetTester tester, double keyboardHeight) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          ctx = context;
          return const Scaffold();
        },
      ),
    ),
  );
  CustomSnackbar.show(context: ctx, message: 'hello');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('clears the keyboard when one is open', (tester) async {
    await pumpWithKeyboard(tester, 300);
    expect(snackbarBottom(tester), greaterThanOrEqualTo(300));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('sits near the bottom when no keyboard is open', (tester) async {
    await pumpWithKeyboard(tester, 0);
    expect(snackbarBottom(tester), lessThan(100));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
