import 'package:flutter/material.dart';
import 'package:traavaalay/View/SplashScreen.dart';
import 'package:traavaalay/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TravaalayApp());
}

class TravaalayApp extends StatelessWidget {
  const TravaalayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travaalay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
