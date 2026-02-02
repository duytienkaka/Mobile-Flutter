import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import '../../core/storage/token_storage.dart';
import '../../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void verify() async {
    if (codeCtrl.text.isEmpty) {
      _showError("Vui lòng nhập mã OTP");
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyOtp(widget.phone, codeCtrl.text);
    setState(() => _isLoading = false);

    if (result["success"] == true) {
      await TokenStorage.saveToken(result["token"]);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } else {
      _showError(result["message"] ?? "OTP không hợp lệ");
    }
  }

  void resendOtp() async {
    setState(() => _isLoading = true);
    final result = await AuthService.sendOtp(widget.phone);
    setState(() => _isLoading = false);

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã gửi lại mã OTP"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(result["message"] ?? "Không thể gửi lại OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFFFFFDF2);
    const bgBottom = Color(0xFFF6EEC8);
    const accent = Color(0xFFFFD233);
    const greyText = Color(0xFF8A8A8A);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Container(
              width: 420,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    color: Color(0x22000000),
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Text("Quay lại", style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Xác thực OTP",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      const Text(
                        "Mã xác thực đã được gửi đến số điện thoại",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: greyText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 10),
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF8A8A8A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Mã hết hạn sau 30s",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: greyText),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "Xác nhận",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoading ? null : resendOtp,
                    child: const Text("Không nhận được mã? Gửi lại"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
