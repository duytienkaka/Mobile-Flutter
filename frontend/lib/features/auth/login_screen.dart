import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../auth/register_screen.dart';
import '../auth/otp_screen.dart';
import '../../home/home_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isEmail = true;

  final AppColorScheme _colors = AppColors.light;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  static const _tabAnimDuration = Duration(milliseconds: 350);
  bool loading = false;

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
          duration: _tabAnimDuration,
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
                    Text(context.tr('Đăng nhập'), style: _titleStyle),
                    const SizedBox(height: 6),
                    Text(context.tr('Chào mừng bạn quay trở lại!'),
                        style: TextStyle(color: _colors.textSecondary)),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 18),

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

                    const SizedBox(height: 18),

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
                        onPressed: loading
                            ? null
                            : () async {
        final email = emailCtrl.text.trim();
        final pass = passCtrl.text.trim();
        final phone = phoneCtrl.text.trim();

        if (isEmail) {
          if (email.isEmpty || pass.isEmpty) {
            _showError(context, context.tr('Cần điền đầy đủ thông tin'));
            return;
          }
        } else {
          if (phone.isEmpty) {
            _showError(context, context.tr('Cần điền đầy đủ thông tin'));
            return;
          }
        }

        setState(() => loading = true);
        try {
          if (isEmail) {
            await AuthService.loginEmail(email, pass);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            await AuthService.sendOtpForLogin(phone);
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  phone: phone,
                  isRegister: false,
                ),
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          _showError(context, isEmail
              ? context.tr('Tài khoản hoặc mật khẩu không đúng.')
              : e.toString());
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
                            : Text(context.tr('Đăng nhập'),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          reverseTransitionDuration: const Duration(milliseconds: 350),
                          pageBuilder: (_, animation, __) => FadeTransition(
                            opacity: animation,
                            child: const RegisterScreen(),
                          ),
                        ),
                      ),
                      child: Text(context.tr('Chưa có tài khoản? Đăng ký ngay'),
                          style: TextStyle(color: _colors.textSecondary)),
                    )
                  ]),
                ),
              ),
            ),
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
}
