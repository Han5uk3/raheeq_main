import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/impact.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/utils/formatters.dart';

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
        String errorMessage = AppLocalizations.of(
          context,
        )!.error_loading_impact;
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
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
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsOverview(bool isAr) {
    if (_impactData == null || _impactData!.productsBreakup.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.products_overview,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._impactData!.productsBreakup.map((product) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              elevation: 2,
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                            color: AppColors.buttonBlueDark,
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
                              color: AppColors.black,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 3; i++) ...[
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: AppLocalizations.of(context)!.donations_overview,
              subtitle: AppLocalizations.of(context)!.see_the_difference,
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark,

                border: Border.all(width: 1, color: AppColors.buttonBlueDark),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
                  child: _isLoading
                      ? _buildShimmerLoader()
                      : _impactData == null
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Text(
                            AppLocalizations.of(context)!.no_impact_data_found,
                          ),
                        )
                      : Column(
                          key: const ValueKey('content'),
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
                                          icon:
                                              Icons.volunteer_activism_outlined,
                                          value: Formatters.formatCount(
                                            _impactData!.totalOrders,
                                          ),
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
                                          icon: Icons.local_shipping_outlined,
                                          value: Formatters.formatCount(
                                            _impactData!.totalProducts,
                                          ),
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
                                      child: Builder(
                                        builder: (context) {
                                          int totalCartons = 0;
                                          for (final breakup
                                              in _impactData!.productsBreakup) {
                                            final nameLower = breakup.name
                                                .toLowerCase();
                                            final nameAr = breakup.nameAr;
                                            if (nameLower.contains('carton') ||
                                                nameAr.contains('كرتون')) {
                                              totalCartons +=
                                                  breakup.totalQuantity;
                                            }
                                          }
                                          return AspectRatio(
                                            aspectRatio: 1.1,
                                            child: _buildStatCard(
                                              icon: Icons.people_outline,
                                              value: Formatters.formatCount(
                                                totalCartons * 20,
                                              ),
                                              label: AppLocalizations.of(
                                                context,
                                              )!.people_helped,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 1.1,
                                        child: _buildStatCard(
                                          icon: Icons.mosque_outlined,
                                          value: Formatters.formatCount(
                                            _impactData!.totalMosques,
                                          ),
                                          label: AppLocalizations.of(
                                            context,
                                          )!.mosques_helped,
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
                                          icon: Icons.account_balance_outlined,
                                          value:
                                              "\u202A${AppLocalizations.of(context)!.sar} ${Formatters.formatCount(_impactData!.totalAmountPaid)}\u202C",
                                          label: AppLocalizations.of(
                                            context,
                                          )!.total_amount,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 1.1,
                                        child: _buildStatCard(
                                          icon: Icons.house_outlined,
                                          value: Formatters.formatCount(
                                            _impactData!.totalOrphanages,
                                          ),
                                          label: AppLocalizations.of(
                                            context,
                                          )!.orphanages_helped,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            _buildProductsOverview(isAr),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
