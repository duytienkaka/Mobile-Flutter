import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/back_header.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';
import 'notification_service.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationItem>> _notificationsFuture;
  List<NotificationItem>? _notifications;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = NotificationService.fetchNotifications().then((
      list,
    ) {
      _notifications = list;
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MainFab(
        onPressed: () => _openScreen(context, const PantryScreen()),
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 4,
        onHome: () => _openScreen(context, const HomeScreen()),
        onRecipe: () => _openScreen(context, const RecipeScreen()),
        onShopping: () => _openScreen(context, const ShoppingScreen()),
        onNotifications: () => _openScreen(context, const NotificationScreen()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: BackHeader(title: context.tr('Thông báo')),
            ),
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('Lỗi tải thông báo'),
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Vui lòng thử lại.'),
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _notificationsFuture =
                                    NotificationService.fetchNotifications()
                                        .then((list) {
                                          _notifications = list;
                                          return list;
                                        });
                              });
                            },
                            child: Text(context.tr('Tải lại')),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = _notifications ?? snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr('Bạn không có thông báo'),
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 60),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return GestureDetector(
                        onTap: () async {
                          // Mark as read if not already read
                          if (!notif.isRead) {
                            try {
                              await NotificationService.markAsRead(notif.id);
                              setState(() {
                                final idx = _notifications?.indexWhere(
                                  (n) => n.id == notif.id,
                                );
                                if (idx != null && idx >= 0) {
                                  _notifications?[idx] = NotificationItem(
                                    id: notif.id,
                                    title: notif.title,
                                    body: notif.body,
                                    isRead: true,
                                    createdAt: notif.createdAt,
                                  );
                                }
                              });
                            } catch (e) {
                              debugPrint(
                                'Failed to mark notification as read: $e',
                              );
                            }
                          }

                          // Navigate to detail screen
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationDetailScreen(notification: notif),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? AppColors.surface
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.border
                                  : AppColors.primary,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontWeight: notif.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (!notif.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.danger,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _deleteNotification(notif.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif.body,
                                style: AppTextStyles.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(notif.createdAt),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotification(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Xóa thông báo')),
        content: Text(context.tr('Bạn có chắc muốn xóa thông báo này?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('Hủy')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.tr('Xóa')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.deleteNotification(id);
        setState(() {
          _notifications?.removeWhere((n) => n.id == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('Đã xóa thông báo')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('Không thể xóa thông báo: $e')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return context.tr('Vừa xong');
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}
