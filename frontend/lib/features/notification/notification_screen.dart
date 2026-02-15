import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/header_bar.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';
import 'notification_service.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
        unreadCount: Provider.of<NotificationService>(
          context,
        ).items.where((e) => !e.read).length,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Builder(
                builder: (context) {
                  final svc = Provider.of<NotificationService>(
                    context,
                    listen: false,
                  );
                  return HeaderBar(
                    title: context.tr('Thông báo'),
                    actionIcon: Icons.send,
                    onAction: () async {
                      final ok = await svc.sendTestToServer(
                        title: 'Thông báo từ app',
                        body: 'Gửi từ client',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Gửi thành công' : 'Gửi thất bại'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<NotificationService>(
      builder: (context, svc, _) {
        final items = svc.items;
        if (items.isEmpty) {
          return EmptyState(
            title: 'Không có thông báo',
            message: 'Bạn hiện chưa có thông báo nào.',
            icon: Icons.notifications_off,
            actionLabel: 'Làm mới',
            onAction: () => svc.add(
              NotificationItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Thông báo mới',
                body: 'Đây là thông báo mẫu',
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final it = items[index];
            return ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationDetailScreen(item: it),
                  ),
                );
                Provider.of<NotificationService>(
                  context,
                  listen: false,
                ).markAsRead(it.id);
              },
              leading: CircleAvatar(
                backgroundColor: it.read
                    ? Colors.grey.shade200
                    : AppColors.primary,
                child: Icon(
                  Icons.notifications,
                  color: it.read ? Colors.black54 : Colors.white,
                ),
              ),
              title: Text(
                it.title,
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: it.read ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                it.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _timeAgo(it.createdAt),
                style: AppTextStyles.caption,
              ),
            );
          },
        );
      },
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}
