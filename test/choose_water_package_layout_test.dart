import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/pages/order/choose_water_package_screen.dart';

const _longName = 'A Very Long Product Name That Certainly Wraps Onto Two Lines';
const _longMessage = 'A rather long note that will certainly need two lines';

Product product({
  required String id,
  required String name,
  required double price,
  String? message,
}) => Product(
  id: id,
  serialNumber: 1, // carton, so it becomes a slot
  name: name,
  nameAr: name,
  subtitle: '',
  subtitleAr: '',
  message: message,
  messageAr: message,
  price: price,
  image: '',
  isHighNeed: false,
  presetQuantities: const [1],
  minQuantity: 1,
);

Future<void> pumpScreen(WidgetTester tester, List<Product> products) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: ChooseWaterPackageScreen(
        selectedCategories: const [],
        availableProducts: products,
      ),
    ),
  );
  await tester.pump();
}

/// Vertical offset of the price line showing [price].
double priceTop(WidgetTester tester, String price) =>
    tester.getTopLeft(find.textContaining(price).first).dy;

void main() {
  testWidgets('a wrapping title does not shift the price on other cards', (
    tester,
  ) async {
    await pumpScreen(tester, [
      product(id: 'a', name: 'Short', price: 111, message: 'note'),
      product(id: 'b', name: _longName, price: 222, message: 'note'),
    ]);

    expect(
      priceTop(tester, '111'),
      moreOrLessEquals(priceTop(tester, '222'), epsilon: 0.5),
      reason: 'prices should sit on the same line across cards',
    );
  });

  testWidgets('a wrapping subtitle does not shift the price on other cards', (
    tester,
  ) async {
    await pumpScreen(tester, [
      product(id: 'a', name: 'Short', price: 111, message: 'hi'),
      product(id: 'b', name: 'Tiny', price: 222, message: _longMessage),
    ]);

    expect(
      priceTop(tester, '111'),
      moreOrLessEquals(priceTop(tester, '222'), epsilon: 0.5),
      reason: 'the subtitle row should reserve the same height on both cards',
    );
  });

  testWidgets('a row stays one line when no card needs two', (tester) async {
    // The second line is only reserved when something actually wraps, so the
    // all-short list must sit higher than the one containing a wrapped title.
    await pumpScreen(tester, [
      product(id: 'a', name: 'Short', price: 111, message: 'hi'),
      product(id: 'b', name: 'Tiny', price: 222, message: 'hi'),
    ]);
    final noneWrapping = priceTop(tester, '111');

    await pumpScreen(tester, [
      product(id: 'a', name: 'Short', price: 111, message: 'hi'),
      product(id: 'b', name: _longName, price: 222, message: 'hi'),
    ]);
    final oneWrapping = priceTop(tester, '111');

    expect(noneWrapping, lessThan(oneWrapping));
  });

  testWidgets('a row nobody fills is dropped entirely', (tester) async {
    await pumpScreen(tester, [
      product(id: 'a', name: 'Short', price: 111, message: 'hi'),
      product(id: 'b', name: 'Tiny', price: 222, message: 'hi'),
    ]);
    final withSubtitles = priceTop(tester, '111');

    await pumpScreen(tester, [
      product(id: 'a', name: 'Short', price: 111),
      product(id: 'b', name: 'Tiny', price: 222),
    ]);
    final withoutSubtitles = priceTop(tester, '111');

    expect(find.text('hi'), findsNothing);
    expect(
      withoutSubtitles,
      lessThan(withSubtitles),
      reason: 'an empty subtitle row should take no space at all',
    );
  });
}
