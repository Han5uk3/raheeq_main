import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_bottom_nav.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/services/freshchat_service.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/pages/profile_tab.dart';
import 'package:raheeq_main/pages/home/pages/orders_tab.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/services/deep_link_service.dart';
import 'package:raheeq_main/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Write a tab index to this notifier to switch the bottom nav tab remotely.
  static final ValueNotifier<int?> switchTabNotifier = ValueNotifier(null);

  /// Name carried by every home screen route, so a notification tap can pop
  /// back down to the existing home screen — see `NotificationNavigator`.
  static const String routeName = '/home';

  /// The route for the home screen. Everything that opens it goes through
  /// here, which is what keeps [routeName] on the route.
  static Route<void> route() => MaterialPageRoute(
    settings: const RouteSettings(name: routeName),
    builder: (_) => const HomeScreen(),
  );

  static int _liveCount = 0;

  /// Whether a home screen is currently in the tree. When it is false there is
  /// nothing to pop back to and a fresh home screen has to be built.
  static bool get isLive => _liveCount > 0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    return [
      const HomeTab(),
      const OrdersTab(),
      Center(
        child: Text(
          AppLocalizations.of(context)!.contact_us,
          style: const TextStyle(fontSize: 24),
        ),
      ),
      const ProfileTab(),
    ];
  }

  @override
  void initState() {
    super.initState();
    HomeScreen._liveCount++;
    HomeScreen.switchTabNotifier.addListener(_onSwitchTab);
    _onSwitchTab(); // Process any pre-set tab value
    WidgetsBinding.instance.addObserver(this);
    FreshchatService.refreshUnreadCount();
    DeepLinkService().init();
    DeepLinkService().processPendingDeepLink();
    NotificationService().markHomeScreenReady();
  }

  @override
  void dispose() {
    HomeScreen._liveCount--;
    HomeScreen.switchTabNotifier.removeListener(_onSwitchTab);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The chat is a native screen, so reading it there never rebuilds anything
  /// on this side. Coming back from it — or from the background after a chat
  /// push — is the moment to take the count again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FreshchatService.refreshUnreadCount();
    }
  }

  void _onSwitchTab() {
    final idx = HomeScreen.switchTabNotifier.value;
    if (idx != null) {
      setState(() {
        _currentIndex = idx;
      });
      HomeScreen.switchTabNotifier.value = null;
    }
  }

  String _getAppBarTitle(BuildContext context) {
    switch (_currentIndex) {
      case 1:
        return AppLocalizations.of(context)!.my_orders;
      case 2:
        return AppLocalizations.of(context)!.contact_us;
      case 3:
        return AppLocalizations.of(context)!.account;
      default:
        return AppLocalizations.of(context)!.raheeq;
    }
  }

  String _getAppBarSubtitle(BuildContext context) {
    switch (_currentIndex) {
      case 1:
        return AppLocalizations.of(context)!.track_your_donations;
      case 2:
        return "";
      case 3:
        return AppLocalizations.of(context)!.manage_account_settings;
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget scaffold = Scaffold(
      extendBody: true, // Important to allow bottom nav area to be transparent
      backgroundColor: Colors.white,
      appBar: (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3)
          ? null
          : CustomAppBar(
              hasBackgroundColor: true,
              title: _getAppBarTitle(context),
              subtitle: _getAppBarSubtitle(context),
              centerTitle: true,
            ),
      body: Container(
        key: ValueKey<int>(_currentIndex),
        decoration:
            (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3)
            ? null
            : const BoxDecoration(
                color: Color(0xFFF8FAFB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
        child: (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3)
            ? _buildPages(context)[_currentIndex]
            : ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: _buildPages(context)[_currentIndex],
              ),
      ),
    
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: FreshchatService.unreadCount,
        builder: (context, unreadChats, _) => CustomBottomNavBar(
          currentIndex: _currentIndex,
          items: [
            CustomBottomNavItem(
              icon: Icons.home_outlined,
              label: AppLocalizations.of(context)!.home,
            ),
            CustomBottomNavItem(
              icon: Icons.shopping_bag_outlined,
              label: AppLocalizations.of(context)!.orders,
            ),
            CustomBottomNavItem(
              icon: Icons.support_agent_outlined,
              label: AppLocalizations.of(context)!.contact_us,
              showBadge: unreadChats > 0,
            ),
            CustomBottomNavItem(
              icon: Icons.person_outline,
              label: AppLocalizations.of(context)!.account,
            ),
          ],
          onTap: (index) {
            if (index == 2) {
              FreshchatService.showConversations(
                context,
                tags: FreshchatService.supportTags,
                filteredViewTitle: "Rahiq Support",
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
        ),
      ),
    );

    Widget finalWidget = _currentIndex == 0
        ? scaffold
        : Container(
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.headerlightblue.withValues(alpha: 0.15),
                    AppColors.headerlightblue,
                  ],
                  stops: const [0.0, 0.18],
                ),
              ),
              child: scaffold,
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          }
        }
      },
      child: finalWidget,
    );
  }
}
