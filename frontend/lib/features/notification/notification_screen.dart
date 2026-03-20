import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';
import 'notification_detail_screen.dart';
import 'notification_service.dart';

enum _NotificationFilter { all, unread, food, planner }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationItem>> _notificationsFuture;
  List<NotificationItem>? _notifications;
  int _unreadCount = 0;
  bool _isMarkingAllRead = false;
  bool _isClearingAll = false;
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
    _fetchUnreadCount();
  }

  Future<List<NotificationItem>> _loadNotifications() async {
    final list = await NotificationService.fetchNotifications();
    _notifications = list;
    _updateUnreadCount(list);
    return list;
  }

  void _updateUnreadCount(List<NotificationItem> notifications) {
    final unread = notifications.where((n) => !n.isRead).length;
    if (!mounted) return;
    setState(() => _unreadCount = unread);
    NotificationBadgeService.instance.setUnreadCount(unread);
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await NotificationService.unreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
      NotificationBadgeService.instance.setUnreadCount(count);
    } catch (_) {}
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    setState(() => _notificationsFuture = _loadNotifications());
    await _notificationsFuture;
  }

  Future<void> _openDetail(NotificationItem notif) async {
    await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: NotificationDetailScreen(notification: notif),
          );
        },
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
      ),
    );

    await _refreshNotifications();
  }

  NotificationCategory _categoryOf(NotificationItem item) {
    return detectNotificationCategory(item);
  }

  bool _matchesFilter(NotificationItem item) {
    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return true;
      case _NotificationFilter.unread:
        return !item.isRead;
      case _NotificationFilter.food:
        final category = _categoryOf(item);
        return category == NotificationCategory.food ||
            category == NotificationCategory.pantry;
      case _NotificationFilter.planner:
        return _categoryOf(item) == NotificationCategory.planner;
    }
  }

  List<NotificationItem> _filteredNotifications(List<NotificationItem> items) {
    final filtered = items.where(_matchesFilter).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Map<String, List<NotificationItem>> _groupByDate(List<NotificationItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<NotificationItem>>{
      context.tr('Hôm nay'): [],
      context.tr('Hôm qua'): [],
      context.tr('Cũ hơn'): [],
    };

    for (final item in items) {
      final date = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      if (date == today) {
        grouped[context.tr('Hôm nay')]!.add(item);
      } else if (date == yesterday) {
        grouped[context.tr('Hôm qua')]!.add(item);
      } else {
        grouped[context.tr('Cũ hơn')]!.add(item);
      }
    }

    grouped.removeWhere((_, value) => value.isEmpty);
    return grouped;
  }

  Future<void> _markAsRead(NotificationItem notif) async {
    if (notif.isRead) return;

    try {
      await NotificationService.markAsRead(notif.id);
      final list = _notifications;
      if (list == null || !mounted) return;

      final index = list.indexWhere((n) => n.id == notif.id);
      if (index < 0) return;

      setState(() {
        list[index] = NotificationItem(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          isRead: true,
          createdAt: notif.createdAt,
          group: notif.group,
        );
      });
      _updateUnreadCount(list);
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        '${context.tr('Không thể đánh dấu đã đọc')}: $e',
        isError: true,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final list = _notifications;
    if (list == null || _isMarkingAllRead) return;

    final unread = list.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    setState(() => _isMarkingAllRead = true);
    try {
      for (final notif in unread) {
        await NotificationService.markAsRead(notif.id);
      }

      if (!mounted) return;
      setState(() {
        _notifications = [
          for (final notif in list)
            NotificationItem(
              id: notif.id,
              title: notif.title,
              body: notif.body,
              isRead: true,
              createdAt: notif.createdAt,
              group: notif.group,
            ),
        ];
      });
      _updateUnreadCount(_notifications ?? const []);
      showTopSnackBar(context, context.tr('Đã đánh dấu tất cả là đã đọc'));
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          context,
          '${context.tr('Không thể cập nhật thông báo')}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    final list = _notifications;
    if (list == null || list.isEmpty || _isClearingAll) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.tr('Xóa tất cả thông báo'),
      message: context.tr('Bạn có chắc muốn xóa toàn bộ thông báo?'),
      cancelText: context.tr('Hủy'),
      confirmText: context.tr('Xóa tất cả'),
      isDanger: true,
      icon: Icons.delete_sweep_outlined,
    );

    if (!confirmed) return;

    setState(() => _isClearingAll = true);
    try {
      await NotificationService.clearAllNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _unreadCount = 0;
      });
      NotificationBadgeService.instance.setUnreadCount(0);
      showTopSnackBar(context, context.tr('Đã xóa tất cả thông báo'));
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        '${context.tr('Xóa thông báo thất bại')}: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isClearingAll = false);
    }
  }

  Future<void> _deleteNotification(NotificationItem notif) async {
    try {
      await NotificationService.deleteNotification(notif.id);
      final list = _notifications;
      if (list == null || !mounted) return;

      setState(() {
        list.removeWhere((n) => n.id == notif.id);
      });
      _updateUnreadCount(list);
      showTopSnackBar(context, context.tr('Đã xóa thông báo'));
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        '${context.tr('Xóa thông báo thất bại')}: $e',
        isError: true,
      );
    }
  }

  IconData _iconForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.food:
        return Icons.warning_amber_rounded;
      case NotificationCategory.pantry:
        return Icons.inventory_2_outlined;
      case NotificationCategory.planner:
        return Icons.calendar_month_outlined;
      case NotificationCategory.system:
        return Icons.notifications_none_rounded;
    }
  }

  Color _toneForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.food:
        return const Color(0xFFB42318);
      case NotificationCategory.pantry:
        return AppColors.primary;
      case NotificationCategory.planner:
        return const Color(0xFF2563EB);
      case NotificationCategory.system:
        return AppColors.textMuted;
    }
  }

  String _labelForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.food:
        return context.tr('Thực phẩm');
      case NotificationCategory.pantry:
        return context.tr('Tủ đồ');
      case NotificationCategory.planner:
        return context.tr('Kế hoạch');
      case NotificationCategory.system:
        return context.tr('Hệ thống');
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return context.tr('Vừa xong');
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${context.tr('phút trước')}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${context.tr('giờ trước')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${context.tr('ngày trước')}';
    }
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  Widget _buildFilterChip({
    required _NotificationFilter value,
    required String label,
    required int count,
  }) {
    final selected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                  ? Colors.white.withValues(alpha: 0.22)
                  : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notif) {
    final category = _categoryOf(notif);
    final tone = _toneForCategory(category);

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: context.tr('Xóa thông báo'),
          message: context.tr('Bạn có chắc muốn xóa thông báo này?'),
          cancelText: context.tr('Hủy'),
          confirmText: context.tr('Xóa'),
          isDanger: true,
          icon: Icons.delete_outline_rounded,
        );
        return confirmed;
      },
      onDismissed: (_) => _deleteNotification(notif),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await _markAsRead(notif);
          if (!mounted) return;
          await _openDetail(notif);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? AppColors.surface : const Color(0xFFF5F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead ? AppColors.border : AppColors.primary,
              width: notif.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForCategory(category), color: tone, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: notif.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          notif.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: notif.isRead
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _labelForCategory(category),
                      style: AppTextStyles.caption.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatTime(notif.createdAt),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: notif.isRead ? null : () => _markAsRead(notif),
                    icon: const Icon(Icons.done_rounded, size: 16),
                    label: Text(context.tr('Đã đọc')),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await _markAsRead(notif);
                      if (!mounted) return;
                      await _openDetail(notif);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(context.tr('Chi tiết')),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(List<NotificationItem> notifications) {
    final filtered = _filteredNotifications(notifications);

    if (filtered.isEmpty) {
      return EmptyState(
        title: context.tr('Không có thông báo phù hợp'),
        message: context.tr('Thử đổi bộ lọc để xem thêm thông báo.'),
        icon: Icons.tune_rounded,
      );
    }

    final groups = _groupByDate(filtered);

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
              child: Text(
                entry.key,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...entry.value.map(_buildNotificationCard),
          ],
        ],
      ),
    );
  }

  int _countFor(_NotificationFilter filter, List<NotificationItem> list) {
    switch (filter) {
      case _NotificationFilter.all:
        return list.length;
      case _NotificationFilter.unread:
        return list.where((n) => !n.isRead).length;
      case _NotificationFilter.food:
        return list
            .where((item) {
              final category = _categoryOf(item);
              return category == NotificationCategory.food ||
                  category == NotificationCategory.pantry;
            })
            .length;
      case _NotificationFilter.planner:
        return list
            .where((item) => _categoryOf(item) == NotificationCategory.planner)
            .length;
    }
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
        unreadNotificationCount: _unreadCount,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: BackHeader(title: context.tr('Thông báo')),
            ),
            FutureBuilder<List<NotificationItem>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                final all = _notifications ?? snapshot.data ?? <NotificationItem>[];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF8EE), Color(0xFFF4FAFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Bạn có $_unreadCount thông báo chưa đọc'),
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _isMarkingAllRead || _unreadCount == 0
                              ? null
                              : _markAllAsRead,
                          style: TextButton.styleFrom(
                            backgroundColor: _isMarkingAllRead || _unreadCount == 0
                                ? AppColors.surfaceSoft
                                : AppColors.primary,
                            foregroundColor: _isMarkingAllRead || _unreadCount == 0
                                ? AppColors.textMuted
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isMarkingAllRead
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(context.tr('Đọc hết')),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isClearingAll || all.isEmpty
                              ? null
                              : _clearAllNotifications,
                          style: TextButton.styleFrom(
                            backgroundColor: _isClearingAll || all.isEmpty
                                ? AppColors.surfaceSoft
                                : AppColors.danger,
                            foregroundColor: _isClearingAll || all.isEmpty
                                ? AppColors.textMuted
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isClearingAll
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(context.tr('Xóa hết')),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            FutureBuilder<List<NotificationItem>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                final all = _notifications ?? snapshot.data ?? <NotificationItem>[];
                return SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        value: _NotificationFilter.all,
                        label: context.tr('Tất cả'),
                        count: _countFor(_NotificationFilter.all, all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        value: _NotificationFilter.unread,
                        label: context.tr('Chưa đọc'),
                        count: _countFor(_NotificationFilter.unread, all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        value: _NotificationFilter.food,
                        label: context.tr('Thực phẩm'),
                        count: _countFor(_NotificationFilter.food, all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        value: _NotificationFilter.planner,
                        label: context.tr('Kế hoạch'),
                        count: _countFor(_NotificationFilter.planner, all),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _notifications == null) {
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
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refreshNotifications,
                            child: Text(context.tr('Tải lại')),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications =
                      _notifications ?? snapshot.data ?? <NotificationItem>[];

                  if (notifications.isEmpty) {
                    return EmptyState(
                      title: context.tr('Chưa có thông báo'),
                      message: context.tr(
                        'Khi có cập nhật mới, thông báo sẽ xuất hiện tại đây.',
                      ),
                      icon: Icons.notifications_none,
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      );
                      final slide = Tween<Offset>(
                        begin: const Offset(0.015, 0),
                        end: Offset.zero,
                      ).animate(fade);
                      return FadeTransition(
                        opacity: fade,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${_selectedFilter.name}-${notifications.length}-$_unreadCount',
                      ),
                      child: _buildLoadedState(notifications),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}
