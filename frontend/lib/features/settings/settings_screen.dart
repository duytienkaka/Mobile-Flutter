import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/top_snackbar.dart';
import '../auth/login_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../notification/notification_screen.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';
import '../../home/home_screen.dart';
import 'settings_service.dart';
import 'policy_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeController _theme = ThemeController.instance;
  final LocaleController _locale = LocaleController.instance;
  static const _notificationKey = 'notifications_enabled';
  final ImagePicker _picker = ImagePicker();
  bool darkMode = false;
  bool notificationsEnabled = true;
  String languageCode = 'vi';
  String? fullName;
  String? avatarUrl;
  bool loadingProfile = false;

  @override
  void initState() {
    super.initState();
    darkMode = _theme.isDark;
    _theme.addListener(_syncTheme);
    languageCode = _locale.locale.languageCode;
    _locale.addListener(_syncLocale);
    _loadNotificationPreference();
    _loadProfile();
  }

  @override
  void dispose() {
    _theme.removeListener(_syncTheme);
    _locale.removeListener(_syncLocale);
    super.dispose();
  }

  void _syncTheme() {
    if (mounted) {
      setState(() => darkMode = _theme.isDark);
    }
  }

  void _syncLocale() {
    if (mounted) {
      setState(() => languageCode = _locale.locale.languageCode);
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_notificationKey) ?? true;
    final status = await Permission.notification.status;
    final enabled = stored && status.isGranted;
    if (!mounted) return;
    setState(() => notificationsEnabled = enabled);
  }

  Future<void> _loadProfile() async {
    setState(() => loadingProfile = true);
    try {
      final profile = await SettingsService.getProfile();
      if (!mounted) return;
      setState(() {
        fullName = profile.fullName;
        avatarUrl = profile.avatarUrl;
      });
    } catch (_) {
      await _loadNameFromToken();
    } finally {
      if (mounted) {
        setState(() => loadingProfile = false);
      }
    }
  }

  Future<void> _loadNameFromToken() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;
    final name = _readJwtClaim(token, 'unique_name');
    if (!mounted) return;
    setState(() => fullName = name);
  }

  String? _readJwtClaim(String token, String claimKey) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = _decodeBase64Url(parts[1]);
    if (payload == null) return null;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data[claimKey] is String) {
        final value = (data[claimKey] as String).trim();
        return value.isEmpty ? null : value;
      }
    } catch (_) {}
    return null;
  }

  String? _decodeBase64Url(String input) {
    try {
      final normalized = base64Url.normalize(input);
      return utf8.decode(base64Url.decode(normalized));
    } catch (_) {
      return null;
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
    BuildContext? context,
  }) {
    final target = context ?? this.context;
    showTopSnackBar(target, message, isError: isError);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Đăng xuất')),
        content: Text(context.tr('Bạn chắc chắn muốn đăng xuất?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Huỷ')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Đăng xuất')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickLanguage() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(context.tr('Tiếng Việt')),
              onTap: () => Navigator.pop(context, 'Tiếng Việt'),
            ),
            ListTile(
              title: Text(context.tr('English')),
              onTap: () => Navigator.pop(context, 'English'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return;
    if (selection == 'English') {
      await _locale.setLocale(const Locale('en'));
    } else {
      await _locale.setLocale(const Locale('vi'));
    }
    _showMessage(context.tr('Đã cập nhật ngôn ngữ'));
  }

  Future<void> _toggleNotifications() async {
    if (notificationsEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationKey, false);
      if (!mounted) return;
      setState(() => notificationsEnabled = false);
      _showMessage(context.tr('Đã tắt thông báo'));
      return;
    }

    final status = await Permission.notification.request();
    if (status.isGranted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationKey, true);
      if (!mounted) return;
      setState(() => notificationsEnabled = true);
      _showMessage(context.tr('Đã bật thông báo'));
      return;
    }

    if (status.isPermanentlyDenied) {
      _showMessage(
        context.tr('Vui lòng cấp quyền thông báo trong cài đặt'),
        isError: true,
      );
      await openAppSettings();
      return;
    }

    _showMessage(context.tr('Bạn đã từ chối quyền thông báo'), isError: true);
  }

  Future<void> _toggleDarkMode() async {
    await _theme.toggle();
    _showMessage(
      _theme.isDark
          ? context.tr('Đã bật chế độ tối')
          : context.tr('Đã tắt chế độ tối'),
    );
  }

  Future<void> _openAvatarPicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.tr('Chụp ảnh')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.tr('Chọn từ thư viện')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Dùng ảnh này?')),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(picked.path), height: 180, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Không')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Sử dụng')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final profile = await SettingsService.uploadAvatar(File(picked.path));
      if (!mounted) return;
      setState(() => avatarUrl = profile.avatarUrl);
      _showMessage(context.tr('Đã cập nhật ảnh đại diện'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openEditNameSheet({required String title}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _EditNameSheet(title: title, initialValue: fullName ?? ''),
    );
    if (result == null) return;
    try {
      final profile = await SettingsService.updateProfile(fullName: result);
      if (!mounted) return;
      setState(() => fullName = profile.fullName);
      _showMessage(context.tr('Đã cập nhật hồ sơ'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openChangePasswordSheet() async {
    final rootContext = context;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChangePasswordSheet(
        onSuccess: () => _showMessage(
          context.tr('Đổi mật khẩu thành công'),
          context: rootContext,
        ),
        onError: (message) =>
            _showMessage(message, isError: true, context: rootContext),
      ),
    );
  }

  void _openScreen(Widget screen) {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final name = (fullName == null || fullName!.trim().isEmpty)
        ? context.tr('Người dùng')
        : fullName!.trim();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final avatarImage = SettingsService.resolveAvatarUrl(avatarUrl);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MainFab(
        onPressed: () => _openScreen(const PantryScreen()),
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: -1,
        onHome: () => _openScreen(const HomeScreen()),
        onRecipe: () => _openScreen(const RecipeScreen()),
        onShopping: () => _openScreen(const ShoppingScreen()),
        onNotifications: () => _openScreen(const NotificationScreen()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: BackHeader(
                title: context.tr('Cài đặt'),
                trailing: GestureDetector(
                  onTap: _openAvatarPicker,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: avatarImage != null
                        ? NetworkImage(avatarImage)
                        : null,
                    child: avatarImage == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _SectionCard(
                    title: context.tr('Hồ sơ người dùng'),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _openAvatarPicker,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColors.primarySoft,
                                    backgroundImage: avatarImage != null
                                        ? NetworkImage(avatarImage)
                                        : null,
                                    child: avatarImage == null
                                        ? Text(
                                            initials,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                              color: AppColors.textPrimary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                loadingProfile
                                    ? context.tr('Đang tải...')
                                    : name,
                                style: AppTextStyles.title,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _openEditNameSheet(
                                title: context.tr('Chỉnh sửa hồ sơ'),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(context.tr('Sửa hồ sơ')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppColors.border),
                        _SettingsRow(
                          icon: Icons.edit_outlined,
                          title: context.tr('Đổi tên'),
                          onTap: () =>
                              _openEditNameSheet(title: context.tr('Đổi tên')),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingsRow(
                          icon: Icons.lock_outline,
                          title: context.tr('Đổi mật khẩu'),
                          onTap: _openChangePasswordSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: context.tr('Tuỳ chọn'),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          title: context.tr('Chế độ tối'),
                          trailing: Switch(
                            value: darkMode,
                            onChanged: (_) => _toggleDarkMode(),
                          ),
                          showChevron: false,
                          onTap: null,
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingsRow(
                          icon: Icons.language,
                          title: context.tr('Ngôn ngữ'),
                          trailingText: languageCode == 'en'
                              ? context.tr('English')
                              : context.tr('Tiếng Việt'),
                          onTap: _pickLanguage,
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingsRow(
                          icon: Icons.notifications_none,
                          title: context.tr('Thông báo'),
                          trailingText: notificationsEnabled
                              ? context.tr('Bật')
                              : context.tr('Tắt'),
                          onTap: _toggleNotifications,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: context.tr('Thông tin'),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: context.tr('Chính sách bảo mật'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingsRow(
                          icon: Icons.description_outlined,
                          title: context.tr('Điều khoản dịch vụ'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsOfServiceScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _confirmLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        context.tr('Đăng xuất'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  final String title;
  final String initialValue;

  const _EditNameSheet({required this.title, required this.initialValue});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      showTopSnackBar(
        context,
        context.tr('Tên không được để trống'),
        isError: true,
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: context.tr('Họ và tên'),
              hintText: context.tr('Nhập họ và tên'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('Huỷ')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(context.tr('Lưu')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final trailingWidget =
        trailing ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(trailingText!, style: AppTextStyles.body),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ],
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.body)),
            trailingWidget,
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final ValueChanged<String> onError;

  const _ChangePasswordSheet({required this.onSuccess, required this.onError});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = currentCtrl.text.trim();
    final next = newCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      widget.onError(context.tr('Vui lòng điền đầy đủ thông tin'));
      return;
    }
    if (current == next) {
      widget.onError(
        context.tr('Mật khẩu mới không được trùng mật khẩu hiện tại'),
      );
      return;
    }
    if (next.length < 6) {
      widget.onError(context.tr('Mật khẩu mới tối thiểu 6 ký tự'));
      return;
    }
    if (next != confirm) {
      widget.onError(context.tr('Mật khẩu xác nhận không khớp'));
      return;
    }
    setState(() => saving = true);
    try {
      await SettingsService.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('Đổi mật khẩu'), style: AppTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: currentCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr('Mật khẩu hiện tại'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: context.tr('Mật khẩu mới')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr('Xác nhận mật khẩu mới'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: Text(context.tr('Huỷ')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: saving ? null : _submit,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Cập nhật')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
