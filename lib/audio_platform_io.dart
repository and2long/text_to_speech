import 'package:path_provider/path_provider.dart';

/// audioplayers writes WAV bytes here on Apple platforms and Linux.
Future<void> prepareAudioPlayback() async {
  final directory = await getTemporaryDirectory();
  await directory.create(recursive: true);
}
