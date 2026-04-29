import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:traavaalay/View/User/Translator.dart';

class TranslatorMatchingPage extends StatefulWidget {
  final Map<String, dynamic> user; // Tourist user data

  const TranslatorMatchingPage({super.key, required this.user});

  @override
  State<TranslatorMatchingPage> createState() => _TranslatorMatchingPageState();
}

class _TranslatorMatchingPageState extends State<TranslatorMatchingPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> recommendedGuides = [];
  List<Map<String, dynamic>> fallbackGuides = [];
  String? _errorMessage;
  String? _statusMessage;
  final TextEditingController _cityController = TextEditingController();
  double _selectedBudget = 300;
  List<String> _selectedLanguages = const ['English', 'Hindi'];
  bool _criteriaExpanded = false;

  final String baseUrl = ApiConfig.translatorsBaseUrl;
  final Set<int> _pendingRequests = {};
  static const List<String> _languageOptions = [
    'English',
    'Hindi',
    'Gujarati',
    'Marathi',
    'Punjabi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
  ];

  // 🎯 WEIGHTS FOR MATCHING ALGORITHM
  static const double WEIGHT_LANGUAGE = 0.3;
  static const double WEIGHT_DISTANCE = 0.2;
  static const double WEIGHT_PRICE = 0.15;
  static const double WEIGHT_RATING = 0.1;
  static const double WEIGHT_EXPERIENCE = 0.15;
  static const double WEIGHT_CERTIFIED = 0.1;

  static const double MAX_DISTANCE_KM = 50;
  static const double BUDGET_FLEXIBILITY = 0.15;

  @override
  void initState() {
    super.initState();
    _cityController.text = (widget.user['city'] ?? '').toString();
    _selectedBudget =
        double.tryParse(widget.user['budget']?.toString() ?? '300') ?? 300;
    _selectedLanguages =
        ((widget.user['languages'] as List?) ?? const ['English', 'Hindi'])
            .map((language) => language.toString())
            .where((language) => language.trim().isNotEmpty)
            .toList();
    fetchAndMatchTranslators();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // 📍 Calculate distance between two coordinates
  double calculateDistance(List<double> loc1, List<double> loc2) {
    return (Math.sqrt(
          Math.pow(loc1[0] - loc2[0], 2) + Math.pow(loc1[1] - loc2[1], 2),
        ) *
        111); // Convert to KM
  }

  // 🎯 MAIN MATCHING ALGORITHM
  Future<void> fetchAndMatchTranslators() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _statusMessage = null;
        recommendedGuides = [];
        fallbackGuides = [];
      });
    }

    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final translators = data.map((t) => t as Map<String, dynamic>).toList();
        final allGuides = <Map<String, dynamic>>[];

        print("📊 Total Translators: ${translators.length}");

        // 🧑‍🎓 Get tourist info
        final touristLanguages = _selectedLanguages.isEmpty
            ? ['English', 'Hindi']
            : List<String>.from(_selectedLanguages);
        final touristLocation = _getLocationCoords();
        final touristBudget = _selectedBudget;
        final preferredCity = _cityController.text.trim().toLowerCase();

        print("🗣️ Tourist Languages: $touristLanguages");
        print("📍 Tourist Location: $touristLocation");
        print("💰 Tourist Budget: ₹$touristBudget/hr");

        List<Map<String, dynamic>> matches = [];

        for (var guide in translators) {
          try {
            final guideLanguages = _extractLanguages(guide);
            if (guideLanguages.isEmpty) {
              print("⏭️ Skipping ${guide['name']}: No languages available");
              continue;
            }

            final commonLanguages = touristLanguages
                .where(
                  (lang) => guideLanguages.any(
                    (guideLang) =>
                        guideLang.toLowerCase() == lang.toLowerCase(),
                  ),
                )
                .toList();

            if (commonLanguages.isEmpty) {
              print("⏭️ Skipping ${guide['name']}: No common languages");
              continue;
            }

            final langScore = commonLanguages.length / touristLanguages.length;

            // 3️⃣ Distance score
            final guideLocation = _extractLocation(guide);
            final distKm = calculateDistance(touristLocation, guideLocation);
            final distScore = Math.max(0, 1 - (distKm / MAX_DISTANCE_KM));

            // 4️⃣ Price score
            final guideBudget =
                double.tryParse(guide['charges']?.toString() ?? '300') ?? 300;
            final priceDiff = (touristBudget - guideBudget).abs();
            final maxDiff = touristBudget * BUDGET_FLEXIBILITY;

            double priceScore = 0;
            if (priceDiff <= maxDiff * 2) {
              priceScore = Math.max(0, 1 - (priceDiff / maxDiff));
            }

            // 5️⃣ Other scores
            final reviews = List<double>.from(
              (guide['reviews'] ?? []).map((r) => r.toDouble()),
            );
            final ratingScore = reviews.isNotEmpty
                ? reviews.reduce((a, b) => a + b) / reviews.length / 5
                : 0.5;

            final experienceYears =
                double.tryParse(guide['experience_years']?.toString() ?? '2') ??
                2;
            final expScore = Math.min(experienceYears / 5, 1);

            final isVerified = _asBool(guide['verified']);
            final certScore = isVerified ? 1.0 : 0.5;
            final cityScore =
                preferredCity.isNotEmpty &&
                    (guide['city'] ?? '').toString().toLowerCase() ==
                        preferredCity
                ? 1.0
                : 0.0;
            final normalizedGuide = {
              'id': guide['id'] ?? 0,
              'name': guide['name'] ?? 'Unknown',
              'languages': guideLanguages,
              'rate_per_hour': guideBudget,
              'rating': ratingScore * 5,
              'reviews_count': reviews.length,
              'city': guide['city'] ?? 'Unknown',
              'verified': isVerified,
              'profileImage': _resolveProfileImage(guide['profileImage']),
              'phone': guide['phone'] ?? '',
              'bio': guide['bio'] ?? 'Translator available',
            };

            allGuides.add({
              ...normalizedGuide,
              'score': double.parse(
                (distScore * WEIGHT_DISTANCE +
                        priceScore * WEIGHT_PRICE +
                        ratingScore * WEIGHT_RATING +
                        expScore * WEIGHT_EXPERIENCE +
                        certScore * WEIGHT_CERTIFIED +
                        cityScore * 0.1)
                    .toStringAsFixed(3),
              ),
              'breakdown': {
                'lang': "0.000",
                'dist': (distScore * WEIGHT_DISTANCE).toStringAsFixed(3),
                'price': (priceScore * WEIGHT_PRICE).toStringAsFixed(3),
                'rating': (ratingScore * WEIGHT_RATING).toStringAsFixed(3),
                'exp': (expScore * WEIGHT_EXPERIENCE).toStringAsFixed(3),
                'cert': (certScore * WEIGHT_CERTIFIED).toStringAsFixed(3),
              },
            });

            // 6️⃣ Calculate final score
            final totalScore =
                (langScore * WEIGHT_LANGUAGE +
                distScore * WEIGHT_DISTANCE +
                priceScore * WEIGHT_PRICE +
                ratingScore * WEIGHT_RATING +
                expScore * WEIGHT_EXPERIENCE +
                certScore * WEIGHT_CERTIFIED +
                cityScore * 0.1);

            matches.add({
              ...normalizedGuide,
              'score': double.parse(totalScore.toStringAsFixed(3)),
              'breakdown': {
                'lang': (langScore * WEIGHT_LANGUAGE).toStringAsFixed(3),
                'dist': (distScore * WEIGHT_DISTANCE).toStringAsFixed(3),
                'price': (priceScore * WEIGHT_PRICE).toStringAsFixed(3),
                'rating': (ratingScore * WEIGHT_RATING).toStringAsFixed(3),
                'exp': (expScore * WEIGHT_EXPERIENCE).toStringAsFixed(3),
                'cert': (certScore * WEIGHT_CERTIFIED).toStringAsFixed(3),
              },
            });

            print(
              "✅ ${guide['name']}: Score = ${totalScore.toStringAsFixed(3)}",
            );
          } catch (e) {
            print("❌ Error processing ${guide['name']}: $e");
          }
        }

        // Sort by score (highest first)
        matches.sort((a, b) => b['score'].compareTo(a['score']));
        allGuides.sort((a, b) => b['score'].compareTo(a['score']));

        if (!mounted) return;
        setState(() {
          recommendedGuides = matches;
          fallbackGuides = allGuides.take(5).toList();
          _statusMessage = matches.isEmpty
              ? "No exact language match found. Showing closest available translators."
              : null;
          _isLoading = false;
        });

        print("🎯 Found ${matches.length} matching guides");
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(
          "Failed to fetch translators (${response.statusCode}). Please try again.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print("❌ Error: $e");
      _showError("Failed to fetch translators. Check backend and try again.");
    }
  }

  // 📍 Get coordinates from user location
  List<double> _getLocationCoords() {
    // Fetch from user data, default to Pune
    final lat =
        double.tryParse(widget.user['latitude']?.toString() ?? '18.5204') ??
        18.5204;
    final lon =
        double.tryParse(widget.user['longitude']?.toString() ?? '73.8567') ??
        73.8567;
    return [lat, lon];
  }

  // 📍 Extract coordinates from guide data
  List<double> _extractLocation(Map<String, dynamic> guide) {
    final lat =
        double.tryParse(guide['latitude']?.toString() ?? '18.5204') ?? 18.5204;
    final lon =
        double.tryParse(guide['longitude']?.toString() ?? '73.8567') ?? 73.8567;
    return [lat, lon];
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  List<String> _extractLanguages(Map<String, dynamic> guide) {
    final rawLanguages = guide['languages'] ?? guide['language'];

    if (rawLanguages is List) {
      return rawLanguages
          .whereType<String>()
          .map((language) => language.trim())
          .where((language) => language.isNotEmpty)
          .toList();
    }

    if (rawLanguages is String && rawLanguages.trim().isNotEmpty) {
      return rawLanguages
          .split(',')
          .map((language) => language.trim())
          .where((language) => language.isNotEmpty)
          .toList();
    }

    return [];
  }

  String _resolveProfileImage(dynamic imageValue) {
    final imagePath = (imageValue ?? '').toString().trim();

    if (imagePath.isEmpty) {
      return '';
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    return "${ApiConfig.rootUrl}/uploads/$imagePath";
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  Future<void> _callTranslator(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _whatsappTranslator(String phone, String name) async {
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}?text=Hi%20$name!%20I'd%20like%20to%20book%20your%20services",
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _requestBooking(Map<String, dynamic> guide) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (selectedDate == null) return;

    final String touristName = widget.user['name'] ?? 'Tourist';
    final int translatorId = guide['id'];
    final List guideLangs = guide['languages'] as List;
    final String language = guideLangs.isNotEmpty
        ? guideLangs.first.toString()
        : 'English';

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.translatorsBaseUrl}/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'translatorId': translatorId,
          'touristName': touristName,
          'bookingDate': selectedDate.toIso8601String().split('T')[0],
          'language': language,
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _pendingRequests.add(translatorId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking requested successfully! The translator can now review it in booking requests.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        String errorMessage = 'Failed to request booking.';
        try {
          final data = jsonDecode(response.body);
          if (data['error'] != null) errorMessage = data['error'];
        } catch (_) {}

        if (response.statusCode == 400 && errorMessage.contains('pending')) {
          setState(() {
            _pendingRequests.add(translatorId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recommended Guides")),
      body: Column(
        children: [
          _buildCriteriaPanel(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : recommendedGuides.isEmpty
                ? Center(child: _buildEmptyState())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: recommendedGuides.length,
                    itemBuilder: (context, index) {
                      final guide = recommendedGuides[index];
                      return _buildGuideCard(guide, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide, int rank) {
    final breakdown = guide['breakdown'] as Map<String, dynamic>;
    final score = guide['score'] as double;
    final imageUrl = (guide['profileImage'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.mutedSurface,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: AppColors.textPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '#$rank Match',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (guide['verified']) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            guide['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${guide['city']} • ₹${guide['rate_per_hour'].toStringAsFixed(0)}/hr',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        "${(score * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricPill(
                      Icons.language,
                      '${(guide['languages'] as List).length} languages',
                    ),
                    _metricPill(
                      Icons.star_rounded,
                      '${guide['rating'].toStringAsFixed(1)} rating',
                    ),
                    _metricPill(
                      Icons.reviews_outlined,
                      '${guide['reviews_count']} reviews',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pendingRequests.contains(guide['id'])
                        ? null
                        : () => _requestBooking(guide),
                    icon: Icon(
                      _pendingRequests.contains(guide['id'])
                          ? Icons.access_time
                          : Icons.calendar_today,
                    ),
                    label: Text(
                      _pendingRequests.contains(guide['id'])
                          ? "Request Pending"
                          : "Request Booking",
                    ),
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: AppColors.primaryLight,
                      disabledForegroundColor: AppColors.textMuted,
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _scoreChip("Lang", breakdown['lang']),
                      _scoreChip("Dist", breakdown['dist']),
                      _scoreChip("Price", breakdown['price']),
                      _scoreChip("Rating", breakdown['rating']),
                      _scoreChip("Exp", breakdown['exp']),
                      _scoreChip("Cert", breakdown['cert']),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (guide['bio'] as String).trim().isEmpty
                      ? 'Local translator available for guided travel support.'
                      : guide['bio'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (guide['languages'] as List)
                      .map(
                        (lang) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            lang.toString(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callTranslator(guide['phone']),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text("Call"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _whatsappTranslator(guide['phone'], guide['name']),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? "Failed to fetch translators",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              "You can retry, or open the full translator list while the matching service is unavailable.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchAndMatchTranslators,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TranslatorPage()),
                );
              },
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text("Browse Translators"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            "No guides matched your criteria",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchAndMatchTranslators,
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TranslatorPage()),
              );
            },
            icon: const Icon(Icons.people_alt_outlined),
            label: const Text("Browse All Translators"),
          ),
          if (fallbackGuides.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Closest Available",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(fallbackGuides.length, (index) {
              return _buildGuideCard(fallbackGuides[index], index + 1);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Match Criteria",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_cityController.text.trim().isEmpty ? 'Any city' : _cityController.text.trim()} • ₹${_selectedBudget.toStringAsFixed(0)}/hr • ${_selectedLanguages.length} languages',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _criteriaExpanded = !_criteriaExpanded;
                  });
                },
                icon: Icon(
                  _criteriaExpanded ? Icons.close_rounded : Icons.tune_rounded,
                ),
                label: Text(_criteriaExpanded ? 'Hide' : 'Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _compactSummaryChip(
                Icons.location_on_outlined,
                _cityController.text.trim().isEmpty
                    ? 'Any city'
                    : _cityController.text.trim(),
              ),
              _compactSummaryChip(
                Icons.currency_rupee,
                '₹${_selectedBudget.toStringAsFixed(0)}/hr',
              ),
              ..._selectedLanguages
                  .take(3)
                  .map(
                    (language) =>
                        _compactSummaryChip(Icons.translate_outlined, language),
                  ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _criteriaExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: "Preferred City",
                    prefixIcon: Icon(Icons.location_city_outlined),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => fetchAndMatchTranslators(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Budget up to ₹${_selectedBudget.toStringAsFixed(0)}/hr",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _selectedBudget,
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  label: _selectedBudget.toStringAsFixed(0),
                  onChanged: (value) {
                    setState(() => _selectedBudget = value);
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  "Preferred Languages",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languageOptions.map((language) {
                    final isSelected = _selectedLanguages.contains(language);
                    return FilterChip(
                      label: Text(language),
                      selected: isSelected,
                      selectedColor: AppColors.secondary.withValues(
                        alpha: 0.22,
                      ),
                      checkmarkColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedLanguages = [
                              ..._selectedLanguages,
                              language,
                            ];
                          } else {
                            _selectedLanguages = _selectedLanguages
                                .where((item) => item != language)
                                .toList();
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: fetchAndMatchTranslators,
                        icon: const Icon(Icons.search),
                        label: const Text("Find Translators"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _cityController.text = (widget.user['city'] ?? '')
                              .toString();
                          _selectedBudget =
                              double.tryParse(
                                widget.user['budget']?.toString() ?? '300',
                              ) ??
                              300;
                          _selectedLanguages =
                              ((widget.user['languages'] as List?) ??
                                      const ['English', 'Hindi'])
                                  .map((language) => language.toString())
                                  .where(
                                    (language) => language.trim().isNotEmpty,
                                  )
                                  .toList();
                        });
                        fetchAndMatchTranslators();
                      },
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactSummaryChip(IconData icon, String label) {
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Math helper (since Dart doesn't have Math.pow directly)
class Math {
  static double pow(double base, double exponent) {
    return base * base; // For distance calculation (power of 2)
  }

  static double sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0 || value == 1) return value;

    double x = value;
    double y = (x + 1) / 2;
    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }
    return x;
  }

  static double max(double a, double b) => a > b ? a : b;
  static double min(double a, double b) => a < b ? a : b;
}
