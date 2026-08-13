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

  /// Tab index of the delivered orders inside [OrdersTab].
  static const int deliveredOrdersTab = 2;

  /// Payload keys the API uses for the order a notification is about.
  static const List<String> _orderIdKeys = ['subOrderId'];

  /// The delivery confirmation — the one notification that opens a page. The
  /// API names it `order_confirmed` ("Delivery Confirmed … you can now view
  /// the delivery proof"); the alias is here in case that name is ever
  /// spelled the way it reads.
  static const List<String> _deliveryConfirmedTypes = [
    'order_confirmed',
    'delivery_confirmed',
  ];

  /// Resolves a notification payload to its destination, or null when the
  /// notification opens nothing.
  ///
  /// Only a delivery confirmation navigates, and only when it names the order
  /// it is about. Every other notification — review updates, payment
  /// approvals, marketing — is read-only: tapping it marks it read and leaves
  /// the user where they were.
  static NotificationDestination? destinationFor(Map<dynamic, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    if (!_deliveryConfirmedTypes.contains(type)) return null;

    final orderId = _orderIdFrom(data);
    if (orderId == null) return null;

    return NotificationDestination(
      homeTab: ordersTabIndex,
      ordersInnerTab: deliveredOrdersTab,
      page: (_) => BookingDetailsPage(orderId: orderId),
    );
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
