import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_bottom_nav.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const Center(child: Text("My Orders Page", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Impact Page", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Profile Page", style: TextStyle(fontSize: 24))),
  ];

  final List<CustomBottomNavItem> _navItems = [
    CustomBottomNavItem(icon: Icons.home_outlined, label: "Home"),
    CustomBottomNavItem(
      icon: Icons.shopping_bag_outlined,
      label: "My Orders",
    ),
    CustomBottomNavItem(icon: Icons.auto_graph_outlined, label: "Impact"),
    CustomBottomNavItem(icon: Icons.person_outline, label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important to allow bottom nav area to be transparent
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: const Text(
                "Raheeq",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              backgroundColor: AppColors.buttonBlueDark,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
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
          child: _pages[_currentIndex],
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
  }
}
