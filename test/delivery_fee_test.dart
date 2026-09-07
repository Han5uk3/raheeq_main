import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/common_widgets/delivery_fee_value.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/models/order_response_model.dart';

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

/// The struck-through amount, or null when nothing is struck through.
String? _strikethroughText(WidgetTester tester) {
  final struck = tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.style?.decoration == TextDecoration.lineThrough);
  return struck.isEmpty ? null : struck.single.data;
}

void main() {
  group('OrderFinancials — booking details', () {
    test('a charged delivery is not free', () {
      final financials = OrderFinancials.fromJson({
        'deliveryFee': 25,
        'totalAmount': 125,
      });
      expect(financials.hasFreeDelivery, isFalse);
      expect(financials.deliveryFee, 25);
    });

    test('reads the backend flag when the fee is reported as the original', () {
      // Contract A: the fee stays populated and a flag marks it waived.
      final financials = OrderFinancials.fromJson({
        'deliveryFee': 25,
        'isFreeDelivery': true,
      });
      expect(financials.hasFreeDelivery, isTrue);
      expect(financials.strikethroughDeliveryFee, 25);
    });

    test('infers free delivery from a zeroed fee plus an original', () {
      // Contract B: the charged fee drops to 0 and the original is separate.
      final financials = OrderFinancials.fromJson({
        'deliveryFee': 0,
        'originalDeliveryFee': 25,
      });
      expect(financials.hasFreeDelivery, isTrue);
      expect(financials.strikethroughDeliveryFee, 25);
    });

    test('accepts the alternate original-fee key names', () {
      for (final key in ['deliveryFeeBeforeDiscount', 'baseDeliveryFee']) {
        final financials = OrderFinancials.fromJson({
          'deliveryFee': 0,
          key: 30,
        });
        expect(financials.strikethroughDeliveryFee, 30, reason: key);
        expect(financials.hasFreeDelivery, isTrue, reason: key);
      }
    });

    test('picks up free-delivery fields from the order root', () {
      final order = OrderResponseModel.fromJson({
        'isFreeDelivery': true,
        'originalDeliveryFee': 25,
        'financials': {'deliveryFee': 0, 'totalAmount': 100},
      });
      expect(order.financials!.hasFreeDelivery, isTrue);
      expect(order.financials!.strikethroughDeliveryFee, 25);
    });

    test('financials win over the root when both carry the field', () {
      final order = OrderResponseModel.fromJson({
        'originalDeliveryFee': 99,
        'financials': {'deliveryFee': 0, 'originalDeliveryFee': 25},
      });
      expect(order.financials!.strikethroughDeliveryFee, 25);
    });

    test('has nothing to strike through when no fee is reported at all', () {
      final financials = OrderFinancials.fromJson({
        'deliveryFee': 0,
        'isFreeDelivery': true,
      });
      expect(financials.hasFreeDelivery, isTrue);
      expect(financials.strikethroughDeliveryFee, isNull);
    });
  });

  group('Checkout — contribution details', () {
    Checkout checkoutWith(Map<String, dynamic> pricing) =>
        Checkout.fromJson({'pricing': pricing, 'items': []});

    test('a charged delivery is not free', () {
      final checkout = checkoutWith({'deliveryFee': 25});
      expect(checkout.hasFreeDelivery, isFalse);
      expect(checkout.totalDeliveryFee, 25);
    });

    test('reads the pricing flag alongside the original fee', () {
      final checkout = checkoutWith({
        'deliveryFee': 25,
        'isFreeDelivery': true,
      });
      expect(checkout.hasFreeDelivery, isTrue);
      expect(checkout.strikethroughDeliveryFee, 25);
    });

    test('infers free delivery from a zeroed fee plus an original', () {
      final checkout = checkoutWith({
        'deliveryFee': 0,
        'originalDeliveryFee': 25,
      });
      expect(checkout.hasFreeDelivery, isTrue);
      expect(checkout.strikethroughDeliveryFee, 25);
    });

    test('has nothing to strike through when no fee is reported at all', () {
      final checkout = checkoutWith({
        'deliveryFee': 0,
        'isFreeDelivery': true,
      });
      expect(checkout.hasFreeDelivery, isTrue);
      expect(checkout.strikethroughDeliveryFee, isNull);
    });
  });

  group('DeliveryFeeValue', () {
    const baseStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    testWidgets('a charged fee renders plainly, with no "Free"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DeliveryFeeValue(
            isFree: false,
            amount: 25,
            baseStyle: baseStyle,
          ),
        ),
      );
      expect(find.textContaining('25.00'), findsOneWidget);
      expect(find.text('Free'), findsNothing);
      expect(_strikethroughText(tester), isNull);
    });

    testWidgets('a free delivery strikes the original and shows "Free"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DeliveryFeeValue(
            isFree: true,
            amount: 25,
            baseStyle: baseStyle,
          ),
        ),
      );
      // The point of the change: never a bare zero.
      expect(find.textContaining('0.00'), findsNothing);
      expect(_strikethroughText(tester), contains('25.00'));
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('"Free" itself is never struck through', (tester) async {
      await tester.pumpWidget(
        _app(
          const DeliveryFeeValue(
            isFree: true,
            amount: 25,
            baseStyle: TextStyle(decoration: TextDecoration.lineThrough),
          ),
        ),
      );
      final free = tester.widget<Text>(find.text('Free'));
      expect(free.style?.decoration, TextDecoration.none);
    });

    testWidgets('shows only "Free" when there is no fee to strike', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DeliveryFeeValue(
            isFree: true,
            amount: null,
            baseStyle: baseStyle,
          ),
        ),
      );
      expect(find.text('Free'), findsOneWidget);
      expect(_strikethroughText(tester), isNull);
      expect(find.textContaining('SAR'), findsNothing);
    });

    testWidgets('localizes "Free" and keeps the amount in Western digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DeliveryFeeValue(
            isFree: true,
            amount: 25,
            baseStyle: baseStyle,
          ),
          locale: const Locale('ar'),
        ),
      );
      expect(find.text('مجانًا'), findsOneWidget);
      expect(_strikethroughText(tester), contains('25.00'));
      expect(
        RegExp(r'[٠-٩]').hasMatch(_strikethroughText(tester)!),
        isFalse,
      );
    });
  });
}
