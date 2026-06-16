class ReviewsResponse {
  final bool success;
  final String message;
  final ReviewsData data;

  ReviewsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ReviewsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ReviewsData.fromJson(json['data'] ?? {}),
    );
  }
}

class ReviewsData {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final List<ReviewModel> items;

  ReviewsData({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.items,
  });

  factory ReviewsData.fromJson(Map<String, dynamic> json) {
    return ReviewsData(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReviewModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ReviewModel {
  final String id;
  final int rating;
  final String reviewText;
  final DateTime? createdAt;
  final ReviewUser? user;
  final ReviewProduct? product;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.reviewText,
    this.createdAt,
    this.user,
    this.product,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      rating: json['rating'] ?? 0,
      reviewText: json['reviewText'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      user: json['user'] != null ? ReviewUser.fromJson(json['user']) : null,
      product: json['product'] != null
          ? ReviewProduct.fromJson(json['product'])
          : null,
    );
  }
}

class ReviewUser {
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  ReviewUser({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class ReviewProduct {
  final String id;
  final String name;
  final String? nameAr;
  final String? image;

  ReviewProduct({
    required this.id,
    required this.name,
    this.nameAr,
    this.image,
  });

  factory ReviewProduct.fromJson(Map<String, dynamic> json) {
    return ReviewProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'],
      image: json['image'],
    );
  }

  String localizedName(bool isAr) {
    if (isAr && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }
}
