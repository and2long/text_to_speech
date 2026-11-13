import 'package:mediapipe_core/mediapipe_core.dart';

/// GPU-optimized vocoder, selected only for a GPU task.
const kokoroGpuModel = DownloadAsset(
  url:
      'https://huggingface.co/litert-community/Kokoro-82M/resolve/'
      '33ad69fec6c4d9eb10a547aaf9a8c63e7c446a56/'
      'kokoro_int8_gpu_fp16.litertlm',
  sha256: '1ef178b127ec48c737daf17eabb4cea5f6b3ffbc510aced270fe5c267bbeac52',
);
