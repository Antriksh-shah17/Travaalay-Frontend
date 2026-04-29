import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:http/http.dart' as http;
import 'package:traavaalay/View/Admin/AdminDashboard.dart';
import 'package:traavaalay/View/Host/Host_Dashboard.dart';
import 'package:traavaalay/View/Signup.dart';
import 'package:traavaalay/View/Translator/TranslatorDashboard.dart';
import 'package:traavaalay/View/User/UserDash.dart';
import 'package:traavaalay/View/User/token_storage.dart';
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  // ✅ Using HTTPS for DevTunnels
  final String baseUrl = ApiConfig.authBaseUrl;
  Future<void> login() async {
    setState(() => loading = true);

    try {
      print('🔵 Attempting login to: $baseUrl/login');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': emailController.text.trim(),
              'password': passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Response Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      setState(() => loading = false);

      if (response.statusCode == 200) {
        final token = data['token'];
        final user = data['user'];

        await TokenStorage.saveToken(token);
        print('✅ Login successful for user: ${user['name']}');

        String role = user['role']?.toLowerCase() ?? 'user';

        if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(user: user)),
          );
        } else if (role == 'host') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HostDashboard(user: user)),
          );
        } else if (role == 'translator') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TranslatorDashboard(user: user)),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Unknown role")));
        }
      } else {
        final message = data['message'] ?? 'Login failed';
        print('❌ Login error: $message');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      setState(() => loading = false);
      print('🔴 Exception during login: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  Widget _buildFastLoginButtons(
    TextEditingController emailCtrl,
    TextEditingController passCtrl,
  ) {
    void fillAndLogin(String email, String password) {
      emailCtrl.text = email;
      passCtrl.text = password;
      login(); // Auto-triggers the login sequence
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          const Text(
            "Fast Login (Testing Only)",
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                label: const Text("User"),
                avatar: const Icon(Icons.person, size: 16),
                onPressed: () => fillAndLogin('rajesh.kumar@example.com', 'password123'),
              ),
              ActionChip(
                label: const Text("Translator"),
                avatar: const Icon(Icons.translate, size: 16),
                onPressed: () => fillAndLogin('amit.singh@example.com', 'password123'),
              ),
              ActionChip(
                label: const Text("Host"),
                avatar: const Icon(Icons.home, size: 16),
                onPressed: () => fillAndLogin('vikram.joshi@example.com', 'password123'),
              ),
              ActionChip(
                label: const Text("Admin"),
                avatar: const Icon(Icons.admin_panel_settings, size: 16),
                onPressed: () => fillAndLogin('admin@travaalay.com', 'password123'),
              ),
            ],
          ),
        ],
      ),
    );
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
              Image.asset("assets/TravText.png", height: 200),
              const SizedBox(height: 30),
              // Text(
              //   "Login Now",
              //   style: GoogleFonts.poppins(
              //     fontSize: 14,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 30),

              // Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              // Login Button
              ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Login",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Fast Login buttons for development
            _buildFastLoginButtons(emailController, passwordController),
            ],
          ),
        ),
      ),
    );
  }
}
