import 'package:flutter/material.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:raheeq_main/common_widgets/custom_bottom_nav.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/pages/profile_tab.dart';
import 'package:raheeq_main/pages/home/pages/orders_tab.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Write a tab index to this notifier to switch the bottom nav tab remotely.
  static final ValueNotifier<int?> switchTabNotifier = ValueNotifier(null);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    HomeScreen.switchTabNotifier.addListener(_onSwitchTab);
  }

  @override
  void dispose() {
    HomeScreen.switchTabNotifier.removeListener(_onSwitchTab);
    super.dispose();
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
        return AppLocalizations.of(context)!.profile;
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
      backgroundColor: Colors.transparent,
      appBar: (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3)
          ? null
          : CustomAppBar(
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
      bottomNavigationBar: CustomBottomNavBar(
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
          ),
          CustomBottomNavItem(
            icon: Icons.person_outline,
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            Freshchat.showConversations(
              tags: const ["chat_with_us"],
              filteredViewTitle: "Rahiq Support",
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
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
