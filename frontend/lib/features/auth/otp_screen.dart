import 'package:flutter/material.dart';
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

  void verify() async {
    final token =
        await AuthService.verifyOtp(widget.phone, codeCtrl.text);

    if (token != null) {
      await TokenStorage.saveToken(token);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP không hợp lệ")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác thực OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Mã gửi tới ${widget.phone}"),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Nhập OTP"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verify,
              child: const Text("Xác nhận"),
            )
          ],
        ),
      ),
    );
  }
}
