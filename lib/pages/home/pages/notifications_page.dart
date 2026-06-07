import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/notification_model.dart';
import 'package:intl/intl.dart';
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
          _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading notifications.';
        _isLoading = false;
      });
    }
  }

  Future<void> _readNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        final response = await ApiService().readNotification(notification.id);
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              final index = _notifications.indexWhere((n) => n.id == notification.id);
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

    // Handle navigation based on data payload
    if (notification.data.containsKey('orderId') && notification.data['orderId'] != null) {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        HomeScreen.switchTabNotifier.value = 1;
      }
    }
  }

  Future<void> _readAllNotifications() async {
    try {
      final response = await ApiService().readAllNotifications();
      if (response.statusCode == 200) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            final notification = _notifications[i];
            _notifications[i] = NotificationModel(
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
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final response = await ApiService().clearAllNotifications();
      if (response.statusCode == 200) {
        setState(() {
          _notifications.clear();
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = AppLocalizations.of(context)!.notifications;
    final subtitle = AppLocalizations.of(context)!.latest_updates_and_alerts;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: subtitle,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: const Color(0x4D91E3FE),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.buttonBlueDark),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
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
                  backgroundColor: AppColors.buttonBlue,
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
      return const Center(
        child: Text(
          "No new notifications",
          style: TextStyle(
            color: AppColors.headersubtitlecolor,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _readAllNotifications,
                child: const Text(
                  "Mark all as read",
                  style: TextStyle(color: AppColors.buttonBlueDark),
                ),
              ),
              TextButton(
                onPressed: _clearAllNotifications,
                child: const Text(
                  "Clear all",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchNotifications,
            color: AppColors.buttonBlue,
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 0, bottom: 40),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0xFFEAEFF2),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(notification.createdAt.toLocal());

    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFF0F8FF),
      child: InkWell(
        onTap: () {
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
                  color: notification.isRead ? const Color(0xFFF2F4F5) : const Color(0xFFD9F0F9),
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
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              color: Colors.black87,
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
                          )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.isRead ? Colors.black54 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
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
  }
}
