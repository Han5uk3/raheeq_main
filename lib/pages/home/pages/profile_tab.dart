import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/home/pages/app_settings_page.dart';
import 'package:raheeq_main/pages/home/pages/my_wallet_page.dart';
import 'package:raheeq_main/pages/home/pages/notifications_page.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/user.dart';
import 'package:raheeq_main/pages/home/pages/my_profile_screen.dart';
import 'package:raheeq_main/pages/home/pages/saved_mosques_page.dart';
import 'package:raheeq_main/pages/home/pages/recurring_donations_page.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:raheeq_main/pages/home/pages/contact_us_page.dart';
import 'package:raheeq_main/pages/home/pages/customer_reviews_page.dart';
import 'package:raheeq_main/pages/home/pages/my_chillers_page.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = false;
  bool _isSaving = false; // Used for logout loading state
  User? _currentUser;
  int _unreadNotificationsCount = 0;

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
    }
    try {
      final unreadRes = await ApiService().getUnreadNotificationsCount();
      if (unreadRes.statusCode == 200 && unreadRes.data['success'] == true) {
        final countData = unreadRes.data['data'];
        if (countData != null && countData['count'] != null) {
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = countData['count'] as int;
            });
          }
        } else if (countData is int) {
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = countData;
            });
          }
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.logout,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.logout_confirmation,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.buttonBlueDark,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.no_session)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        key: const ValueKey('content'),
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Scrollable Header mimicking the original AppBar
            Container(
              width: double.infinity,
              color: const Color(0x4D91E3FE),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 60, 16, 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.profile,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.manage_account_settings,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildSection(
                      AppLocalizations.of(context)!.account_section,
                      [
                        _buildMenuTile(
                          icon: Icons.person_outline_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.personal_information,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyProfileScreen(),
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
                          title: AppLocalizations.of(context)!.saved_mosques,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedMosquesPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuTile(
                          icon: Icons.cached_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.recurring_donations,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecurringDonationsPage(),
                              ),
                            );
                          },
                        ),
                        // _buildMenuTile(
                        //   icon: Icons.description_outlined,
                        //   title: AppLocalizations.of(context)!.tax_receipts,
                        //   onTap: () {
                        //     CustomSnackbar.show(
                        //       context: context,
                        //       message: AppLocalizations.of(
                        //         context,
                        //       )!.feature_coming_soon,
                        //       duration: Duration(seconds: 1),
                        //       bottomMargin: 130,
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      AppLocalizations.of(context)!.payment_orders_section,
                      [
                        _buildMenuTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: AppLocalizations.of(context)!.my_wallet,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyWalletPage(),
                              ),
                            );
                          },
                        ),
                        // _buildMenuTile(
                        //   icon: Icons.payment_outlined,
                        //   title: AppLocalizations.of(context)!.payment_methods,
                        //   onTap: () {
                        //     CustomSnackbar.show(
                        //       context: context,
                        //       message: AppLocalizations.of(
                        //         context,
                        //       )!.redirecting_payment_methods,
                        //       duration: Duration(seconds: 1),
                        //       bottomMargin: 130,
                        //     );
                        //   },
                        // ),
                        _buildMenuTile(
                          icon: Icons.kitchen_outlined,
                          title: AppLocalizations.of(context)!.my_chillers,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyChillersPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuTile(
                          icon: Symbols.package_2,
                          title: AppLocalizations.of(context)!.order_history,
                          onTap: () {
                            HomeScreen.switchTabNotifier.value = 1;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      AppLocalizations.of(context)!.settings_section,
                      [
                        _buildMenuTile(
                          icon: Icons.notifications_outlined,
                          title: AppLocalizations.of(context)!.notifications,
                          badgeCount: _unreadNotificationsCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            ).then((_) {
                              _refreshProfile();
                            });
                          },
                        ),
                        _buildMenuTile(
                          icon: Icons.shield_outlined,
                          title: AppLocalizations.of(context)!.terms_conditions,
                          onTap: () {
                            CustomSnackbar.show(
                              context: context,
                              message: AppLocalizations.of(
                                context,
                              )!.redirecting_terms,
                              duration: Duration(seconds: 1),
                              bottomMargin: 130,
                            );
                          },
                        ),
                        _buildMenuTile(
                          icon: Icons.settings_outlined,
                          title: AppLocalizations.of(context)!.app_settings,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppSettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSection(AppLocalizations.of(context)!.support_section, [
                      // _buildMenuTile(
                      //   icon: Icons.help_outline,
                      //   title: AppLocalizations.of(context)!.help_center,
                      //   onTap: () {
                      //     CustomSnackbar.show(context: context, message: //           AppLocalizations.of(
                      //             context,
                      //           )!.feature_coming_soon,
                      //, duration: Duration(seconds: 1));
                      //   },
                      // ),
                      _buildMenuTile(
                        icon: Icons.phone_outlined,
                        title: AppLocalizations.of(context)!.contact_us,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuTile(
                        icon: Icons.star_outline_rounded,
                        title: AppLocalizations.of(context)!.customer_reviews,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerReviewsPage(),
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

                        child: Text(AppLocalizations.of(context)!.logout),
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
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Card(
      color: Colors.white,
      elevation: 2,
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
      elevation: 2,
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
                      begin: AlignmentDirectional.bottomEnd,
                      end: AlignmentDirectional.topStart,
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
            // const SizedBox(height: 16),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     _buildInfoCardItem(
            //       "24",
            //       AppLocalizations.of(context)!.donations_label,
            //     ),
            //     _buildInfoCardItem(
            //       "8",
            //       AppLocalizations.of(context)!.mosques_label,
            //     ),
            //     _buildInfoCardItem(
            //       "2.4K",
            //       AppLocalizations.of(context)!.people_label,
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _buildInfoCardItem(String value, String label) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 20,
  //           color: AppColors.buttonBlue,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  //     ],
  //   );
  // }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: InkWell(
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
                child: Transform.scale(
                  scaleX: isRtl(context) ? -1 : 1,
                  child: Badge(
                    isLabelVisible: badgeCount > 0,
                    label: Text('$badgeCount'),
                    child: Icon(
                      icon,
                      color: AppColors.buttonBlueDark,
                      size: 22,
                    ),
                  ),
                ),
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
              Transform.scale(
                scaleX: isRtl(context) ? -1 : 1,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[600],
                  size: 14,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
