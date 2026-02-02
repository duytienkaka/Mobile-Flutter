import 'package:flutter/material.dart';
import '../../core/storage/token_storage.dart';
import '../../home/home_screen.dart';
import 'auth_service.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isEmailMode = true;
  bool agreed = false;
  bool loading = false;
  final _switchDuration = const Duration(milliseconds: 220);

  final fullNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  // ================= EMAIL REGISTER =================
  Future<void> registerEmail() async {
    if (!agreed) {
      showMsg("Bạn phải đồng ý điều khoản");
      return;
    }
    if (fullNameCtrl.text.trim().isEmpty) {
      showMsg("Vui lòng nhập họ và tên");
      return;
    }
    if (emailCtrl.text.trim().isEmpty) {
      showMsg("Vui lòng nhập email");
      return;
    }
    if (!emailCtrl.text.contains('@')) {
      showMsg("Email không hợp lệ");
      return;
    }
    if (passCtrl.text.length < 6) {
      showMsg("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }
    if (passCtrl.text != confirmCtrl.text) {
      showMsg("Mật khẩu không khớp");
      return;
    }

    setState(() => loading = true);

    final result = await AuthService.registerEmail(
      fullNameCtrl.text.trim(),
      emailCtrl.text.trim(),
      passCtrl.text,
    );

    setState(() => loading = false);

    if (result["success"] == true) {
      await TokenStorage.saveToken(result["token"]);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      showMsg(result["message"] ?? "Đăng ký thất bại");
    }
  }

  // ================= PHONE REGISTER =================
  Future<void> registerPhone() async {
    if (!agreed) {
      showMsg("Bạn phải đồng ý điều khoản");
      return;
    }
    if (fullNameCtrl.text.trim().isEmpty) {
      showMsg("Vui lòng nhập họ và tên");
      return;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      showMsg("Vui lòng nhập số điện thoại");
      return;
    }
    if (phoneCtrl.text.trim().length < 8) {
      showMsg("Số điện thoại không hợp lệ");
      return;
    }

    setState(() => loading = true);

    final result = await AuthService.registerPhone(
      fullNameCtrl.text.trim(),
      phoneCtrl.text.trim(),
    );

    setState(() => loading = false);

    if (result["success"] == true) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(phone: phoneCtrl.text.trim()),
          ),
        );
      }
    } else {
      showMsg(result["message"] ?? "Không gửi được OTP");
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
              width: 460,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                  const Text(
                    "Đăng ký",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tạo tài khoản mới để bắt đầu",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: greyText),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(3, 3),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 6,
                          offset: Offset(-3, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _ModeButton(
                          label: "Email",
                          icon: Icons.email_outlined,
                          selected: isEmailMode,
                          accent: accent,
                          onTap: () => setState(() => isEmailMode = true),
                        ),
                        _ModeButton(
                          label: "Số điện thoại",
                          icon: Icons.phone,
                          selected: !isEmailMode,
                          accent: accent,
                          onTap: () => setState(() => isEmailMode = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _ShadowField(
                    controller: fullNameCtrl,
                    hint: "Họ và tên",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),

                  AnimatedSwitcher(
                    duration: _switchDuration,
                    transitionBuilder: (child, animation) {
                      final offsetTween = Tween<Offset>(
                        begin: Offset(isEmailMode ? 0.1 : -0.1, 0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic));
                      return ClipRect(
                        child: SlideTransition(
                          position: animation.drive(offsetTween),
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: isEmailMode
                        ? Column(
                            key: const ValueKey('email'),
                            children: [
                              _ShadowField(
                                controller: emailCtrl,
                                hint: "Email",
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _ShadowField(
                                controller: passCtrl,
                                hint: "Password",
                                icon: Icons.lock_outline,
                                obscure: true,
                              ),
                              const SizedBox(height: 12),
                              _ShadowField(
                                controller: confirmCtrl,
                                hint: "Re - password",
                                icon: Icons.lock_outline,
                                obscure: true,
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('phone'),
                            children: [
                              _ShadowField(
                                controller: phoneCtrl,
                                hint: "Số điện thoại",
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: agreed,
                        onChanged: (v) => setState(() => agreed = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          "Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : isEmailMode
                              ? registerEmail
                              : registerPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "Đăng ký",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Đã có tài khoản? "),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Đăng nhập ngay"),
                      ),
                    ],
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

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.black : Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.black : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShadowField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _ShadowField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(2, 2),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-2, -2),
            spreadRadius: -4,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    );
  }
}
