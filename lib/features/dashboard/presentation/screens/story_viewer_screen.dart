import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/widgets/smart_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../../deals/presentation/screens/deal_list_screen.dart';
import '../controllers/story_view_state.dart';

class StoryViewerArgs {
  const StoryViewerArgs({
    required this.group,
    this.initialIndex = 0,
    this.allGroups,
    this.groupIndex = 0,
  });

  final StoryGroup group;
  final int initialIndex;
  final List<StoryGroup>? allGroups; // All available story groups
  final int groupIndex; // Current group index in allGroups
}

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.args});

  static const routePath = '/stories/view';
  static const routeName = 'storyViewer';

  final StoryViewerArgs args;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late int _currentIndex;
  late int _currentGroupIndex;
  late StoryGroup _currentGroup;
  late List<double> _progress; // Progress for each story (0.0 to 1.0)
  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _isPaused = false;

  static const Duration _imageDuration = Duration(seconds: 5);
  static const Duration _timerInterval = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.args.initialIndex;
    _currentGroupIndex = widget.args.groupIndex;
    _currentGroup = widget.args.group;
    _progress = List.filled(_currentGroup.stories.length, 0.0);
    // Mark initial story group as viewed (pass ID directly to ensure correct value)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markCurrentGroupAsViewed(_currentGroup.wholesalerId);
    });
    _loadStory(_currentIndex);
  }

  void _markCurrentGroupAsViewed([String? wholesalerId]) {
    final id = wholesalerId ?? _currentGroup.wholesalerId;
    if (id.isNotEmpty) {
      // Mark as viewed (fire and forget - async operation)
      ref.read(storyViewStateProvider.notifier).markViewed(id).catchError((e) {
        debugPrint('Failed to mark story as viewed: $e');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(int index) {
    _timer?.cancel();
    _videoController?.dispose();
    _videoController = null;
    if (isPushBackInvoked) return;

    if (index < 0 || index >= _currentGroup.stories.length) {
      // All stories in current group viewed
      if (index >= _currentGroup.stories.length) {
        // Try to load next wholesaler's stories
        _loadNextWholesaler("Load Story!");
      } else {
        // Going back before first story, exit
        if (mounted) {
          isPushBackInvoked = true;
          Navigator.of(context).pop();
        }
      }
      return;
    }

    setState(() {
      _currentIndex = index;
      _isPaused = false;
      _progress[_currentIndex] = 0.0;
    });

    final story = _currentGroup.stories[index];

    if (story.isVideo) {
      _loadVideo(story.mediaUrl);
    } else {
      _startImageTimer();
    }
  }

  void _loadPreviousWholesaler() {
    if (isPushBackInvoked) return;
    final allGroups = widget.args.allGroups;
    debugPrint(
        'Loading previous wholesaler currentIndex : $_currentGroupIndex Group Size : ${allGroups?.length}');
    if (allGroups == null || _currentGroupIndex <= 0) {
      debugPrint('No more wholesalers, Pushing Back');
      // No more wholesalers, exit
      if (mounted) {
        isPushBackInvoked = true;
        Navigator.of(context).pop();
      }
      return;
    }

    final previousGroupIndex = _currentGroupIndex - 1;
    final previousGroup = allGroups[previousGroupIndex];

    if (previousGroup.stories.isEmpty) {
      // Skip empty groups
      setState(() {
        _currentGroupIndex = previousGroupIndex;
      });
      _loadPreviousWholesaler(); // Recursively find previous non-empty group
      return;
    }

    // Load the LAST story of the previous wholesaler
    final lastStoryIndex = previousGroup.stories.length - 1;

    setState(() {
      _currentGroupIndex = previousGroupIndex;
      _currentGroup = previousGroup;
      _currentIndex = lastStoryIndex;
      _progress = List.filled(previousGroup.stories.length, 0.0);
      // Mark all previous stories as completed
      for (int i = 0; i < lastStoryIndex; i++) {
        _progress[i] = 1.0;
      }
    });

    // Mark previous wholesaler's story group as viewed (pass ID directly to avoid timing issues)
    _markCurrentGroupAsViewed(previousGroup.wholesalerId);
    _loadStory(lastStoryIndex);
  }

  bool isPushBackInvoked = false;
  void _loadNextWholesaler(String? caller) {
    if (isPushBackInvoked) return;
    final allGroups = widget.args.allGroups;
    debugPrint(
        'Loading next wholesaler currentIndex : $_currentGroupIndex Group Size : ${allGroups?.length} By $caller');
    if (allGroups == null || _currentGroupIndex >= (allGroups.length - 1)) {
      debugPrint('No more wholesalers, Pushing Back');
      // No more wholesalers, exit
      if (mounted) {
        isPushBackInvoked = true;
        Navigator.of(context).pop();
        return;
      }
    }

    if (allGroups == null) {
      isPushBackInvoked = true;
      Navigator.of(context).pop();
      return;
    }

    // Move to next wholesaler
    final nextGroupIndex = _currentGroupIndex + 1;
    final nextGroup = allGroups[nextGroupIndex];

    if (nextGroup.stories.isEmpty) {
      // Skip empty groups
      setState(() {
        _currentGroupIndex = nextGroupIndex;
      });
      _loadNextWholesaler("It Self");
      return;
    }

    setState(() {
      _currentGroupIndex = nextGroupIndex;
      _currentGroup = nextGroup;
      _currentIndex = 0;
      _progress = List.filled(nextGroup.stories.length, 0.0);
    });

    // Mark next wholesaler's story group as viewed (pass ID directly to avoid timing issues)
    _markCurrentGroupAsViewed(nextGroup.wholesalerId);
    _loadStory(0);
  }

  void _loadVideo(String url) {
    final uri = _normalizeMediaUri(url);
    _videoController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        if (!mounted) return;
        if (_videoController?.value.hasError == true) {
          debugPrint(
              'Video error: ${_videoController?.value.errorDescription}');
          // Skip to next story on error
          _goToNext();
          return;
        }
        setState(() {});
        _videoController?.play();
        _startVideoTimer();
      }).catchError((error) {
        debugPrint('Video load error: $error');
        if (mounted) _goToNext();
      });
  }

  void _startImageTimer() {
    _timer = Timer.periodic(_timerInterval, (timer) {
      if (_isPaused) return;

      setState(() {
        _progress[_currentIndex] +=
            _timerInterval.inMilliseconds / _imageDuration.inMilliseconds;
        if (_progress[_currentIndex] >= 1.0) {
          _progress[_currentIndex] = 1.0;
          timer.cancel();
          _goToNext();
        }
      });
    });
  }

  void _startVideoTimer() {
    _timer = Timer.periodic(_timerInterval, (timer) {
      if (_isPaused || _videoController == null) return;

      final position = _videoController!.value.position.inMilliseconds;
      final duration = _videoController!.value.duration.inMilliseconds;

      if (duration > 0) {
        setState(() {
          _progress[_currentIndex] = position / duration;
        });

        if (_videoController!.value.position >=
            _videoController!.value.duration) {
          timer.cancel();
          _goToNext();
        }
      }
    });
  }

  void _goToPrevious() {
    debugPrint('Going to previous story');
    if (_currentIndex > 0) {
      _progress[_currentIndex] = 0.0;
      _loadStory(_currentIndex - 1);
    } else {
      _loadPreviousWholesaler();
    }
  }

  void _goToNext() {
    debugPrint('Going to next story');
    if (_currentIndex < _currentGroup.stories.length - 1) {
      _progress[_currentIndex] = 1.0;
      _loadStory(_currentIndex + 1);
    } else {
      // Last story of current wholesaler, move to next wholesaler
      _progress[_currentIndex] = 1.0;
      _loadNextWholesaler("Go Next Story");
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _videoController?.pause();
    } else {
      _videoController?.play();
    }
  }

  Uri _normalizeMediaUri(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Uri.parse(url);
    if (uri.scheme.toLowerCase() == 'http') {
      return uri.replace(scheme: 'https');
    }
    return uri;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final story = _currentGroup.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          // Tap on left 1/3 = previous, right 1/3 = next, middle = pause
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;

          if (tapPosition < screenWidth / 3) {
            _goToPrevious();
          } else if (tapPosition > screenWidth * 2 / 3) {
            _goToNext();
          } else {
            _togglePause();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Content
            SizedBox.expand(
              child: _buildStoryContent(story),
            ),

            // Progress Bars at Top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _StoryProgressBars(
                  storyCount: _currentGroup.stories.length,
                  currentIndex: _currentIndex,
                  progress: _progress,
                ),
              ),
            ),

            // Header with wholesaler info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          _currentGroup.wholesalerName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentGroup.wholesalerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _timeAgo(story.expiresAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          isPushBackInvoked = true;
                          Navigator.of(context).pop();
                          context.push(
                            DealListScreen.routePath,
                            extra: {
                              'wholesalerId': _currentGroup.wholesalerId,
                              'title':
                                  'Deals from ${_currentGroup.wholesalerName}',
                            },
                          );
                        },
                        icon:
                            const Icon(Icons.local_offer, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pause indicator
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.pause_circle_outline,
                  size: 80,
                  color: Colors.white70,
                ),
              ),

            // Product/Deal Card Overlay (WhatsApp-style)
            if (story.product != null || story.deal != null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _buildProductDealCard(story),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryMedia story) {
    if (story.isVideo) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      }
      if (_videoController!.value.hasError) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // Image story (use SmartNetworkImage to handle data: URIs from API)
    return SmartNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 64, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildProductDealCard(StoryMedia story) {
    // Determine if it's a product or deal
    final isProduct = story.product != null;
    final isDeal = story.deal != null;

    if (!isProduct && !isDeal) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Pause story when tapping card
        setState(() => _isPaused = true);

        if (isProduct) {
          context.push('/products/${story.product!.id}').then((_) {
            // Resume when returning
            if (mounted) setState(() => _isPaused = false);
          });
        } else if (isDeal) {
          context.push('/deals/${story.deal!.id}').then((_) {
            // Resume when returning
            if (mounted) setState(() => _isPaused = false);
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product/Deal Image (use SmartNetworkImage to handle data: URIs)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SmartNetworkImage(
                    imageUrl: isProduct
                        ? story.product!.imageUrl
                        : (story.deal!.images?.isNotEmpty ?? false)
                            ? story.deal!.images!.first
                            : '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image, color: Colors.white54),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[800],
                      child:
                          const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product/Deal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon + Label
                      Row(
                        children: [
                          Icon(
                            isProduct ? Icons.shopping_bag : Icons.local_offer,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProduct ? 'Product' : 'Deal',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        isProduct ? story.product!.title : story.deal!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Price (EUR primary + USD indicator)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProduct
                                ? context
                                    .formatPriceEurOnly(story.product!.price)
                                : context
                                    .formatPriceEurOnly(story.deal!.dealPrice),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isProduct
                                ? '(${context.formatPriceUsdFromEur(story.product!.price)})'
                                : '(${context.formatPriceUsdFromEur(story.deal!.dealPrice)})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress bars at the top showing progress for each story
class _StoryProgressBars extends StatelessWidget {
  const _StoryProgressBars({
    required this.storyCount,
    required this.currentIndex,
    required this.progress,
  });

  final int storyCount;
  final int currentIndex;
  final List<double> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(
          storyCount,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ProgressBar(
                progress: _getProgressForIndex(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getProgressForIndex(int index) {
    if (index < currentIndex) {
      return 1.0; // Completed stories
    } else if (index == currentIndex) {
      return progress[index].clamp(0.0, 1.0); // Current story
    } else {
      return 0.0; // Upcoming stories
    }
  }
}

/// Individual progress bar
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
