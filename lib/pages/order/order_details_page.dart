import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/models/city.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/services/network_monitor.dart';
import 'package:raheeq_main/services/snackbar_insets_services.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'dart:developer';
import 'package:raheeq_main/common_widgets/donation_type_bottom_sheet.dart';
import 'package:raheeq_main/common_widgets/subscription_plans_bottom_sheet.dart';
import 'package:raheeq_main/common_widgets/subscription_details_bottom_sheet.dart';
import 'package:raheeq_main/models/subscription_plan.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class ReviewOrderPage extends StatefulWidget {
  final List<OrderCategoryState> orderStates;

  const ReviewOrderPage({super.key, required this.orderStates});

  @override
  State<ReviewOrderPage> createState() => _ReviewOrderPageState();
}

class _ReviewOrderPageState extends State<ReviewOrderPage>
    with SingleTickerProviderStateMixin {
  late List<Product> _uniqueProducts;
  bool _isProcessing = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    SnackbarInsets.setBottomInset(kBottomNavigationBarHeight);
    final productMap = <String, Product>{};
    for (final state in widget.orderStates) {
      for (final sp in state.selectedProducts) {
        productMap[sp.product.id] = sp.product;
      }
    }
    _uniqueProducts = productMap.values.toList();

    if (_uniqueProducts.isNotEmpty) {
      _tabController = TabController(
        length: _uniqueProducts.length,
        vsync: this,
      );
      // Rebuild the page whenever the selected tab changes so the
      // (non-lazy) content below the TabBar reflects the new tab.
      _tabController!.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    SnackbarInsets.clear();

    _tabController?.dispose();
    super.dispose();
  }

  double get _totalPrice {
    return widget.orderStates.fold(0, (sum, state) => sum + state.totalPrice);
  }

  void _showDonationTypeDialog(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DonationTypeBottomSheet(
        onOneTimeSelected: () => _processOneTimeCheckout(context, isAr),
        onMonthlySelected: () =>
            _showSubscriptionPlansBottomSheet(context, isAr),
      ),
    );
  }

  void _showSubscriptionPlansBottomSheet(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionPlansBottomSheet(
        onPlanSelected: (plan) {
          _showSubscriptionDetailsBottomSheet(context, plan, isAr);
        },
        onBack: () {
          _showDonationTypeDialog(context, isAr);
        },
      ),
    );
  }

  void _showSubscriptionDetailsBottomSheet(
    BuildContext context,
    SubscriptionPlan plan,
    bool isAr,
  ) {
    final items = _prepareCheckoutItems();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionDetailsBottomSheet(
        plan: plan,
        checkoutItems: items,
        orderStates: widget.orderStates,
        onBack: () {
          _showSubscriptionPlansBottomSheet(context, isAr);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _prepareCheckoutItems() {
    final List<Map<String, dynamic>> items = [];
    for (final state in widget.orderStates) {
      final category = state.categoryItem.category;
      for (final sp in state.selectedProducts) {
        final item = <String, dynamic>{
          'productId': sp.product.id,
          'quantity': sp.quantity,
        };
        if (sp.notes != null && sp.notes!.trim().isNotEmpty) {
          item['note'] = sp.notes!.trim();
        }
        final optionType = state.categoryItem.optionType;
        final slug = category.slug;
        if (optionType == 'specific') {
          final specificData = state.categoryItem.specificData;
          if (specificData is Place) {
            item['locationId'] = specificData.id;
          } else if (specificData is City) {
            item['cityId'] = specificData.id;
          }
        } else {
          final specificData = state.categoryItem.specificData;
          if (optionType == 'most_in_need' && specificData is City) {
            item['cityId'] = specificData.id;
          } else if (slug == 'essential_supplies' &&
              optionType == 'most_in_need') {
            item['categorySlug'] = 'mosques_in_need';
          } else {
            item['categorySlug'] = slug;
          }
        }
        items.add(item);
      }
    }
    return items;
  }

  Future<void> _processOneTimeCheckout(BuildContext context, bool isAr) async {
    final items = _prepareCheckoutItems();

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiService();
      final isEssential = widget.orderStates.any(
        (state) => state.categoryItem.category.slug == 'essential_supplies',
      );
      final response = isEssential
          ? await apiService.createCheckoutEssential(items: items)
          : await apiService.createCheckoutQuick(items: items);
      log('createCheckout response: ${response.data}');

      final checkoutDataMap = response.data['data'];
      final checkoutData = Checkout.fromJson(checkoutDataMap);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _navigateToDetails(
          context,
          AppLocalizations.of(context)!.one_time_donation,
          checkoutData: checkoutData,
        );
      }
    } catch (e) {
      log('Error creating checkout: $e', error: e);
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        String errorMessage = AppLocalizations.of(
          context,
        )!.error_occurred_try_again;
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
    }
  }

  void _navigateToDetails(
    BuildContext context,
    String donationType, {
    required Checkout checkoutData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContributionDetailsPage(
          orderStates: widget.orderStates,
          donationType: donationType,
          checkoutData: checkoutData,
        ),
      ),
    );
  }

  /// Builds the cards for a single product as a plain (non-scrolling)
  /// Column, so its height is exactly the sum of its children — no
  /// leftover space when there's only one or two cards.
  Widget _buildProductTabContent(Product product, bool isAr) {
    final relevantStates = widget.orderStates.where((state) {
      return state.selectedProducts.any((sp) => sp.product.id == product.id);
    }).toList();

    return Column(
      children: [
        for (int index = 0; index < relevantStates.length; index++) ...[
          if (index > 0) const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final state = relevantStates[index];
              final category = state.categoryItem.category;
              final sp = state.selectedProducts.firstWhere(
                (p) => p.product.id == product.id,
              );

              final slug = category.slug;
              final optionType = state.categoryItem.optionType;
              String originalCategoryLabel = category.localizedLabel(isAr);
              String categoryLabel = originalCategoryLabel;
              String locationText = "";

              if (optionType == 'specific') {
                final specificData = state.categoryItem.specificData;
                if (specificData is Place) {
                  categoryLabel = specificData.localizedName(isAr);
                  locationText = specificData.address;
                } else {
                  categoryLabel = specificData?.localizedName(isAr) ?? "";
                  locationText = "";
                }
              } else if (optionType == 'most_in_need') {
                if (slug == 'orphanages') {
                  locationText = AppLocalizations.of(
                    context,
                  )!.most_needy_orphanage;
                } else if (slug == 'meqat_mosques') {
                  locationText = AppLocalizations.of(
                    context,
                  )!.most_needy_meqat_mosque;
                } else if (slug == 'mosques_in_need') {
                  final specificData = state.categoryItem.specificData;
                  if (specificData != null) {
                    // Can be a City object or a String depending on where it was selected
                    if (specificData is City) {
                      categoryLabel = specificData.localizedName(isAr);
                    } else if (specificData is String) {
                      categoryLabel = specificData;
                    } else {
                      try {
                        categoryLabel = specificData.localizedName(isAr);
                      } catch (_) {}
                    }
                  }
                  locationText = "";
                } else {
                  locationText = AppLocalizations.of(context)!.most_in_need;
                }
              } else if (slug == 'remote_mosques' || slug == 'cemeteries') {
                locationText = "";
              } else {
                locationText = AppLocalizations.of(context)!.general;
              }

              // If the title of the card was changed to something specific (like a mosque name or city name),
              // show the original category name where the location would normally be shown.
              if (categoryLabel != originalCategoryLabel) {
                locationText = originalCategoryLabel;
              }

              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                                if (locationText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    locationText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Divider(),
                      SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${AppLocalizations.of(context)!.choose_quantity} (${product.localizedName(isAr)})",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: sp.quantity > sp.product.minQuantity
                                      ? 1.0
                                      : 0.45,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (sp.quantity >
                                          sp.product.minQuantity) {
                                        setState(() {
                                          sp.quantity -= 1;
                                        });
                                      } else {
                                        CustomSnackbar.show(
                                          context: context,
                                          message: AppLocalizations.of(context)!
                                              .minimum_quantity_for_location_is(
                                                sp.product.minQuantity
                                                    .toString(),
                                              ),
                                          isError: true,
                                          bottomMargin: 120,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            sp.quantity > sp.product.minQuantity
                                            ? AppColors.buttonBlueDark
                                            : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${sp.quantity}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      sp.quantity += 1;
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonBlueDark,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        cursorColor: AppColors.buttonBlueDark,
                        initialValue: sp.notes,
                        maxLines: 3,
                        onChanged: (val) {
                          sp.notes = val;
                        },
                        scrollPadding: EdgeInsets.only(bottom: 70),
                        style: TextStyle(
                          color: AppColors.buttonBlueDark,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.would_you_like_to_add_a_note_to_the_delivery_agent,
                          hintStyle: TextStyle(
                            color: AppColors.buttonBlueDark.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonBlueDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.order_details;
    final subtitle = AppLocalizations.of(context)!.verify_your_order_details;

    if (_uniqueProducts.isEmpty || _tabController == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CustomAppBar(
                hasBackgroundColor: true,
                isStartAligned: true,
                title: title,
                subtitle: subtitle,
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(AppLocalizations.of(context)!.no_products_selected),
              ),
            ),
          ],
        ),
      );
    }

    final currentProduct = _uniqueProducts[_tabController!.index];

    return IgnorePointer(
      ignoring: _isProcessing,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBody: true,
        backgroundColor: AppColors.white,
        bottomNavigationBar: Padding(
          padding: EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
          child: BottomActionPill(
            isLoading: _isProcessing,
            subtitleWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.total_price,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            titleWidget: Text(
              "\u202A${AppLocalizations.of(context)!.sar_currency} ${_totalPrice.toStringAsFixed(2)}\u202C",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            buttonText: AppLocalizations.of(context)!.continue_btn,
            onButtonTap: () {
              if (NetworkMonitor.instance.status == NetworkStatus.offline) {
                CustomSnackbar.show(
                  context: context,
                  message: AppLocalizations.of(context)!.internet_error,
                  isError: true,
                );
                return;
              }
              FocusManager.instance.primaryFocus?.unfocus();
              final hasChiller = _uniqueProducts.any(
                (p) => p.serialNumber == 2,
              );
              if (hasChiller) {
                _processOneTimeCheckout(context, isAr);
              } else {
                _showDonationTypeDialog(context, isAr);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomAppBar(
                hasBackgroundColor: true,
                isStartAligned: true,
                title: title,
                subtitle: subtitle,
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
              Stack(
                children: [
                  Container(height: 50, color: AppColors.buttonBlueDark),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AspectRatio(
                            aspectRatio: 790 / 418,
                            child: Material(
                              elevation: 1,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              color: Colors.white,
                              child: Image.asset(
                                "assets/static_banners/details_banner.jpeg",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E9EC),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                splashBorderRadius: BorderRadius.circular(25),
                                isScrollable: _uniqueProducts.length > 3,
                                dividerColor: Colors.transparent,
                                dividerHeight: 0,
                                labelColor: Colors.white,
                                unselectedLabelColor: AppColors.buttonBlueDark,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: AppColors.buttonBlueDark,
                                ),
                                labelPadding: EdgeInsets.zero,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                tabs: _uniqueProducts
                                    .map(
                                      (p) => Tab(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                          ),
                                          child: Text(
                                            p.localizedName(isAr),
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildProductTabContent(currentProduct, isAr),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 ? 50 : 140,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

