# Local changes to mediapipe_audio 0.3.0

Source: https://pub.dev/packages/mediapipe_audio/versions/0.3.0

The upstream TTS capability table allowed Metal only on macOS, even though
the official iOS sample supports Kokoro's GPU vocoder on physical iOS devices:
https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/text_to_speech/ios

`lib/src/capabilities.dart` adds `ios/arm64` with minimum iOS 16 to the TTS
GPU targets and explicitly excludes iOS Simulator. Both the capability query
and `TextToSpeech.create` use this table. The existing GPU model-section check,
native delegate plumbing and pinned MediaPipe 1.2.3 libraries are unchanged.

Android arm64 is also enabled for Kokoro's OpenCL GPU path, as supported by the
official Android sample:
https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/text_to_speech/android

`queryTextToSpeechCapabilities` checks `clGetPlatformIDs` and `clGetDeviceIDs`
through the exposed OpenCL driver before declaring Android GPU available.
CPU OpenCL devices do not qualify. Web and non-Android targets do not run the
probe. Android x86 emulators and 32-bit targets remain outside the GPU table.
The app's AndroidManifest declares optional `libOpenCL.so` and
`libOpenCL-pixel.so` libraries for Android 12+ vendor-library visibility.
Driver discovery alone does not guarantee successful model delegation; the
device's LiteRT/OpenCL compatibility still requires manual validation.

This package is vendored so the fix survives dependency resolution and CI.
Keep upstream LICENSE and NOTICE. Review this patch when upgrading upstream.

