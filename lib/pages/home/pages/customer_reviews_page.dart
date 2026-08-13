import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/review_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:raheeq_main/utils/formatters.dart';

class CustomerReviewsPage extends StatefulWidget {
  const CustomerReviewsPage({super.key});

  @override
  State<CustomerReviewsPage> createState() => _CustomerReviewsPageState();
}

class _CustomerReviewsPageState extends State<CustomerReviewsPage> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final response = await ApiService().getCustomerReviews();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final reviewsResponse = ReviewsResponse.fromJson(response.data);
        if (mounted) {
          setState(() {
            _reviews = reviewsResponse.data.items;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load reviews");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = AppLocalizations.of(context)!.error;
        if (e.toString().contains("connection error")) {
          errorMessage = AppLocalizations.of(context)!.internet_error;
        } else if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        } else {
          errorMessage = AppLocalizations.of(context)!.error;
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review, bool isAr) {
    final userName =
        review.user?.fullName ?? AppLocalizations.of(context)!.user;
    final avatarUrl = review.user?.avatarUrl;
    final productName = review.product?.localizedName(isAr) ?? '';
    final productImage = review.product?.image;
    final dateStr = review.createdAt != null
        ? Formatters.formatDate(context, review.createdAt!)
        : '';

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.headerlightblue,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonBlueDark,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.reviewText,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (productName.isNotEmpty || productImage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (productImage != null && productImage.isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: productImage,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.water_drop,
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonBlueDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.customer_reviews;

    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Container(
                color: AppColors.buttonBlueDark,
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
                        : _reviews.isEmpty
                        ? Center(
                            key: const ValueKey('empty'),
                            child: Text(
                              AppLocalizations.of(context)!.no_reviews_found,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            key: const ValueKey('content'),
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              return _buildReviewCard(
                                context,
                                _reviews[index],
                                isAr,
                              );
                            },
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
          return Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 60,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(width: 200, height: 14, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
