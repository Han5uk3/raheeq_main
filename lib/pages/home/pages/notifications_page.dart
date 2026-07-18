import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/notification_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getNotifications();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        setState(() {
          _notifications = data
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await ApiService().readAllNotifications();
      if (response.statusCode == 200) {
        setState(() {
          for (var notification in _notifications) {
            notification.isRead = true;
          }
        });
        if (mounted) {
          final message =
              response.data['message'] ?? 'All notifications marked as read';
          CustomSnackbar.show(context: context, message: message);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.failed_to_mark_all_as_read,
          isError: true,
        );
      }
    }
  }

  Future<void> _readNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        final response = await ApiService().readNotification(notification.id);
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              final index = _notifications.indexWhere(
                (n) => n.id == notification.id,
              );
              if (index != -1) {
                _notifications[index] = NotificationModel(
                  id: notification.id,
                  title: notification.title,
                  body: notification.body,
                  category: notification.category,
                  userId: notification.userId,
                  driverId: notification.driverId,
                  adminId: notification.adminId,
                  data: notification.data,
                  isRead: true,
                  createdAt: notification.createdAt,
                );
              }
            });
          }
        }
      } catch (e) {
        // Fail silently
      }
    }

    if (notification.category == 'MARKETING') {
      return;
    }

    // Handle navigation based on data payload
    final data = notification.data;
    final type = data['type'];
    final orderId = data['orderid'] ?? data['orderId'] ?? data['order_id'];

    if (type?.toString().toLowerCase() == 'order_confirmed') {
      final subOrderId =
          data['subOrderId'] ?? data['suborderid'] ?? data['sub_order_id'];
      final targetOrderId = subOrderId ?? orderId;
      if (targetOrderId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BookingDetailsPage(orderId: targetOrderId.toString()),
          ),
        );
      }
    } else {
      if (mounted) {
        HomeScreen.switchTabNotifier.value = 1;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final response = await ApiService().clearAllNotifications();
      if (response.statusCode == 200) {
        setState(() {
          _notifications.clear();
        });
        if (mounted) {
          final message =
              response.data['message'] ??
              'All notifications cleared successfully';
          CustomSnackbar.show(context: context, message: message);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.failed_to_clear_notifications,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = AppLocalizations.of(context)!.notifications;
    final subtitle = AppLocalizations.of(context)!.latest_updates_and_alerts;

    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: subtitle,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
            actions: [
              PopupMenuButton<String>(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    _markAllAsRead();
                  } else if (value == 'clear_all') {
                    _clearAllNotifications();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Text(AppLocalizations.of(context)!.mark_all_read),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Text(
                      AppLocalizations.of(context)!.clear_notifications,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: RefreshIndicator(
                onRefresh: _fetchNotifications,
                color: AppColors.buttonBlueDark,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: constraints.maxHeight,
                      width: double.infinity,
                      color: AppColors.buttonBlueDark,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: <Widget>[
                                          ...previousChildren,
                                          if (currentChild != null)
                                            currentChild,
                                        ],
                                      );
                                    },

                                child: _buildContent(constraints.maxHeight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double minHeight) {
    if (_isLoading) {
      return ListView.separated(
        key: const ValueKey('loader'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 0, bottom: 40),
        itemCount: 10,
        separatorBuilder: (context, index) =>
            const Divider(color: Color(0xFFEAEFF2), height: 1),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
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
    }

    if (_errorMessage != null) {
      return Container(
        height: minHeight,
        alignment: Alignment.center,
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Container(
        height: minHeight,
        alignment: Alignment.center,
        key: const ValueKey('empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_on_outlined,
              size: 80,
              color: AppColors.headersubtitlecolor,
            ),
            Text(
              AppLocalizations.of(context)!.no_new_notifications,
              style: TextStyle(
                color: AppColors.headersubtitlecolor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('content'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 0, bottom: 40),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Color(0xFFEAEFF2), height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a', locale);
    final formattedDate = dateFormat.format(notification.createdAt.toLocal());

    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFF0F8FF),
      child: InkWell(
        onTap: () {
          log('Notification Full Data: ${notification.toJson()}');
          _readNotification(notification);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? const Color(0xFFF2F4F5)
                      : const Color(0xFFD9F0F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.buttonBlueDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (isAr && notification.titleAr != null)
                                ? notification.titleAr!
                                : notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (isAr && notification.bodyAr != null)
                          ? notification.bodyAr!
                          : notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.isRead
                            ? Colors.black54
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (notification.data['imageUrl'] != null &&
                  notification.data['imageUrl'].toString().isNotEmpty) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _readNotification(notification);
                    _showImageViewer(context, notification.data['imageUrl']);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      notification.data['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
