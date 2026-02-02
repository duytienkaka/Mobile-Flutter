import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../auth/register_screen.dart';
import '../auth/otp_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/top_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isEmail = true;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  bool loading = false;

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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    const BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
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
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Đăng nhập', style: AppTextStyles.title),
                    const SizedBox(height: 6),
                    const Text('Chào mừng bạn quay trở lại!',
                        style: TextStyle(color: AppColors.textSecondary)),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(children: [
                        _buildTab(
                          label: 'Email',
                          selected: isEmail,
                          onTap: () => setState(() => isEmail = true),
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          label: 'Số điện thoại',
                          selected: !isEmail,
                          onTap: () => setState(() => isEmail = false),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 18),

                    if (isEmail) ...[
                      _buildInputLabel('Email'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.mail),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInputLabel('Password'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                    ] else ...[
                      _buildInputLabel('Số điện thoại'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                setState(() => loading = true);
                                try {
                                  if (isEmail) {
                                    await AuthService.loginEmail(
                                        emailCtrl.text, passCtrl.text);

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Đăng nhập thành công.')),
                                    );
                                  } else {
                                    await AuthService
                                        .sendOtpForLogin(phoneCtrl.text);
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OtpScreen(
                                          phone: phoneCtrl.text,
                                          isRegister: false,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  _showError(context, e.toString());
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
                            : const Text('Đăng nhập',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Chưa có tài khoản? Đăng ký ngay',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  ]),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
}
