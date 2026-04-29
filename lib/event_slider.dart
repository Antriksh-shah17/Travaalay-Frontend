import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traavaalay/Model/event.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

class EventSlider extends StatefulWidget {
  final List<Event> events;
  final List<String> defaultMedia;

  const EventSlider({
    super.key,
    required this.events,
    required this.defaultMedia,
  });

  @override
  State<EventSlider> createState() => _EventSliderState();
}

class _EventSliderState extends State<EventSlider> {
  int _currentIndex = 0;
  final Map<String, VideoPlayerController> _videoControllers = {};

  List<Event> get _slides => widget.events.isNotEmpty
      ? widget.events
      : widget.defaultMedia
            .map(
              (url) => Event(
                title: "",
                description: "",
                date: DateTime.now(),
                mediaPath: url,
              ),
            )
            .toList();

  @override
  void initState() {
    super.initState();
    _syncVideoControllers();
  }

  @override
  void didUpdateWidget(covariant EventSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncVideoControllers();
  }

  void _syncVideoControllers() {
    final activeMediaPaths = _slides.map((slide) => slide.mediaPath).toSet();

    final stalePaths = _videoControllers.keys
        .where((path) => !activeMediaPaths.contains(path))
        .toList();
    for (final path in stalePaths) {
      _videoControllers.remove(path)?.dispose();
    }

    for (final slide in _slides) {
      final path = slide.mediaPath;
      if (!_looksLikeVideo(path) || _videoControllers.containsKey(path)) {
        continue;
      }

      final controller = path.startsWith('assets/')
          ? VideoPlayerController.asset(path)
          : VideoPlayerController.networkUrl(Uri.parse(path));

      _videoControllers[path] = controller;
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (!mounted) return;
          _updatePlayback();
          setState(() {});
        });
    }

    _updatePlayback();
  }

  void _updatePlayback() {
    final currentPath = _currentIndex < _slides.length
        ? _slides[_currentIndex].mediaPath
        : null;

    _videoControllers.forEach((path, controller) {
      if (!controller.value.isInitialized) return;
      if (path == currentPath) {
        controller.play();
      } else {
        controller.pause();
      }
    });
  }

  bool _looksLikeVideo(String path) {
    final normalized = path.toLowerCase();
    return normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.m4v') ||
        normalized.endsWith('.webm');
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          itemBuilder: (context, index, realIndex) {
            final slide = slides[index];

            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MediaSlide(
                    mediaPath: slide.mediaPath,
                    controller: _videoControllers[slide.mediaPath],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  if (slide.title.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(slide.date),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              _updatePlayback();
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _currentIndex == index ? 20 : 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: _currentIndex == index
                    ? AppColors.secondary
                    : AppColors.textMuted,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MediaSlide extends StatefulWidget {
  final String mediaPath;
  final VideoPlayerController? controller;

  const _MediaSlide({required this.mediaPath, this.controller});

  @override
  State<_MediaSlide> createState() => _MediaSlideState();
}

class _MediaSlideState extends State<_MediaSlide> {
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = _looksLikeVideo(widget.mediaPath);
  }

  @override
  void didUpdateWidget(covariant _MediaSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isVideo = _looksLikeVideo(widget.mediaPath);
  }

  bool _looksLikeVideo(String path) {
    final normalized = path.toLowerCase();
    return normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.m4v') ||
        normalized.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      final controller = widget.controller;
      if (controller == null || !controller.value.isInitialized) {
        return Container(
          color: AppColors.mutedSurface,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    if (widget.mediaPath.startsWith('assets/')) {
      return Image.asset(widget.mediaPath, fit: BoxFit.cover);
    }

    return Image.network(
      widget.mediaPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.mutedSurface,
          child: const Center(
            child: Icon(Icons.image_not_supported, color: AppColors.textMuted),
          ),
        );
      },
    );
  }
}
