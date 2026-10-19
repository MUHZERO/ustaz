import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:md_player_android/md_player_android.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

abstract class VideoSource {
  Future<void> init(String youtubeId, Duration startAt);
  Stream<Duration> get position;
  void pause();
  Widget view();
  Future<void> dispose();

  factory VideoSource.forPlatform() =>
      Platform.isIOS ? IframeSource() : MdPlayerSource();
}

class MdPlayerSource implements VideoSource {
  MdPlayerController? _controller;
  final _positions = StreamController<Duration>.broadcast();

  void _emitPosition() {
    final controller = _controller;
    if (controller != null && !_positions.isClosed) {
      _positions.add(controller.value.position);
    }
  }

  @override
  Stream<Duration> get position => _positions.stream;

  @override
  Future<void> init(String youtubeId, Duration startAt) async {
    final controller = MdPlayerController.network(
      'https://www.youtube.com/watch?v=$youtubeId',
    );
    _controller = controller;
    controller.addListener(_emitPosition);
    await controller.initialize();
    await controller.seekTo(startAt);
  }

  @override
  void pause() => _controller?.pause();

  @override
  Widget view() => _controller == null
      ? const SizedBox.shrink()
      : MdPlayer(controller: _controller!);

  @override
  Future<void> dispose() async {
    _controller?.removeListener(_emitPosition);
    await _controller?.dispose();
    await _positions.close();
  }
}

class IframeSource implements VideoSource {
  YoutubePlayerController? _controller;

  @override
  Stream<Duration> get position =>
      _controller?.videoStateStream.map((state) => state.position) ??
      const Stream<Duration>.empty();

  @override
  Future<void> init(String youtubeId, Duration startAt) async {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: youtubeId,
      startSeconds: startAt.inSeconds.toDouble(),
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        privacyEnhancedMode: true,
      ),
    );
  }

  @override
  void pause() => _controller?.pauseVideo();

  @override
  Widget view() => _controller == null
      ? const SizedBox.shrink()
      : YoutubePlayer(controller: _controller!);

  @override
  Future<void> dispose() => _controller?.close() ?? Future<void>.value();
}
