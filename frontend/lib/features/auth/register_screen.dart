import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'otp_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isEmail = true;

  final AppColorScheme _colors = AppColors.light;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  bool loading = false;
  bool agreeTerms = false;

  TextStyle get _titleStyle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _colors.textPrimary,
      );

  void _showError(BuildContext context, String message) {
    final text = message.replaceAll('Exception: ', '').trim();
    showTopSnackBar(context, text, isError: true);
  }

  Widget _buildTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _colors.primary : _colors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _colors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : _colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF9E5), Color(0xFFFFF2B8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 360,
                      child: Card(
                        elevation: 12,
                        shadowColor: _colors.shadow,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(context.tr('Đăng ký'), style: _titleStyle),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('Tạo tài khoản mới để bắt đầu'),
                              style: TextStyle(color: _colors.textSecondary),
                            ),

                            const SizedBox(height: 16),
                            _buildInputLabel(context.tr('Họ và tên')),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                hintText: context.tr('Họ và tên'),
                                prefixIcon: const Icon(Icons.person),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: _colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(children: [
                                _buildTab(
                                  label: context.tr('Email'),
                                  selected: isEmail,
                                  onTap: () => setState(() => isEmail = true),
                                ),
                                const SizedBox(width: 6),
                                _buildTab(
                                  label: context.tr('Số điện thoại'),
                                  selected: !isEmail,
                                  onTap: () => setState(() => isEmail = false),
                                ),
                              ]),
                            ),

                            const SizedBox(height: 12),
                            if (isEmail) ...[
                              _buildInputLabel(context.tr('Email')),
                              const SizedBox(height: 6),
                              TextField(
                                controller: emailCtrl,
                                decoration: InputDecoration(
                                  hintText: context.tr('Email'),
                                  prefixIcon: const Icon(Icons.mail),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInputLabel(context.tr('Password')),
                              const SizedBox(height: 6),
                              TextField(
                                controller: passCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: context.tr('Password'),
                                  prefixIcon: const Icon(Icons.lock),
                                ),
                              ),
                            ] else ...[
                              _buildInputLabel(context.tr('Số điện thoại')),
                              const SizedBox(height: 6),
                              TextField(
                                controller: phoneCtrl,
                                decoration: InputDecoration(
                                  hintText: context.tr('Số điện thoại'),
                                  prefixIcon: const Icon(Icons.phone),
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: agreeTerms,
                                  onChanged: (v) => setState(() => agreeTerms = v ?? false),
                                ),
                                Expanded(
                                  child: Text(
                                    context.tr('Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật'),
                                    style: TextStyle(
                                        fontSize: 12, color: _colors.textSecondary),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: (loading || !agreeTerms)
                                    ? null
                                    : () async {
                                        setState(() => loading = true);
                                        try {
                                          final name = nameCtrl.text.trim();
                                          final email = emailCtrl.text.trim();
                                          final pass = passCtrl.text.trim();
                                          final phone = phoneCtrl.text.trim();

                                          if (isEmail) {
                                            if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                                              _showError(context, context.tr('Cần điền đầy đủ thông tin'));
                                              return;
                                            }
                                          } else {
                                            if (name.isEmpty || phone.isEmpty) {
                                              _showError(context, context.tr('Cần điền đầy đủ thông tin'));
                                              return;
                                            }
                                            if (!_isValidPhone(phone)) {
                                              _showError(context, context.tr('Số điện thoại không đúng định dạng'));
                                              return;
                                            }
                                          }

                                          if (isEmail) {
                                            await AuthService.registerEmail(name, email, pass);
                                          } else {
                                            await AuthService.sendOtpForRegister(phone);
                                            if (!mounted) return;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => OtpScreen(
                                                  phone: phone,
                                                  fullName: name,
                                                  isRegister: true,
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          _showError(context, _mapRegisterError(e.toString()));
                                        } finally {
                                          if (mounted) setState(() => loading = false);
                                        }
                                      },
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(context.tr('Đăng ký'),
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.tr('Đã có tài khoản? Đăng nhập ngay'),
                                  style: TextStyle(color: _colors.textSecondary)),
                            )
                          ]),
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
    );
  }

  Widget _buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _colors.textSecondary,
        ),
      ),
    );
  }

  bool _isValidPhone(String phone) => RegExp(r'^0\\d{9}$').hasMatch(phone);

  String _mapRegisterError(String raw) {
    final text = raw.replaceAll('Exception: ', '').trim().toLowerCase();
    if (text.contains('exist') || text.contains('đã tồn tại') || text.contains('already')) {
      return 'Tài khoản đã tồn tại';
    }
    return raw.replaceAll('Exception: ', '').trim();
  }
}
