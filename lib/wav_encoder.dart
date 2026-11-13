import 'dart:typed_data';

/// Encodes normalized mono PCM as a 16-bit WAV for platform audio players.
Uint8List encodeWav(Float32List samples, int sampleRateHz) {
  final dataSize = samples.length * 2;
  final bytes = ByteData(44 + dataSize);
  void writeTag(int offset, String tag) {
    for (var i = 0; i < tag.length; i++) {
      bytes.setUint8(offset + i, tag.codeUnitAt(i));
    }
  }

  writeTag(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  writeTag(8, 'WAVE');
  writeTag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // Mono
  bytes.setUint32(24, sampleRateHz, Endian.little);
  bytes.setUint32(28, sampleRateHz * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  writeTag(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final sample = samples[i].isFinite ? samples[i].clamp(-1.0, 1.0) : 0.0;
    bytes.setInt16(
      44 + i * 2,
      (sample * (sample < 0 ? 32768 : 32767)).round(),
      Endian.little,
    );
  }
  return bytes.buffer.asUint8List();
}
