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

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = NotificationService.fetchNotifications();
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
                      child: Text(
                        context.tr('Lỗi tải thông báo'),
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];
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
                          await NotificationService.markAsRead(notif.id);
                          setState(() {
                            _notificationsFuture =
                                NotificationService.fetchNotifications();
                          });
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
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.border
                                  : AppColors.primary.withOpacity(0.3),
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
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
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
