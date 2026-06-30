import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/chiller_model.dart';
import 'dart:developer';
import 'package:shimmer/shimmer.dart';

class MyChillersPage extends StatefulWidget {
  const MyChillersPage({super.key});

  @override
  State<MyChillersPage> createState() => _MyChillersPageState();
}

class _MyChillersPageState extends State<MyChillersPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ChillerModel> _chillers = [];

  @override
  void initState() {
    super.initState();
    _fetchChillers();
  }

  Future<void> _fetchChillers() async {
    try {
      final response = await _apiService.getMyChillers();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _chillers = data.map((e) => ChillerModel.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      log('Error fetching chillers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(width: 120, height: 12, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: AppLocalizations.of(context)!.my_chillers,
              subtitle: AppLocalizations.of(context)!.my_chillers_subtitle,
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Container(
              color: const Color(0x4D91E3FE),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
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
                      ? _buildShimmerLoading()
                      : _chillers.isEmpty
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Text(
                            AppLocalizations.of(context)!.no_chillers_found,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          key: const ValueKey('content'),
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          itemCount: _chillers.length,
                          itemBuilder: (context, index) {
                            final chiller = _chillers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildChillerItem(chiller),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChillerItem(ChillerModel chiller) {
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chiller.product?.image != null &&
              chiller.product!.image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                chiller.product!.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName.isNotEmpty ? productName : 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order: ${chiller.subOrderNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationName.isNotEmpty
                            ? locationName
                            : 'Unknown Location',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chiller.status == 'CONFIRMED'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chiller.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: chiller.status == 'CONFIRMED'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (chiller.isChillerAvailable)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
