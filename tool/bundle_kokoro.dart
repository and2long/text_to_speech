import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mediapipe_core/mediapipe_core.dart';

import 'package:text_to_speech/kokoro_model.dart';

// Bundle the official GPU variant using ModelStore's verified downloader.
Future<void> main(List<String> arguments) async {
  if (arguments.any((arg) => arg != '--check')) {
    stderr.writeln('Usage: dart run tool/bundle_kokoro.dart [--check]');
    exitCode = 64;
    return;
  }
  final check = arguments.contains('--check');
  final folder = Directory('assets/mediapipe');
  for (final asset in [kokoroGpuModel]) {
    final model = File('${folder.path}/${asset.sha256}');
    Future<bool> verified() async =>
        await model.exists() &&
        (await sha256.bind(model.openRead()).first).toString() == asset.sha256;
    if (!await verified()) {
      if (check) {
        stderr.writeln(
          'Kokoro model missing or corrupt: ${asset.url}. Run dart run tool/bundle_kokoro.dart',
        );
        exitCode = 1;
        return;
      }
      final source = await ModelStore(
        cacheDirectory: '.dart_tool/kokoro_download',
      ).get(asset);
      await folder.create(recursive: true);
      final partial = File('${model.path}.partial');
      await File(source.path!).copy(partial.path);
      await partial.rename(model.path);
      if (!await verified()) {
        throw StateError('Bundled Kokoro SHA-256 mismatch');
      }
    }
    stdout.writeln(
      'Verified ${Uri.parse(asset.url).pathSegments.last}: ${await model.length()} bytes.',
    );
  }
  // Remove the formerly bundled CPU model; it must not enter future builds.
  final obsoleteCpuModel = File(
    '${folder.path}/e7b931ee5d4b7104012a838c9eee240d19ea69cb3ca269041a3274f83dbb7fa1',
  );
  if (await obsoleteCpuModel.exists()) {
    if (check) {
      stderr.writeln(
        'Obsolete CPU model is still bundled. Run dart run tool/bundle_kokoro.dart',
      );
      exitCode = 1;
      return;
    }
    await obsoleteCpuModel.delete();
  }
  final manifest = File('${folder.path}/manifest.json');
  final contents =
      '${const JsonEncoder.withIndent('  ').convert({
        'note': 'Written by dart run tool/bundle_kokoro.dart. GPU Kokoro model.',
        'models': [
          {'model': 'kokoro_gpu', 'file': kokoroGpuModel.sha256, 'url': kokoroGpuModel.url},
        ],
      })}\n';
  if (check) {
    if (!await manifest.exists() || await manifest.readAsString() != contents) {
      stderr.writeln(
        'Model manifest is out of date. Run dart run tool/bundle_kokoro.dart',
      );
      exitCode = 1;
      return;
    }
  } else {
    await manifest.writeAsString(contents);
  }
  stdout.writeln('GPU Kokoro model bundled and SHA-256 verified.');
}
