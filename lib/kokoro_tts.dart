import 'package:mediapipe_audio/mediapipe_audio.dart';

import 'kokoro_model.dart';

/// Loads the bundled Kokoro model. Reuse the task and dispose it after use.
/// Results contain PCM samples; the caller handles playback separately.
Future<TextToSpeech> createKokoroTts() async {
  ModelStore.allowDownloads = false;
  return TextToSpeech.create(
    TextToSpeechOptions(
      model: kokoroGpuModel,
      delegate: Delegate.gpu,
      defaultVoiceId: 'zf_xiaobei',
    ),
  );
}
