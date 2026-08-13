import 'package:flutter/material.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/home/pages/orders_tab.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:raheeq_main/storage/auth_storage.dart';

/// Where a notification tap should leave the user.
class NotificationDestination {
  /// Bottom nav tab of [HomeScreen] to land on.
  final int homeTab;

  /// Tab inside [OrdersTab], when [homeTab] is the orders tab.
  final int? ordersInnerTab;

  /// Page to open on top of the home screen; null lands on the tab itself.
  final WidgetBuilder? page;

  const NotificationDestination({
    this.homeTab = NotificationNavigator.homeTabIndex,
    this.ordersInnerTab,
    this.page,
  });
}

/// Navigation for anything opened by tapping a notification — the in-app
/// notifications list, a push notification, or a deep link.
///
/// The rule is that the back stack must match what the user would have had by
/// walking to the page from the home screen: the home screen on the matching
/// tab, then the page. Whatever the tap happened on — the notifications page
/// especially — is dropped, so back goes to the orders list rather than back
/// into the notifications list.
class NotificationNavigator {
  const NotificationNavigator._();

  /// Bottom nav indices of [HomeScreen].
  static const int homeTabIndex = 0;
  static const int ordersTabIndex = 1;

  /// Tab indices inside [OrdersTab].
  static const int upcomingOrdersTab = 0;
  static const int outForDeliveryOrdersTab = 1;
  static const int deliveredOrdersTab = 2;

  /// Payload keys the API uses for the order a notification is about.
  static const List<String> _orderIdKeys = [
    'subOrderId',
    'suborderid',
    'orderId',
    'orderid',
    'id',
  ];

  /// Resolves a notification payload to its destination, or null when the
  /// notification opens nothing (marketing, payment confirmations).
  ///
  /// Types are matched loosely because the payload vocabulary is the API's:
  /// anything about a delivery lands on the delivered orders and anything
  /// about a delivery in progress lands on out-for-delivery.
  ///
  /// [fallbackToOrders] decides what an unrecognised type does. A tap in the
  /// in-app list should always go somewhere, so it falls back to the orders
  /// list; a push tap stays put rather than yanking the user out of what they
  /// were doing for a notification this app does not know how to open.
  static NotificationDestination? destinationFor(
    Map<dynamic, dynamic> data, {
    bool fallbackToOrders = true,
  }) {
    if (data['category']?.toString().toUpperCase() == 'MARKETING') return null;

    final type = data['type']?.toString().toLowerCase() ?? '';

    if (type == 'order_confirmed') return null;

    if (type == 'payment_approved') {
      return const NotificationDestination(
        homeTab: ordersTabIndex,
        ordersInnerTab: upcomingOrdersTab,
      );
    }

    final orderId = _orderIdFrom(data);

    if (type.contains('out_for_delivery') || type.contains('on_the_way')) {
      return NotificationDestination(
        homeTab: ordersTabIndex,
        ordersInnerTab: outForDeliveryOrdersTab,
        page: _orderDetailsPage(orderId),
      );
    }

    if (type.contains('deliver')) {
      return NotificationDestination(
        homeTab: ordersTabIndex,
        ordersInnerTab: deliveredOrdersTab,
        page: _orderDetailsPage(orderId),
      );
    }

    if (!fallbackToOrders) return null;
    return const NotificationDestination(homeTab: ordersTabIndex);
  }

  /// Opens [destination]. Pass a [context] when one is at hand; otherwise the
  /// root navigator is used, which is what push taps and deep links have.
  static void open(NotificationDestination destination, {BuildContext? context}) {
    final navigator = context != null
        ? Navigator.of(context)
        : AuthStorage.navigatorKey.currentState;
    if (navigator == null) return;

    HomeScreen.switchTabNotifier.value = destination.homeTab;
    if (destination.ordersInnerTab != null) {
      OrdersTab.switchInnerTabNotifier.value = destination.ordersInnerTab;
    }

    if (HomeScreen.isLive) {
      // Pop down to the home screen already in the tree, keeping the data it
      // has loaded. Matching on the route name rather than `isFirst` matters
      // during the splash → home replacement, when the splash route is still
      // below the home route and popping to the first route would land back
      // on the splash screen.
      navigator.popUntil((route) => route.settings.name == HomeScreen.routeName);
    } else {
      // Tapped from a cold start: there is no home screen yet to go back to.
      navigator.pushAndRemoveUntil(HomeScreen.route(), (route) => false);
    }

    final page = destination.page;
    if (page != null) {
      navigator.push(MaterialPageRoute(builder: page));
    }
  }

  /// Opens the details of [orderId] as if it had been tapped in [OrdersTab].
  static void openOrderDetails(
    String orderId, {
    BuildContext? context,
    int ordersInnerTab = deliveredOrdersTab,
    bool autoPlayVideo = false,
  }) {
    open(
      NotificationDestination(
        homeTab: ordersTabIndex,
        ordersInnerTab: ordersInnerTab,
        page: (_) =>
            BookingDetailsPage(orderId: orderId, autoPlayVideo: autoPlayVideo),
      ),
      context: context,
    );
  }

  static WidgetBuilder? _orderDetailsPage(String? orderId) {
    if (orderId == null) return null;
    return (_) => BookingDetailsPage(orderId: orderId);
  }

  static String? _orderIdFrom(Map<dynamic, dynamic> data) {
    for (final key in _orderIdKeys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
