import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mediapipe_audio/mediapipe_audio.dart';

import 'speech_playback.dart';
import 'kokoro_voices.dart';

void main() {
  ModelStore.allowDownloads = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.speech});

  final SpeechPlayback? speech;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '文字朗读',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(speech: speech),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.speech});

  final SpeechPlayback? speech;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _textController = TextEditingController(
    text:
        '你好，欢迎使用文字朗读。今天也是美好的一天，愿你保持好奇，发现生活中的小惊喜。'
        '你可以修改这段文字，然后点击朗读，听听它的声音。',
  );
  late final SpeechPlayback _speech = widget.speech ?? KokoroSpeechPlayback();
  bool _busy = false;
  bool _gpuSupported = false;
  bool _checkingGpu = true;
  String? _gpuDetectionError;
  String _voiceId = kokoroChineseVoices.first.id;
  String? _error;
  bool _hasStartedReading = false;
  SpeechSynthesisStats? _synthesisStats;
  Duration? _preparationElapsed;
  String _status = '点击朗读，听听这段文字的声音';

  @override
  void initState() {
    super.initState();
    unawaited(_checkGpuSupport());
  }

  Future<void> _checkGpuSupport() async {
    if (mounted) {
      setState(() {
        _checkingGpu = true;
        _gpuDetectionError = null;
      });
    }
    var supported = false;
    String? detectionError;
    try {
      supported = await _speech.supportsGpu();
    } catch (error) {
      debugPrint('检测 GPU 支持失败: $error');
      detectionError = '暂时无法检测 GPU 支持，无法使用朗读功能。';
    }
    if (mounted) {
      setState(() {
        _gpuSupported = supported;
        _gpuDetectionError = detectionError;
        _checkingGpu = false;
      });
    }
  }

  Future<void> _readAloud() async {
    final text = _textController.text.trim();
    if (_busy || _checkingGpu || !_gpuSupported || text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _hasStartedReading = true;
      _synthesisStats = null;
      _preparationElapsed = null;
      _status = '正在准备模型，首次加载可能需要一些时间…';
    });
    try {
      await _speech.speak(
        text,
        voiceId: _voiceId,
        onPrepared: (_, elapsed) {
          if (mounted) {
            setState(() {
              _preparationElapsed = elapsed;
              _status = '正在生成语音…';
            });
          }
        },
        onSynthesized: (stats) {
          if (mounted) {
            setState(() {
              _synthesisStats = stats;
            });
          }
        },
        onPlaying: () {
          if (mounted) setState(() => _status = '正在朗读…');
        },
      );
      if (mounted) setState(() => _status = '朗读完成');
    } catch (error, stack) {
      debugPrint('朗读失败: $error\n$stack');
      if (mounted) {
        setState(() {
          _error = '朗读失败，请重试。若多次失败，请尝试缩短文字或重新打开应用。';
          _status = '未能完成朗读';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  String _seconds(Duration duration) =>
      '${(duration.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(2)} 秒';

  @override
  void dispose() {
    _textController.dispose();
    unawaited(
      _speech.dispose().catchError((Object error) {
        debugPrint('释放语音资源失败: $error');
      }),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingGpu || !_gpuSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('文字朗读')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _checkingGpu ? Icons.memory : Icons.block,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _checkingGpu
                          ? '正在检测 GPU 支持…'
                          : (_gpuDetectionError != null
                                ? 'GPU 检测失败'
                                : '暂不支持此设备'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _checkingGpu
                          ? '请稍候，正在检查运行环境。'
                          : (_gpuDetectionError ??
                                '此设备或运行环境不支持当前语音模型的 GPU 加速，暂时无法使用朗读功能。'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('文字朗读')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '把文字读给你听',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('输入想听的内容，使用中文语音在本地朗读。'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    minLines: 6,
                    maxLines: 12,
                    maxLength: 500,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: '朗读内容',
                      hintText: '在这里输入文字…',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _voiceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '中文发音人',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final voice in kokoroChineseVoices)
                        DropdownMenuItem(
                          value: voice.id,
                          child: Text(voice.label),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (voiceId) {
                            if (voiceId != null) {
                              setState(() {
                                _voiceId = voiceId;
                                _error = null;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed:
                        _busy ||
                            _checkingGpu ||
                            _textController.text.trim().isEmpty
                        ? null
                        : _readAloud,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('朗读'),
                  ),
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: Text(_status)),
                  if (_hasStartedReading) ...[
                    const SizedBox(height: 12),
                    Text(
                      _preparationElapsed == null
                          ? (_busy ? '模型准备耗时：准备中…' : '模型准备耗时：未完成')
                          : '模型准备耗时：${_seconds(_preparationElapsed!)}',
                    ),
                    Text(
                      _synthesisStats == null
                          ? (_busy
                                ? (_preparationElapsed == null
                                      ? '语音生成耗时：等待模型准备'
                                      : '语音生成耗时：生成中…')
                                : '语音生成耗时：未完成')
                          : '语音生成耗时：${_seconds(_synthesisStats!.synthesis)}',
                    ),
                    if (_synthesisStats != null)
                      Text('语音时长：${_seconds(_synthesisStats!.audioDuration)}'),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
