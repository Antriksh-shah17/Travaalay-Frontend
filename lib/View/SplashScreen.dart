import 'package:flutter/material.dart';
import 'package:traavaalay/View/Login.dart';
import 'package:traavaalay/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          height: 280,
          width: 280,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            child: Image.asset("assets/logog.png", fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
