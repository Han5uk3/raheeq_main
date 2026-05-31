import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/user.dart';
import 'package:raheeq_main/pages/home/pages/my_profile_screen.dart';
import 'package:raheeq_main/pages/home/pages/saved_mosques_page.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/pages/home/pages/my_wallet_page.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/home/pages/notifications_page.dart';
import 'package:raheeq_main/pages/home/pages/recurring_donations_page.dart';
import 'package:raheeq_main/pages/home/pages/app_settings_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = false;
  bool _isSaving = false; // Used for logout loading state
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = AuthStorage.user;

    // Refresh user profile silently on load to match production APIs
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService().getProfile();
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _currentUser = AuthStorage.user;
          });
        }
      }
    } catch (e) {
      // Fail silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out of Raheeq?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      // Call API logout silently to notify server, then wipe storage
      final refToken = AuthStorage.refreshToken ?? '';
      await ApiService().logout(refreshToken: refToken);

      // Clear storage (this will automatically pop routes and redirect to Login via navigatorKey)
      await AuthStorage.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("No session found. Please log in.")),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            key: const ValueKey('content'),
            physics: const ClampingScrollPhysics(),
            child: Column(
                      children: [
                        // Scrollable Header mimicking the original AppBar
                        Container(
                          width: double.infinity,
                          color: const Color(0x4D91E3FE),
                          padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Profile",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Manage your account settings",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.headersubtitlecolor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Rounded gray sheet containing all sections
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildInfoCard(),
                                const SizedBox(height: 16),
                                _buildSection("Account", [
                                  _buildMenuTile(
                                    icon: Icons.person_outline_rounded,
                                    title: "Personal Information",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MyProfileScreen(),
                                        ),
                                      ).then((_) {
                                        // Refresh user info when returning from subpage
                                        if (mounted) {
                                          setState(() {
                                            _currentUser = AuthStorage.user;
                                          });
                                        }
                                      });
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.favorite_border_rounded,
                                    title: "Saved Mosques",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SavedMosquesPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.cached_rounded,
                                    title: "Recurring Donations",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const RecurringDonationsPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.description_outlined,
                                    title: "Tax Receipts",
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tax Reciepts page coming soon",
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                _buildSection("Payment & orders", [
                                  _buildMenuTile(
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: "My Wallet",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const MyWalletPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.payment_outlined,
                                    title: "Payment Methods",
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Redirecting to My Payment Methods...",
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Symbols.package_2,
                                    title: "Order History",
                                    onTap: () {
                                      HomeScreen.switchTabNotifier.value = 1;
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                _buildSection("Settings", [
                                  _buildMenuTile(
                                    icon: Icons.notifications_outlined,
                                    title: "Notifications",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const NotificationsPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.shield_outlined,
                                    title: "Terms and Conditions",
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Redirecting to Terms and Conditions...",
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.settings_outlined,
                                    title: "App Settings",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AppSettingsPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 16),

                                _buildSection("Support", [
                                  _buildMenuTile(
                                    icon: Icons.help_outline,
                                    title: "Help Center",
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Help Center page coming soon",
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildMenuTile(
                                    icon: Icons.phone_outlined,
                                    title: "Contact Us",
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Contact us page coming soon",
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ]),

                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _logout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonBlueDark,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      fixedSize: Size(double.infinity, 50),
                                    ),

                                    child: Text("Log Out"),
                                  ),
                                ),
                                const SizedBox(height: 150),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Card(
      color: Colors.white,
      elevation: 1,
      borderOnForeground: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(color: AppColors.black, fontSize: 16),
            ),
          ),
          const Divider(color: Color(0xFFEAEFF2), height: 1),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return items[index];
            },
            separatorBuilder: (context, index) {
              return const Divider(color: Color(0xFFEAEFF2), height: 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 84, // radius 42 * 2
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                      colors: [
                        Color(
                          0xFFBCECF5,
                        ), // Bright white-blue light beam origin
                        AppColors.headerlightblue, // Light blue transition
                        AppColors.buttonBlueDark, // Deep blue base
                      ],
                      stops: [0.0, 0.05, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.headerlightblue.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 16,
                        offset: const Offset(-4, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentUser!.firstName.substring(0, 1).toUpperCase() +
                          _currentUser!.lastName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser!.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCardItem("24", "Donations"),
                _buildInfoCardItem("8", "Mosques"),
                _buildInfoCardItem("2.4K", "People"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.buttonBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,

    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF48B3D2), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[300],
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
