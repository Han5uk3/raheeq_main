import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:video_player/video_player.dart';

class ProofMediaItem {
  final String title;
  final String url;
  final bool isVideo;

  ProofMediaItem({
    required this.title,
    required this.url,
    required this.isVideo,
  });
}

class ProofMediaViewerPage extends StatefulWidget {
  final List<ProofMediaItem> mediaItems;
  final int initialIndex;

  const ProofMediaViewerPage({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
  });

  @override
  State<ProofMediaViewerPage> createState() => _ProofMediaViewerPageState();
}

class _ProofMediaViewerPageState extends State<ProofMediaViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    final url = widget.mediaItems[_currentIndex].url;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: WaterLoadingIndicator(waveColor1: Colors.white),
        ),
      );

      final uri = Uri.parse(url);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'downloaded_file';
      
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      
      final dio = Dio();
      await dio.download(url, filePath);
      
      if (mounted) Navigator.pop(context); // hide loading
      
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download file')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text("", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.mediaItems[_currentIndex].title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton.filled(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadCurrent,
            tooltip: 'Download',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.mediaItems[index];
                  if (item.isVideo) {
                    return _VideoPlayerItem(url: item.url);
                  } else {
                    return InteractiveViewer(
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: item.url,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: WaterLoadingIndicator(
                              waveColor1: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            if (widget.mediaItems.length > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.mediaItems.length, (index) {
                  bool isActive = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: isActive ? 32 : 12,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final String url;
  const _VideoPlayerItem({required this.url});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {});
              _controller.play();
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _isError = true;
              });
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Text(
          "Failed to load video",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(
        child: WaterLoadingIndicator(waveColor1: Colors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
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
