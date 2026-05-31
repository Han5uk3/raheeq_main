import 'package:flutter/material.dart';
import 'package:raheeq_main/utils/colors.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                splashFactory: NoSplash.splashFactory,
                splashBorderRadius: BorderRadius.circular(25),
                isScrollable: false,
                dividerColor: Colors.transparent,
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
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    child: Center(
                      child: Text(
                        isAr ? 'طلبات جديدة' : 'New Orders',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Tab(
                    child: Center(
                      child: Text(
                        isAr ? 'جاري التوصيل' : 'Out for Delivery',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Tab(
                    child: Center(
                      child: Text(
                        isAr ? 'تم التوصيل' : 'Delivered',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                Center(
                  child: Text(
                    isAr ? 'لا توجد طلبات جديدة' : 'No new orders',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                Center(
                  child: Text(
                    isAr
                        ? 'لا توجد طلبات جاري توصيلها'
                        : 'No orders out for delivery',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                Center(
                  child: Text(
                    isAr ? 'لا توجد طلبات تم توصيلها' : 'No delivered orders',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
