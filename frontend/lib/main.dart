import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/features/shopping/shopping_screen.dart';
import 'dart:convert';
import 'core/notifications/push_service.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_controller.dart';
import 'features/auth/login_screen.dart';
import 'home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  await LocaleController.instance.load();

  try {
    await Firebase.initializeApp();
    await PushService.instance.initialize();
  } catch (e, stackTrace) {
    debugPrint('Startup warning: Firebase/Push init failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeController.instance.mode,
        locale: LocaleController.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const _StartupAuthGate(),
        routes: {
          '/shopping': (context) => const ShoppingScreen(),
        },
      ),
    );
  }
}

class _StartupAuthGate extends StatefulWidget {
  const _StartupAuthGate();

  @override
  State<_StartupAuthGate> createState() => _StartupAuthGateState();
}

class _StartupAuthGateState extends State<_StartupAuthGate> {
  late final Future<Widget> _startupScreen;

  @override
  void initState() {
    super.initState();
    _startupScreen = _resolveStartupScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startupScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }

  Future<Widget> _resolveStartupScreen() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      return const LoginScreen();
    }

    if (_isTokenExpired(token)) {
      await TokenStorage.clear();
      return const LoginScreen();
    }

    return const HomeScreen();
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = _decodeBase64Url(parts[1]);
      if (payload == null) return true;

      final data = jsonDecode(payload);
      if (data is! Map || data['exp'] == null) return false;

      final expRaw = data['exp'];
      final expSeconds = expRaw is int
          ? expRaw
          : int.tryParse(expRaw.toString());

      if (expSeconds == null) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }

  String? _decodeBase64Url(String input) {
    try {
      final normalized = base64Url.normalize(input);
      return utf8.decode(base64Url.decode(normalized));
    } catch (_) {
      return null;
    }
  }
}
