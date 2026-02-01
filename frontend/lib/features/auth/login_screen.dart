import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../../core/storage/token_storage.dart';
import 'otp_screen.dart';
import '../../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  @override
  void initState() {
    _tab = TabController(length: 2, vsync: this);
    super.initState();
  }

  void loginEmail() async {
    final token = await AuthService.loginEmail(emailCtrl.text, passCtrl.text);

    if (token != null) {
      await TokenStorage.saveToken(token);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đăng nhập thất bại")));
    }
  }

  void loginPhone() async {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => OtpScreen(phone: phoneCtrl.text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: "Email"),
              Tab(text: "Số điện thoại"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // EMAIL
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: "Email"),
                      ),
                      TextField(
                        controller: passCtrl,
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loginEmail,
                        child: const Text("Đăng nhập"),
                      ),
                    ],
                  ),
                ),

                // PHONE
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: "Số điện thoại",
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loginPhone,
                        child: const Text("Gửi OTP"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
