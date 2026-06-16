import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/impact.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class ImpactPage extends StatefulWidget {
  const ImpactPage({super.key});

  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage> {
  bool _isLoading = true;
  ImpactModel? _impactData;

  @override
  void initState() {
    super.initState();
    _fetchImpact();
  }

  Future<void> _fetchImpact() async {
    try {
      final response = await ApiService().getImpact();
      if (response.data['success'] == true) {
        setState(() {
          _impactData = ImpactModel.fromJson(response.data['data']);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load impact");
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.error_loading_impact,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.buttonBlue, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecentDonations(bool isAr) {
    if (_impactData == null || _impactData!.productsBreakup.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.recent_donations,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.buttonBlueDark,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.view_all,
              style: const TextStyle(fontSize: 14, color: AppColors.buttonBlue),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._impactData!.productsBreakup.map((product) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.water_drop,
                        color: AppColors.buttonBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.localizedName(isAr),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonBlueDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${product.totalQuantity} ${AppLocalizations.of(context)!.items_donated}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.delivered,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: AppLocalizations.of(context)!.your_impact,
              subtitle: AppLocalizations.of(context)!.see_the_difference,
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              color: const Color(0x4D91E3FE),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: _isLoading
                    ? const Center(child: WaterLoadingIndicator())
                    : _impactData == null
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.no_impact_data_found,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1.1,
                                      child: _buildStatCard(
                                        icon: Icons.water_drop_outlined,
                                        value: "${_impactData!.totalOrders}",
                                        label: AppLocalizations.of(
                                          context,
                                        )!.total_donations,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1.1,
                                      child: _buildStatCard(
                                        icon: Icons.people_outline,
                                        value: "${_impactData!.totalProducts}",
                                        label: AppLocalizations.of(
                                          context,
                                        )!.products_donated,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1.1,
                                      child: _buildStatCard(
                                        icon: Icons.inventory_2_outlined,
                                        value:
                                            "${AppLocalizations.of(context)!.sar} ${_impactData!.totalAmountPaid.toInt()}",
                                        label: AppLocalizations.of(
                                          context,
                                        )!.total_given,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1.1,
                                      child: _buildStatCard(
                                        icon: Icons.trending_up,
                                        value:
                                            "${_impactData!.totalMosques.toString().padLeft(2, '0')}",
                                        label: AppLocalizations.of(
                                          context,
                                        )!.mosques_helped,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          /*Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A6A8F), Color(0xFF91E3FE)],
                                begin: AlignmentDirectional.centerStart,
                                end: AlignmentDirectional.centerEnd,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "12 Days",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.current_donation_streak,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),*/
                          _buildRecentDonations(isAr),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
