import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app pins `MediaQueryData.boldText` on in main.dart. These pin down the
/// property that makes that worth doing: it overrides the weight a widget asked
/// for, rather than only applying to text that left its weight unset.
FontWeight? renderedWeight(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText));
  return rich.text.style?.fontWeight;
}

Widget app(Widget child) => MediaQuery(
  data: const MediaQueryData(boldText: true),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets('overrides an inline light weight', (tester) async {
    await tester.pumpWidget(
      app(const Text('x', style: TextStyle(fontWeight: FontWeight.w300))),
    );
    expect(renderedWeight(tester), FontWeight.bold);
  });

  testWidgets('overrides an inline w500 weight', (tester) async {
    await tester.pumpWidget(
      app(const Text('x', style: TextStyle(fontWeight: FontWeight.w500))),
    );
    expect(renderedWeight(tester), FontWeight.bold);
  });
}
