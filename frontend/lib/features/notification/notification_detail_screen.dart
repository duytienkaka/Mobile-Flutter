import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialogs.dart';
import 'notification_service.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late NotificationItem _notification;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (_notification.isRead) return;

    try {
      await NotificationService.markAsRead(_notification.id);
      if (!mounted) return;
      setState(() {
        _notification = NotificationItem(
          id: _notification.id,
          title: _notification.title,
          body: _notification.body,
          isRead: true,
          createdAt: _notification.createdAt,
          group: _notification.group,
        );
      });
    } catch (_) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        context.tr('Lỗi cập nhật thông báo'),
        isError: true,
      );
    }
  }

  Future<void> _deleteNotification() async {
    if (_isDeleting) return;

    final confirm = await showAppConfirmDialog(
      context: context,
      title: context.tr('Xóa thông báo'),
      message: context.tr('Bạn có chắc muốn xóa thông báo này?'),
      cancelText: context.tr('Hủy'),
      confirmText: context.tr('Xóa'),
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirm) return;

    setState(() => _isDeleting = true);
    try {
      await NotificationService.deleteNotification(_notification.id);
      if (!mounted) return;
      showTopSnackBar(context, context.tr('Đã xóa thông báo'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        '${context.tr('Xóa thông báo thất bại')}: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  NotificationCategory _categoryOf(NotificationItem item) {
    return detectNotificationCategory(item);
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return context.tr('Vừa xong');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${context.tr('phút trước')}';
    if (diff.inHours < 24) return '${diff.inHours} ${context.tr('giờ trước')}';
    if (diff.inDays < 7) return '${diff.inDays} ${context.tr('ngày trước')}';
    return _formatDateTime(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final category = _categoryOf(_notification);
    final tone = _toneForCategory(category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('Chi tiết thông báo'),
          style: AppTextStyles.subtitle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 18),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_iconForCategory(category), color: tone),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _notification.title,
                              style: AppTextStyles.subtitle.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _notification.isRead
                                        ? AppColors.border
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _notification.isRead
                                        ? context.tr('Đã đọc')
                                        : context.tr('Chưa đọc'),
                                    style: AppTextStyles.caption.copyWith(
                                      color: _notification.isRead
                                          ? AppColors.textPrimary
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatTimeAgo(_notification.createdAt),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 22),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
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
                      Text(
                        context.tr('Nội dung thông báo'),
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _notification.body,
                        style: AppTextStyles.body.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDateTime(_notification.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 560),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 26),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _deleteNotification,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                    label: Text(context.tr('Xóa thông báo')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
