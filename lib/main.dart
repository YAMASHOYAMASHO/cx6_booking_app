import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/config/firebase_config.dart';
import 'src/config/debug_config.dart';
import 'src/views/login_page.dart';
import 'src/views/home_page.dart';
import 'src/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(options: FirebaseConfig.firebaseConfig);

  // 日本語ロケール初期化
  await initializeDateFormatting('ja_JP', null);

  // デバッグモード時の自動ログイン
  if (kDebugMode && DebugConfig.enableAutoLogin) {
    debugPrint('🔧 [Debug] デバッグモード - 自動ログインを試行中...');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: DebugConfig.autoLoginEmail,
        password: DebugConfig.autoLoginPassword,
      );
      debugPrint('✅ [Debug] 自動ログイン成功: ${DebugConfig.autoLoginEmail}');
    } catch (e) {
      debugPrint('⚠️ [Debug] 自動ログイン失敗: $e');
      debugPrint('   通常のログイン画面を表示します');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: '装置予約システム',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // ローカルフォントを使用
        fontFamily: 'NotoSansJP',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'NotoSansJP'),
          displayMedium: TextStyle(fontFamily: 'NotoSansJP'),
          displaySmall: TextStyle(fontFamily: 'NotoSansJP'),
          headlineLarge: TextStyle(fontFamily: 'NotoSansJP'),
          headlineMedium: TextStyle(fontFamily: 'NotoSansJP'),
          headlineSmall: TextStyle(fontFamily: 'NotoSansJP'),
          titleLarge: TextStyle(fontFamily: 'NotoSansJP'),
          titleMedium: TextStyle(fontFamily: 'NotoSansJP'),
          titleSmall: TextStyle(fontFamily: 'NotoSansJP'),
          bodyLarge: TextStyle(fontFamily: 'NotoSansJP'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansJP'),
          bodySmall: TextStyle(fontFamily: 'NotoSansJP'),
          labelLarge: TextStyle(fontFamily: 'NotoSansJP'),
          labelMedium: TextStyle(fontFamily: 'NotoSansJP'),
          labelSmall: TextStyle(fontFamily: 'NotoSansJP'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage();
          } else {
            return const HomePage();
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'エラー: $error',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontFamily: 'monospace',
                      ),
                    ),
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
