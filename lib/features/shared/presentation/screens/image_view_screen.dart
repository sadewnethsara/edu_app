import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:math/features/social/feed/widgets/social_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class ImageViewScreen extends StatefulWidget {
  final List<String>? imageUrls;
  final List<ImageProvider>? imageProviders;
  final String? videoUrl;
  final int initialIndex;
  final String heroTagPrefix;

  const ImageViewScreen({
    super.key,
    this.imageUrls,
    this.imageProviders,
    this.videoUrl,
    this.initialIndex = 0,
    required this.heroTagPrefix,
  });

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.videoUrl != null; // Determine if there's a video
    final imageCount =
        widget.imageUrls?.length ?? widget.imageProviders?.length ?? 0;
    final totalCount = (hasVideo ? 1 : 0) + imageCount;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Prevent resize on keyboard (if any)
      body: Dismissible(
        key: const Key('image_view_dismissible'),
        direction: DismissDirection.vertical,
        onDismissed: (_) => Navigator.of(context).pop(),
        resizeDuration: const Duration(milliseconds: 100),
        movementDuration: const Duration(milliseconds: 200),
        background: const ColoredBox(color: Colors.transparent),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                if (hasVideo && index == 0) {
                  return Center(
                    child: SocialVideoPlayer(
                      videoUrl: widget.videoUrl!,
                      autoPlay: true,
                    ),
                  );
                }

                final imageIndex = hasVideo ? index - 1 : index;
                final imageProvider = widget.imageUrls != null
                    ? CachedNetworkImageProvider(widget.imageUrls![imageIndex])
                    : widget.imageProviders![imageIndex];

                return Hero(
                  tag: '${widget.heroTagPrefix}_$imageIndex',
                  child: PhotoView(
                    imageProvider: imageProvider,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2.5,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent, // Allow scaffold interaction
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 50,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (totalCount > 1)
              Positioned(
                bottom: 40,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(totalCount, (index) {
                        final isSelected = _currentIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
