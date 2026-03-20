import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/l10n/app_localizations.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const EmailOtpScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final otpCtrl = TextEditingController();
  bool loading = false;
  final AppColorScheme _colors = AppColors.light;

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(context.tr('Quay lại'),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('Xác thực Email OTP'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${context.tr('Mã OTP đã gửi tới')} ${widget.email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpCtrl,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        filled: true,
                        fillColor: _colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _colors.border),
                        ),
                      ),
                      style: const TextStyle(
                        letterSpacing: 14,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                setState(() => loading = true);
                                try {
                                  await AuthService.registerEmail(
                                    widget.fullName,
                                    widget.email,
                                    widget.password,
                                    otpCtrl.text.trim(),
                                  );

                                  if (!mounted) return;
                                  showTopSnackBar(
                                    context,
                                    context.tr('Đăng ký thành công. Vui lòng đăng nhập.'),
                                  );
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  showTopSnackBar(
                                    context,
                                    e.toString().replaceAll('Exception: ', ''),
                                    isError: true,
                                  );
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
                            : Text(context.tr('Xác nhận'),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
