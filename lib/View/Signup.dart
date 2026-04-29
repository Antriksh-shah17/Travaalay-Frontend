import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'Login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool loading = false;

  final String baseUrl = ApiConfig.authBaseUrl;

  // ========================
  // 📩 SEND OTP
  // ========================
  Future<void> sendOtp() async {
    setState(() => loading = true);

    try {
      print('🔵 Sending OTP to: ${emailController.text.trim()}');
      print('🔵 URL: $baseUrl/send-otp');

      final response = await http
          .post(
            Uri.parse('$baseUrl/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': emailController.text.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      print("🟢 SEND OTP RESPONSE CODE: ${response.statusCode}");
      print("🟢 SEND OTP RESPONSE: ${response.body}");

      setState(() => loading = false);

      if (response.body.isEmpty) {
        throw Exception("Empty response from server");
      }

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'] ?? "OTP sent")));
    } catch (e) {
      setState(() => loading = false);
      print("🔴 ERROR sending OTP: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending OTP: $e")));
    }
  }

  // ========================
  // 🔥 VERIFY OTP + SIGNUP
  // ========================
  Future<void> verifySignup() async {
    setState(() => loading = true);

    try {
      print('🔵 Verifying signup for: ${emailController.text.trim()}');
      print('🔵 URL: $baseUrl/verify-signup');

      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'password': passwordController.text.trim(),
              'role': roleController.text.trim().toLowerCase(),
              'city': "Ahmedabad",
              'otp': otpController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("🟢 VERIFY RESPONSE CODE: ${response.statusCode}");
      print("🟢 VERIFY RESPONSE: ${response.body}");

      setState(() => loading = false);

      if (response.body.isEmpty) {
        throw Exception("Empty response from server");
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful! Please login."),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final message = data['message'] ?? 'Signup failed';
        print('🟠 Signup error: $message');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      setState(() => loading = false);
      print('🔴 ERROR during signup: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/TravText.png", height: 100),
              const SizedBox(height: 30),

              Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 30),

              // NAME
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // EMAIL
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // ROLE
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: "Role (user/translator/host)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // OTP FIELD (ALPHANUMERIC)
              TextField(
                controller: otpController,
                keyboardType: TextInputType.text, // ✅ FIX
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Enter OTP",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // SEND OTP BUTTON
              ElevatedButton(
                onPressed: loading ? null : sendOtp,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send OTP"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 15),

              // SIGNUP BUTTON
              ElevatedButton(
                onPressed: loading ? null : verifySignup,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LOGIN NAVIGATION
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
