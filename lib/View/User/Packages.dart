import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class PackagesPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const PackagesPage({super.key, required this.user});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  List<Map<String, dynamic>> packages = [];
  bool _isLoading = true;
  final String baseUrl = ApiConfig.packagesBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (!mounted) return;

        setState(() {
          packages = data.map((packageData) {
            final imageUrl = _resolvePackageImage(packageData['imageUrl']);

            return {
              "id": packageData['id'],
              "category": _normalizeCategory(packageData['category']),
              "title": (packageData['title'] ?? '').toString(),
              "description": (packageData['description'] ?? '').toString(),
              "price": packageData['price']?.toString() ?? '',
              "imageUrl": imageUrl,
              "location": (packageData['location'] ?? '').toString(),
              "telescopeProvided": packageData['telescopeProvided'],
              "bestViewingTime": (packageData['bestViewingTime'] ?? '')
                  .toString(),
              "weatherDep": (packageData['weatherDep'] ?? '').toString(),
              "stargazingStatus": (packageData['stargazingStatus'] ?? '')
                  .toString(),
              "eventDate": packageData['event_date']?.toString() ?? '',
              "eventTime": (packageData['event_time'] ?? '').toString(),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _resolvePackageImage(dynamic imageValue) {
    final imagePath = (imageValue ?? '').toString().trim();

    if (imagePath.isEmpty) {
      return '';
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    return "${ApiConfig.rootUrl}/uploads/$imagePath";
  }

  String _normalizeCategory(dynamic categoryValue) {
    final category = (categoryValue ?? '').toString().trim().toLowerCase();

    if (category == 'stargazing' ||
        category == 'astro' ||
        category == 'astronomy') {
      return 'Astro';
    }

    if (category == 'agro' ||
        category == 'agriculture' ||
        category == 'farming' ||
        category == 'farm') {
      return 'Agro';
    }

    if (category == 'tour' ||
        category == 'tours' ||
        category == 'travel' ||
        category == 'sightseeing') {
      return 'Tour';
    }

    return (categoryValue ?? '').toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Packages"),
          bottom: const TabBar(
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: "Tour"),
              Tab(text: "Astro"),
              Tab(text: "Agro"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PackageList(
              category: "Tour",
              packages: packages,
              user: widget.user,
            ),
            PackageList(
              category: "Astro",
              packages: packages,
              user: widget.user,
            ),
            PackageList(
              category: "Agro",
              packages: packages,
              user: widget.user,
            ),
          ],
        ),
      ),
    );
  }
}

class PackageList extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> packages;
  final Map<String, dynamic> user;

  const PackageList({
    super.key,
    required this.category,
    required this.packages,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final filteredPackages = packages
        .where(
          (packageData) =>
              (packageData["category"] ?? '').toString().toLowerCase() ==
              category.toLowerCase(),
        )
        .toList();

    if (filteredPackages.isEmpty) {
      return Center(
        child: Text(
          "No $category packages available",
          style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filteredPackages.length,
      itemBuilder: (context, index) {
        final packageData = filteredPackages[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PackageCard(packageData: packageData, user: user),
        );
      },
    );
  }
}

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> packageData;
  final Map<String, dynamic> user;

  const PackageCard({super.key, required this.packageData, required this.user});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (packageData["imageUrl"] ?? '').toString();
    final category = (packageData["category"] ?? '').toString();
    final title = (packageData["title"] ?? '').toString();
    final description = (packageData["description"] ?? '').toString();
    final location = (packageData["location"] ?? '').toString();
    final price = (packageData["price"] ?? '').toString();
    final isAstro = category.toLowerCase() == 'astro';
    final isTour = category.toLowerCase() == 'tour';
    final eventDate = (packageData["eventDate"] ?? '').toString();
    final eventTime = (packageData["eventTime"] ?? '').toString();
    final detailA = location.isNotEmpty
        ? location
        : (isAstro
              ? 'Night experience'
              : isTour
              ? 'Guided experience'
              : 'Farm experience');
    final detailB = eventTime.isNotEmpty
        ? eventTime
        : eventDate.isNotEmpty
        ? eventDate.split('T').first
        : (isAstro
              ? 'Guided skywatch'
              : isTour
              ? 'Local sightseeing'
              : 'Hands-on local stay');

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PackageDetailsPage(packageData: packageData, user: user),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: imageUrl.isEmpty
                      ? Container(
                          height: 200,
                          color: AppColors.mutedSurface,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 44,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: AppColors.mutedSurface,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 44,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detailA,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (price.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            price,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(icon: Icons.place_outlined, label: detailA),
                      _InfoPill(
                        icon: isAstro
                            ? Icons.nightlight_round
                            : isTour
                            ? Icons.tour_outlined
                            : Icons.eco_outlined,
                        label: detailB,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            "Curated experience",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PackageDetailsPage(
                                packageData: packageData,
                                user: user,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                        child: const Text("View"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PackageDetailsPage extends StatefulWidget {
  final Map<String, dynamic> packageData;
  final Map<String, dynamic> user;

  const PackageDetailsPage({
    super.key,
    required this.packageData,
    required this.user,
  });

  @override
  State<PackageDetailsPage> createState() => _PackageDetailsPageState();
}

class _PackageDetailsPageState extends State<PackageDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  bool _isSubmitting = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'package_id': widget.packageData['id'],
          'user_id': widget.user['id'],
          'date': _dateController.text.trim(),
        }),
      );

      final Map<String, dynamic>? body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body?['message']?.toString() ??
                  'Booking request sent to the host. Current status: Pending',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body?['error']?.toString() ?? 'Failed to submit booking',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatLabel(String label, dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return '';
    return "$label: $text";
  }

  @override
  Widget build(BuildContext context) {
    final packageData = widget.packageData;
    final category = (packageData["category"] ?? '').toString();
    final imageUrl = (packageData["imageUrl"] ?? '').toString();
    final isAstro = category.toLowerCase() == 'astro';
    final isTour = category.toLowerCase() == 'tour';
    final telescopeProvided =
        packageData["telescopeProvided"] == 1 ||
        packageData["telescopeProvided"] == true;
    final userName = (widget.user['name'] ?? 'Traveler').toString();
    final userEmail = (widget.user['email'] ?? '').toString();

    final details = <String>[
      _formatLabel("Category", packageData["category"]),
      _formatLabel("Location", packageData["location"]),
      _formatLabel("Price", packageData["price"]),
      _formatLabel("Event Date", packageData["eventDate"]),
      _formatLabel("Event Time", packageData["eventTime"]),
      if (isTour) "Experience Type: Guided city or local tour",
      if (isAstro) "Telescope Provided: ${telescopeProvided ? 'Yes' : 'No'}",
      if (isAstro)
        _formatLabel("Best Viewing Time", packageData["bestViewingTime"]),
      if (isAstro)
        _formatLabel("Weather Dependency", packageData["weatherDep"]),
      if (isAstro) _formatLabel("Sky Status", packageData["stargazingStatus"]),
    ].where((item) => item.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text((packageData["title"] ?? 'Package').toString()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isEmpty
                  ? Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 56),
                    )
                  : Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 56,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              (packageData["title"] ?? '').toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              (packageData["description"] ?? '').toString(),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "Package Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 8, color: Colors.teal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(detail)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Book This Package",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Booking will use your logged-in account",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  if (userEmail.isNotEmpty)
                    Text(
                      userEmail,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      labelText: "Booking Date",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please select a booking date";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      "After booking, a pending request is created automatically and the host can review it from their booking requests screen.",
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Book Now"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
