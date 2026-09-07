import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/chiller_model.dart';
import 'package:raheeq_main/models/mosque.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/widgets/order_chiller_sheet.dart';
import 'package:raheeq_main/pages/order/choose_water_package_screen.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:shimmer/shimmer.dart';

class ChillerDetailsPage extends StatelessWidget {
  final ChillerModel chiller;

  const ChillerDetailsPage({super.key, required this.chiller});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final productName = isArabic
        ? (chiller.product?.nameAr.isNotEmpty == true
              ? chiller.product!.nameAr
              : chiller.product?.name ?? '')
        : (chiller.product?.name.isNotEmpty == true
              ? chiller.product!.name
              : chiller.product?.nameAr ?? '');
            
    final locationName = isArabic
        ? (chiller.deliveredLocation?.nameAr.isNotEmpty == true
              ? chiller.deliveredLocation!.nameAr
              : chiller.deliveredLocation?.name ?? '')
        : (chiller.deliveredLocation?.name.isNotEmpty == true
              ? chiller.deliveredLocation!.name
              : chiller.deliveredLocation?.nameAr ?? '');

    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: AppLocalizations.of(context)!.chiller_info,
            subtitle: "",
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Container(
                width: double.infinity,
                color: AppColors.buttonBlueDark,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Section
                        _buildSectionCard(
                          context,
                          child: Row(
                            children: [
                              if (chiller.product?.image != null &&
                                  chiller.product!.image.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: chiller.product!.image,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.white,
                                          ),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  ),
                                )
                              else
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  productName.isNotEmpty
                                      ? productName
                                      : AppLocalizations.of(
                                          context,
                                        )!.unknown_product,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Order Details Section
                        _buildSectionCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                '${AppLocalizations.of(context)!.order_number}:',
                                chiller.subOrderNumber,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                '${AppLocalizations.of(context)!.status}:',
                                _getLocalizedStatusText(
                                  context,
                                  chiller.status,
                                ),
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                '${AppLocalizations.of(context)!.delivered_at}:',
                                chiller.deliveredAt != null
                                    ? chiller.deliveredAt!.toString().substring(
                                        0,
                                        10,
                                      )
                                    : AppLocalizations.of(
                                        context,
                                      )!.not_available,
                              ),
                              // Refill history only appears once there is one
                              // — an empty count says nothing worth a row.
                              if (chiller.refillCount > 0) ...[
                                const Divider(height: 24),
                                _buildInfoRow(
                                  '${AppLocalizations.of(context)!.refills}:',
                                  '${chiller.refillCount}',
                                ),
                              ],
                              if (chiller.lastRefilledDate != null) ...[
                                const Divider(height: 24),
                                _buildInfoRow(
                                  '${AppLocalizations.of(context)!.last_refilled}:',
                                  chiller.lastRefilledDate!
                                      .toString()
                                      .substring(0, 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location Details Section
                        _buildSectionCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                              
                                children: [
                                  Expanded(
                                    child: _buildInfoRow(
                                      '${AppLocalizations.of(context)!.location}:',
                                      locationName.isNotEmpty
                                          ? locationName
                                          : AppLocalizations.of(
                                              context,
                                            )!.unknown_location,
                                    ),
                                  ),
                              
                             
                                
                                ],
                              ),
                              const Divider(height: 24),

                              if (chiller.deliveredLocation?.address != null &&
                                  chiller
                                      .deliveredLocation!
                                      .address
                                      .isNotEmpty) ...[
                        
                                _buildInfoRow(
                                  '${AppLocalizations.of(context)!.address}:',
                                  chiller.deliveredLocation!.address,
                                ),
                              ],
                            ],
                          ),
                          
                        ),
                        const SizedBox(height: 32),

                        // Refills only go to a chiller that has actually been
                        // delivered and is still accepting them; the checkout
                        // rejects anything else.
                        if (chiller.canRefill) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBlueDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                final category = HomeTab.cachedCategories
                                    .firstWhere(
                                      (c) =>
                                          c.slug ==
                                          chiller.deliveredLocation?.type,
                                      orElse: () =>
                                          HomeTab.cachedCategories.firstWhere(
                                            (c) =>
                                                c.slug == 'mosques', // fallback
                                            orElse: () =>
                                                HomeTab.cachedCategories.first,
                                          ),
                                    );

                                final specificPlace = Mosque(
                                  id: chiller.deliveredLocation?.id ?? '',
                                  name: chiller.deliveredLocation?.name ?? '',
                                  nameAr:
                                      chiller.deliveredLocation?.nameAr ?? '',
                                  beneficiaryCount: 0,
                                  latitude:
                                      chiller.deliveredLocation?.latitude ??
                                      0.0,
                                  longitude:
                                      chiller.deliveredLocation?.longitude ??
                                      0.0,
                                  address:
                                      chiller.deliveredLocation?.address ?? '',
                                  image: '',
                                  zone: null,
                                  isActive: true,
                                );

                                final selectedCategoryItem =
                                    SelectedCategoryItem(
                                      category: category,
                                      optionType: 'specific',
                                      specificData: specificPlace,
                                    );

                                final waterCartons = HomeTab.cachedProducts
                                    .where(
                                      (p) =>
                                          p.serialNumber == 1 ||
                                          p.serialNumber == 4,
                                    )
                                    .toList();

                                // The chiller's own sub-order id: it makes this
                                // a refill, so the backend links the order to
                                // this chiller and locks delivery to its
                                // location.
                                ChooseWaterPackageScreen.showAsBottomSheet(
                                  context,
                                  selectedCategories: [selectedCategoryItem],
                                  availableProducts: waterCartons,
                                  chillerRefillSubOrderId: chiller.id,
                                );
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.order_water_to_this_chiller,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.buttonBlueDark,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => OrderChillerSheet.start(context),
                            child: Text(
                              AppLocalizations.of(context)!.order_new_chiller,
                              style: const TextStyle(
                                color: AppColors.buttonBlueDark,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedStatusText(BuildContext context, String status) {
    final stat = status.toLowerCase();
    if (stat == "confirmed") {
      return AppLocalizations.of(context)!.confirmed;
    } else if (stat == "delivered") {
      return AppLocalizations.of(context)!.delivered;
    } else {
      return status;
    }
  }

  Widget _buildSectionCard(
    BuildContext context, {
    String? title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
