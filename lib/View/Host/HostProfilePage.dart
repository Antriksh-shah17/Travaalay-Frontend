import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:traavaalay/View/Login.dart';
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class HostProfilePage extends StatefulWidget {
  final Map<String, dynamic> user; // Pass the host JSON data

  const HostProfilePage({super.key, required this.user});

  @override
  State<HostProfilePage> createState() => _HostProfilePageState();
}

class _HostProfilePageState extends State<HostProfilePage> {
  late String verificationStatus;

  @override
  void initState() {
    super.initState();
    final v = widget.user['verified'];
    bool isVerified = v == 1 || v == true || v == '1';
    verificationStatus = isVerified ? "Verified ✅" : "Not Verified / Pending";
    _fetchLatestStatus();
  }

  /// Fetch the latest user profile from the DB to check if Admin approved them
  Future<void> _fetchLatestStatus() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.usersBaseUrl}/${widget.user['id']}'));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        
        final Map<String, dynamic> data = decodedData is List 
            ? (decodedData.isNotEmpty ? decodedData[0] : {}) 
            : decodedData;
            
        final v = data['verified'];
        bool isVerified = v == 1 || v == true || v == '1';
        
        if (mounted) {
          setState(() {
            if (isVerified) {
              verificationStatus = "Verified ✅";
            } else {
              verificationStatus = "Not Verified / Pending";
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching latest status: $e");
    }
  }

  /// Pick image and upload via standard HTTP Multipart Request
  Future<void> _uploadDocument(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);

    setState(() {
      verificationStatus = "Uploading $type...";
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${ApiConfig.translatorsBaseUrl}/upload-document'));
          
      request.fields['translatorId'] = widget.user['id'].toString();
      request.fields['documentType'] = type;
      request.files.add(await http.MultipartFile.fromPath('document', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          verificationStatus = "$type Uploaded (Pending Verification)";
        });
      } else {
        throw Exception("Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        verificationStatus = "Error uploading $type ❌";
      });
      print("Upload error: $e");
    }
  }

  /// Send overall verification request to backend
  Future<void> _proceedToVerify() async {
    setState(() {
      verificationStatus = "Sending request...";
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.translatorsBaseUrl}/request-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "translatorId": widget.user['id'],
          "name": widget.user['name'] ?? "Unknown",
          "email": widget.user['email'] ?? "",
          "city": widget.user['city'] ?? "",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          verificationStatus = "Pending Admin Approval";
        });
      } else {
        throw Exception("Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        verificationStatus = "Error sending request ❌";
      });
      print("API request error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name = (user['name'] ?? "Unknown").toString();
    final email = (user['email'] ?? "No Email").toString();
    final city = (user['city'] ?? "Unknown City").toString();
    final initials = _buildInitials(name);
    final bool isVerified = verificationStatus.contains("Verified ✅");

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchLatestStatus,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 300,
              backgroundColor: AppColors.surface,
              foregroundColor: Colors.white,
              title: const Text("Host Profile"),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                        AppColors.accent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 90,
                        right: -20,
                        child: _buildGlowCircle(
                          size: 160,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: -30,
                        child: _buildGlowCircle(
                          size: 120,
                          color: Colors.amber.withValues(alpha: 0.12),
                        ),
                      ),
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 110, 24, 28),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      CircleAvatar(
                                        radius: 42,
                                        backgroundColor: Colors.white,
                                        child: CircleAvatar(
                                          radius: 38,
                                          backgroundColor: AppColors.secondary,
                                          backgroundImage: user['profileImage'] != null && user['profileImage'].toString().isNotEmpty
                                              ? NetworkImage(
                                                  user['profileImage'].toString().startsWith('http')
                                                      ? user['profileImage'].toString()
                                                      : "${ApiConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '')}/uploads/${user['profileImage']}"
                                                )
                                              : null,
                                          child: user['profileImage'] == null || user['profileImage'].toString().isEmpty
                                              ? Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.verified, color: Colors.amber, size: 28),
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Host • $city",
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: "Personal Details",
                      subtitle: "Your public profile information.",
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.person_outline, "Full Name", name),
                          _buildInfoRow(Icons.email_outlined, "Email", email),
                          _buildInfoRow(Icons.location_city_outlined, "City", city, isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      title: "Verification Status",
                      subtitle: isVerified 
                          ? "Your profile is fully verified." 
                          : "Complete your verification to build trust with tourists.",
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? AppColors.success.withValues(alpha: 0.14)
                                  : AppColors.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isVerified ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isVerified ? Icons.verified : Icons.pending_actions, 
                                  color: isVerified ? AppColors.success : AppColors.warning
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    verificationStatus, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: isVerified ? AppColors.success : AppColors.warning
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isVerified) ...[
                            const SizedBox(height: 16),
                            _buildActionTile(
                              icon: Icons.badge_outlined,
                              title: "Upload ID Proof",
                              subtitle: "Passport, Aadhaar, Driver's License",
                              accent: AppColors.accent,
                              onTap: () => _uploadDocument("ID Proof"),
                            ),
                            const SizedBox(height: 12),
                            _buildActionTile(
                              icon: Icons.workspace_premium_outlined,
                              title: "Upload Certificates",
                              subtitle: "Hosting or Guide Certifications",
                              accent: AppColors.secondary,
                              onTap: () => _uploadDocument("Certificate"),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _proceedToVerify,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Proceed to Verify", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      title: "Quick Actions",
                      subtitle: "Manage your account settings.",
                      child: Column(
                        children: [
                          _buildActionTile(
                            icon: Icons.edit_outlined,
                            title: "Edit Profile",
                            subtitle: "Update your details and offerings",
                            accent: AppColors.accent,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Edit profile coming soon")),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionTile(
                            icon: Icons.logout,
                            title: "Logout",
                            subtitle: "End your session safely",
                            accent: AppColors.danger,
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name.split(' ').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "H";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  Widget _buildGlowCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.mutedSurface, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
