import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/top_snackbar.dart';

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

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Quay lại',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Xác thực OTP', style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  Text(
                    'Mã xác thực đã được gửi đến số điện thoại\n${widget.phone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpCtrl,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
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
                  const Text('Mã hết hạn sau 30s',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Xác thực thành công.')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                final text =
                                    e.toString().replaceAll('Exception: ', '');
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
                          : const Text('Xác nhận',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Không nhận được mã? Liên hệ hỗ trợ',
                      style:
                          TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
