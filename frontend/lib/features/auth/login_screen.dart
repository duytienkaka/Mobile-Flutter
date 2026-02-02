import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../auth/register_screen.dart';
import '../auth/otp_screen.dart';
import '../../home/home_screen.dart';

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
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
            color: selected ? const Color(0xFFF9D649) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : Colors.black54,
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
            width: 420,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Đăng nhập',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Chào mừng bạn quay trở lại!',
                      style: TextStyle(color: Colors.black54)),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
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

                  const SizedBox(height: 20),

                  if (isEmail) ...[
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: const Color(0xFFF7F7F8),
                        prefixIcon: const Icon(Icons.mail),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        filled: true,
                        fillColor: const Color(0xFFF7F7F8),
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        filled: true,
                        fillColor: const Color(0xFFF7F7F8),
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9D649),
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const HomeScreen()),
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
                    child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                  )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
