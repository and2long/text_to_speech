import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:mediapipe_audio/mediapipe_audio.dart';

import 'audio_platform_io.dart'
    if (dart.library.js_interop) 'audio_platform_web.dart';
import 'kokoro_tts.dart';
import 'wav_encoder.dart';

abstract interface class SpeechPlayback {
  Future<bool> supportsGpu();

  Future<void> speak(
    String text, {
    required String voiceId,
    required void Function(Delegate delegate, Duration elapsed) onPrepared,
    required void Function(SpeechSynthesisStats stats) onSynthesized,
    required void Function() onPlaying,
  });
  Future<void> dispose();
}

class SpeechSynthesisStats {
  const SpeechSynthesisStats({
    required this.delegate,
    required this.initialization,
    required this.synthesis,
    required this.audioDuration,
  });

  final Delegate delegate;
  final Duration initialization;
  final Duration synthesis;
  final Duration audioDuration;
}

class KokoroSpeechPlayback implements SpeechPlayback {
  TextToSpeech? _tts;
  AudioPlayer? _player;
  bool _disposed = false;
  Completer<void>? _playback;

  @override
  Future<bool> supportsGpu() async => (await queryTextToSpeechCapabilities())
      .supportedDelegates
      .contains(Delegate.gpu);

  @override
  Future<void> speak(
    String text, {
    required String voiceId,
    required void Function(Delegate delegate, Duration elapsed) onPrepared,
    required void Function(SpeechSynthesisStats stats) onSynthesized,
    required void Function() onPlaying,
  }) async {
    if (_disposed) throw StateError('语音服务已关闭');
    final initialization = Stopwatch()..start();
    final tts = _tts ??= await createKokoroTts();
    initialization.stop();
    if (_disposed) {
      await tts.dispose();
      return;
    }
    onPrepared(tts.delegate, initialization.elapsed);
    final synthesis = Stopwatch()..start();
    final result = await tts.synthesize(text, voiceId: voiceId);
    synthesis.stop();
    if (_disposed) return;
    if (result.samples.isEmpty) throw StateError('未生成音频，请检查输入文字');
    onSynthesized(
      SpeechSynthesisStats(
        delegate: tts.delegate,
        initialization: initialization.elapsed,
        synthesis: synthesis.elapsed,
        audioDuration: Duration(
          microseconds:
              (result.samples.length *
                      Duration.microsecondsPerSecond /
                      result.sampleRateHz)
                  .round(),
        ),
      ),
    );
    await prepareAudioPlayback();
    if (_disposed) return;
    final player = _player ??= AudioPlayer();
    final completion = Completer<void>();
    _playback = completion;
    final subscription = player.onPlayerComplete.listen(
      (_) {
        if (!completion.isCompleted) completion.complete();
      },
      onError: (Object error, StackTrace stack) {
        if (!completion.isCompleted) completion.completeError(error, stack);
      },
    );
    // Attach the completion listener before playback, including very short clips.
    try {
      await Future.wait<void>([
        player
            .play(
              BytesSource(
                encodeWav(result.samples, result.sampleRateHz),
                mimeType: 'audio/wav',
              ),
            )
            .then((_) {
              if (!_disposed) onPlaying();
            }),
        completion.future,
      ], eagerError: true);
    } finally {
      await subscription.cancel();
      _playback = null;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _tts?.cancel();
    final playback = _playback;
    if (playback != null && !playback.isCompleted) playback.complete();
    try {
      await _player?.dispose();
    } finally {
      await _tts?.dispose();
    }
  }
}
