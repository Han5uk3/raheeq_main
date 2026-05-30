import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_bottom_nav.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/pages/profile_tab.dart';
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

  final List<Widget> _pages = [
    const HomeTab(),
    const Center(child: Text("My Orders Page", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Impact Page", style: TextStyle(fontSize: 24))),
    const ProfileTab(),
  ];

  final List<CustomBottomNavItem> _navItems = [
    CustomBottomNavItem(icon: Icons.home_outlined, label: "Home"),
    CustomBottomNavItem(icon: Icons.shopping_bag_outlined, label: "My Orders"),
    CustomBottomNavItem(icon: Icons.auto_graph_outlined, label: "Impact"),
    CustomBottomNavItem(icon: Icons.person_outline, label: "Profile"),
  ];

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

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 1:
        return "My Orders";
      case 2:
        return "Impact";
      case 3:
        return "Profile";
      default:
        return "Raheeq";
    }
  }

  String _getAppBarSubtitle() {
    switch (_currentIndex) {
      case 1:
        return "Track your mosque donations";
      case 2:
        return "Your ongoing charity rewards";
      case 3:
        return "Manage your account settings";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget scaffold = Scaffold(
      extendBody: true, // Important to allow bottom nav area to be transparent
      backgroundColor: Colors.transparent,
      appBar: (_currentIndex == 0 || _currentIndex == 3)
          ? null
          : CustomAppBar(
              title: _getAppBarTitle(),
              subtitle: _getAppBarSubtitle(),
              centerTitle: true,
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          decoration: (_currentIndex == 0 || _currentIndex == 3)
              ? null
              : const BoxDecoration(
                  color: Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
          child: (_currentIndex == 0 || _currentIndex == 3)
              ? _pages[_currentIndex]
              : ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: _pages[_currentIndex],
                ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );

    if (_currentIndex == 0) {
      return scaffold;
    }

    return Container(
      color: Colors.white, // Covers the black native window background
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.headerlightblue.withValues(alpha: 0.15),
              AppColors.headerlightblue,
            ],
            stops: const [
              0.0,
              0.18,
            ], // Seamless transition matching status bar + toolbarHeight
          ),
        ),
        child: scaffold,
      ),
    );
  }
}
