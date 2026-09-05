import 'dart:developer';
import 'dart:io' show File, Platform;

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ProofMediaItem {
  final String title;
  final String url;
  final bool isVideo;
  String? thumbnail;

  /// Names this piece of proof in a saved file: `<orderNumber>_<fileLabel>`.
  /// Unlike [title] it stays the same in both app languages, so a download
  /// made in Arabic is named like one made in English.
  final String fileLabel;

  ProofMediaItem({
    required this.title,
    required this.url,
    required this.isVideo,
    required this.fileLabel,
    this.thumbnail,
  });
}

class ProofMediaViewerPage extends StatefulWidget {
  final List<ProofMediaItem> mediaItems;
  final int initialIndex;

  /// Prefixes downloaded files so they can be traced back to their order.
  final String? orderNumber;

  const ProofMediaViewerPage({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
    this.orderNumber,
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

  /// Bridges to `MainActivity.saveToDownloads`. Android only; iOS has no
  /// folder a third party app may write into.
  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.rahiq.app/downloads',
  );

  /// `<orderNumber>_<label>.<ext>`, e.g. `10001268-4_mosque_front.jpg`.
  ///
  /// The extension is taken from the URL when it looks like one, since the
  /// name decides which app opens the file later; the media kind gives a sane
  /// default when the URL carries no extension (signed URLs often don't).
  String _fileNameFor(ProofMediaItem item) {
    final path = Uri.parse(item.url).path;
    final dot = path.lastIndexOf('.');
    final urlExtension = dot != -1 ? path.substring(dot + 1).toLowerCase() : '';
    final extension = RegExp(r'^[a-z0-9]{2,4}$').hasMatch(urlExtension)
        ? urlExtension
        : (item.isVideo ? 'mp4' : 'jpg');

    // Order numbers are plain like `10001268-4`, but anything a path or
    // MediaStore would choke on is stripped rather than trusted.
    final order = (widget.orderNumber ?? '').replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '',
    );
    final prefix = order.isEmpty ? '' : '${order}_';

    return '$prefix${item.fileLabel}.$extension';
  }

  String _mimeTypeFor(String fileName, bool isVideo) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return isVideo ? 'video/mp4' : 'image/jpeg';
    }
  }

  Future<void> _downloadCurrent() async {
    final item = widget.mediaItems[_currentIndex];
    final fileName = _fileNameFor(item);
    var isLoaderShowing = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: WaterLoadingIndicator(waveColor1: Colors.white),
        ),
      );
      isLoaderShowing = true;

      // Downloaded under its final name so that the share sheet fallback
      // offers the same name the Downloads copy would have had.
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      await Dio().download(item.url, tempPath);

      // Where a file can be put varies by platform, so each answers with the
      // message describing where the user will find it. A null means nothing
      // was kept and the share sheet has to take over.
      String? savedMessage;

      if (Platform.isAndroid) {
        final savedAs = await _downloadsChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'path': tempPath,
            'fileName': fileName,
            'mimeType': _mimeTypeFor(fileName, item.isVideo),
          },
        );
        if (savedAs != null && mounted) {
          savedMessage = AppLocalizations.of(context)!.saved_to_downloads;
        }
      } else if (Platform.isIOS) {
        // iOS has no shared Downloads folder a third party app may write into.
        // The app's own Documents folder is the closest equivalent: Info.plist
        // publishes it to the Files app, so the file shows up under
        // On My iPhone > Rahiq keeping the name it was given here.
        final documents = await getApplicationDocumentsDirectory();
        await File(tempPath).copy('${documents.path}/$fileName');
        if (mounted) {
          savedMessage = AppLocalizations.of(context)!.saved_to_files;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // hide loading
      isLoaderShowing = false;

      if (savedMessage != null) {
        CustomSnackbar.show(context: context, message: savedMessage);
        return;
      }

      // Android 9 and older, where writing to Downloads needs a storage
      // permission this app does not ask for: hand the named file to the
      // system sheet so it can still be kept somewhere.
      await SharePlus.instance.share(ShareParams(files: [XFile(tempPath)]));
    } catch (e) {
      log('Failed to download proof media: $e', name: 'ProofMediaViewer');
      if (!mounted) return;
      if (isLoaderShowing) Navigator.pop(context); // hide loading
      CustomSnackbar.show(
        context: context,
        isError: true,
        message: AppLocalizations.of(context)!.download_failed,
      );
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
            tooltip: AppLocalizations.of(context)!.download,
          ),
        ],
      ),
      body: Column(
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
