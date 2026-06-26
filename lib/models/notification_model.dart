class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String category;
  final String? userId;
  final String? driverId;
  final String? adminId;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.userId,
    this.driverId,
    this.adminId,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? '',
      userId: json['userId'],
      driverId: json['driverId'],
      adminId: json['adminId'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'userId': userId,
      'driverId': driverId,
      'adminId': adminId,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
