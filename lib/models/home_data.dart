import 'banner_data.dart';
import 'campaign.dart';
import 'category.dart';
import 'product.dart';

class HomeData {
  final List<BannerData> banners;
  final List<Campaign> campaigns;
  final List<Category> categories;
  final List<Product> products;

  const HomeData({
    required this.banners,
    required this.campaigns,
    required this.categories,
    required this.products,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final rawBanners = json['banners'] as List<dynamic>?;
    final rawCampaigns = json['campaigns'] as List<dynamic>?;
    final rawCategories = json['categories'] as List<dynamic>?;
    final rawProducts = json['products'] as List<dynamic>?;

    return HomeData(
      banners: rawBanners
              ?.map((b) => BannerData.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      campaigns: rawCampaigns
              ?.map((c) => Campaign.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      categories: rawCategories
              ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      products: rawProducts
              ?.map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
