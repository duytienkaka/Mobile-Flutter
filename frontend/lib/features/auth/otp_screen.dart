import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/l10n/app_localizations.dart';
import '../../home/home_screen.dart';
import 'dart:async';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? fullName;
  final bool isRegister;

  const OtpScreen({
    super.key,
    required this.phone,
    this.fullName,
    required this.isRegister,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpCtrl = TextEditingController();
  bool loading = false;
  int _remainingSeconds = 30;
  Timer? _timer;

  final AppColorScheme _colors = AppColors.light;

  TextStyle get _titleStyle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _colors.textPrimary,
      );

  @override
  void dispose() {
    otpCtrl.dispose();
    _timer?.cancel();
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
                  Text(context.tr('Xác thực OTP'), style: _titleStyle),
                  const SizedBox(height: 6),
                  Text(
                    '${context.tr('Mã xác thực đã được gửi đến số điện thoại')}\n${widget.phone}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpCtrl,
                    maxLength: 6,
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
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      letterSpacing: 14,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                    Text('${context.tr('Mã hết hạn sau')} ${_remainingSeconds}s',
                      style: TextStyle(color: _colors.textMuted, fontSize: 12)),
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
                                if (widget.isRegister) {
                                  await AuthService.registerPhone(
                                      widget.fullName!,
                                      widget.phone,
                                      otpCtrl.text);
                                } else {
                                  await AuthService.loginPhone(
                                      widget.phone, otpCtrl.text);
                                }

                                if (!mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                final text =
                                    e.toString().replaceAll('Exception: ', '');
                                // ignore: use_build_context_synchronously
                                showTopSnackBar(context, text, isError: true);
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
                  const SizedBox(height: 10),
                      Text(context.tr('Không nhận được mã? Liên hệ hỗ trợ'),
                      style:
                          TextStyle(color: _colors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }
}
