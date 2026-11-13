# text_to_speech

使用 Kokoro GPU 模型进行本地文字转语音的 Flutter 应用。

## 模型打包

```sh
flutter pub get
dart run tool/bundle_kokoro.dart
dart run tool/bundle_kokoro.dart --check
```

仅打包 `kokoro_int8_gpu_fp16.litertlm`（约 295 MB），固定 URL、版本和 SHA-256
定义在 `lib/kokoro_model.dart`。脚本下载并验证 GPU 模型、生成资源清单，并移除旧 CPU 模型资源。
`pubspec.yaml` 的 `assets/mediapipe/` 会将模型打包进 App，运行时不下载模型。
模型权重不提交到 Git；首次克隆项目后运行上述打包命令恢复本地模型。资源清单和下载脚本保留在仓库中。
模型已存在且校验通过时会直接复用，不会重复下载。macOS 的 `./script/build_and_run.sh`
会自动获取依赖并补齐模型；直接使用 `flutter run`、Android/iOS 构建或 Xcode 构建前，先执行上述命令。
最终发布的 App 安装包自带模型，普通用户安装后无需另行下载。
不要运行包的 `mediapipe_core:bundle_models` 命令，它会覆盖项目的模型清单。
模型使用 Apache 2.0 许可，分发时保留相应许可及声明。

## 运行环境

启动时检测 GPU 支持，检测期间显示等待页面：

- 支持 GPU：进入文字朗读首页。
- 不支持 GPU：显示独立的“不支持此设备”页面，不提供文字输入或朗读功能。
- 检测失败：显示检测失败提示页面。

当前支持 macOS 15+ Apple Silicon、iOS 16+ arm64 真机，以及提供 OpenCL GPU 驱动的 Android arm64 真机（Android 9+）。
Android 启动时实际查询 OpenCL 平台和 GPU 设备；没有可访问驱动时显示不支持页面。
AndroidManifest 已声明可选的 OpenCL 原生库，供 Android 12+ 访问厂商驱动。
iOS 模拟器和没有 OpenCL 驱动的 Android 模拟器显示不支持页面。
项目使用 `vendor/mediapipe_audio` 中的 0.3.0 本地修复版，详情见该目录的 `LOCAL_PATCHES.md`。
应用仅创建 GPU delegate，不再提供 CPU 模型或 CPU 切换选项。
Kokoro 的 GPU 路径主要加速声码器，声学模型仍会使用 CPU。

## 首页

首页预填中文示例，提供最多 500 字的输入框、中文发音人下拉选择器和朗读按钮。
默认 Xiaobei，其他声音包括 Xiaoni、Xiaoxiao、Xiaoyi、Yunjian、Yunxi、Yunxia、Yunyang。
点击朗读后按钮禁用，保留“朗读”文字与喇叭图标。

先显示模型准备耗时，生成后显示语音生成耗时及实际语音时长；播放结束后保留显示。
音频通过 `audioplayers` 播放，合成结果转换为 16-bit PCM WAV，部分平台使用临时文件。

`lib/kokoro_tts.dart` 的 `createKokoroTts()` 提供 GPU 模型初始化入口；复用实例，使用完毕后调用 `dispose()`。

macOS 本地构建并启动：`./script/build_and_run.sh`。
按照当前项目约定，不包含单元测试；设备端效果由手动运行验证。

参考：[mediapipe_audio](https://pub.dev/packages/mediapipe_audio)、
[Kokoro 模型](https://huggingface.co/litert-community/Kokoro-82M)。
