import 'dart:convert';
import 'package:flutter/material.dart';
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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String _selectedRole = 'user';

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
              'role': _selectedRole,
              'city': "Ahmedabad",
              'phone': phoneController.text.trim(),
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

  Widget _buildLoadingSpinner() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
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

              // PHONE
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // ROLE
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(
                    value: 'translator',
                    child: Text('Translator'),
                  ),
                  DropdownMenuItem(value: 'host', child: Text('Host')),
                ],
                onChanged: loading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedRole = value);
                      },
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

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "OTP Verification",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Send the code first, then verify to create your account.",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: loading ? null : sendOtp,
                            icon: loading
                                ? _buildLoadingSpinner()
                                : const Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 18,
                                  ),
                            label: const Text("Send OTP"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              foregroundColor: AppColors.secondary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: loading ? null : verifySignup,
                            icon: loading
                                ? _buildLoadingSpinner()
                                : const Icon(Icons.verified_rounded, size: 18),
                            label: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
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
                        ),
                      ],
                    ),
                  ],
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
