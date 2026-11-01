// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final audioDir = Directory('assets/audio');
  if (!audioDir.existsSync()) {
    audioDir.createSync(recursive: true);
  }

  // 1. bottle_select.wav: crisp, soft glass clink
  _writeWav(
    'assets/audio/bottle_select.wav',
    _generateAudio(
      durationSec: 0.18,
      sampleRate: 22050,
      generator: (t) {
        final env = math.exp(-22 * t);
        final fundamental = math.sin(2 * math.pi * 1280 * t);
        final overtone = 0.45 * math.sin(2 * math.pi * 2600 * t);
        return (fundamental + overtone) * env * 0.75;
      },
    ),
  );

  // 2. water_pour.wav: gentle flowing and glugging water
  _writeWav(
    'assets/audio/water_pour.wav',
    _generateAudio(
      durationSec: 0.85,
      sampleRate: 22050,
      generator: (t) {
        final env = (t < 0.1 ? t / 0.1 : (t > 0.75 ? (0.85 - t) / 0.1 : 1.0))
            .clamp(0.0, 1.0);
        final glugFreq = 420.0 + 85.0 * math.sin(2 * math.pi * 14 * t);
        final glug = math.sin(2 * math.pi * glugFreq * t);
        final bubble =
            0.4 *
            math.sin(2 * math.pi * (glugFreq * 1.8) * t) *
            (0.5 + 0.5 * math.sin(2 * math.pi * 22 * t));
        final noise =
            (math.Random((t * 22050).toInt()).nextDouble() * 2 - 1) * 0.12;
        return (glug * 0.55 + bubble + noise) * env * 0.7;
      },
    ),
  );

  // 3. water_settle.wav: soft liquid finishing droplet
  _writeWav(
    'assets/audio/water_settle.wav',
    _generateAudio(
      durationSec: 0.28,
      sampleRate: 22050,
      generator: (t) {
        final env = math.exp(-14 * t);
        final sweepFreq = 520.0 + 160.0 * (1.0 - t / 0.28);
        final droplet = math.sin(2 * math.pi * sweepFreq * t);
        final sub = 0.3 * math.sin(2 * math.pi * (sweepFreq * 0.5) * t);
        return (droplet + sub) * env * 0.75;
      },
    ),
  );

  // 4. invalid_move.wav: quiet, subtle rejection sound
  _writeWav(
    'assets/audio/invalid_move.wav',
    _generateAudio(
      durationSec: 0.16,
      sampleRate: 22050,
      generator: (t) {
        final env = math.exp(-18 * t);
        final tone = math.sin(2 * math.pi * 165 * t);
        return tone * env * 0.65;
      },
    ),
  );

  // 5. level_complete.wav: cheerful, peaceful melodic chime arpeggio
  _writeWav(
    'assets/audio/level_complete.wav',
    _generateAudio(
      durationSec: 1.1,
      sampleRate: 22050,
      generator: (t) {
        // Notes: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
        final notes = [
          {'time': 0.00, 'freq': 523.25, 'dur': 0.4},
          {'time': 0.18, 'freq': 659.25, 'dur': 0.4},
          {'time': 0.36, 'freq': 783.99, 'dur': 0.4},
          {'time': 0.54, 'freq': 1046.50, 'dur': 0.55},
        ];
        double val = 0;
        for (final n in notes) {
          final start = n['time'] as double;
          final freq = n['freq'] as double;
          final dur = n['dur'] as double;
          if (t >= start && t < start + dur) {
            final dt = t - start;
            final env = math.exp(-6.5 * dt);
            val +=
                (math.sin(2 * math.pi * freq * dt) +
                    0.3 * math.sin(2 * math.pi * freq * 2 * dt)) *
                env *
                0.45;
          }
        }
        return val.clamp(-1.0, 1.0);
      },
    ),
  );

  // 6. button_tap.wav: subtle UI click
  _writeWav(
    'assets/audio/button_tap.wav',
    _generateAudio(
      durationSec: 0.08,
      sampleRate: 22050,
      generator: (t) {
        final env = math.exp(-55 * t);
        return math.sin(2 * math.pi * 880 * t) * env * 0.6;
      },
    ),
  );

  // 7. extra_tube.wav: light bottle-placement chime
  _writeWav(
    'assets/audio/extra_tube.wav',
    _generateAudio(
      durationSec: 0.35,
      sampleRate: 22050,
      generator: (t) {
        final env = math.exp(-12 * t);
        final ch1 = math.sin(2 * math.pi * 920 * t);
        final ch2 = 0.4 * math.sin(2 * math.pi * 1380 * t);
        return (ch1 + ch2) * env * 0.7;
      },
    ),
  );

  print('Audio files generated successfully in assets/audio/ !');
}

List<int> _generateAudio({
  required double durationSec,
  required int sampleRate,
  required double Function(double t) generator,
}) {
  final numSamples = (durationSec * sampleRate).toInt();
  final samples = <int>[];
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final sampleDouble = generator(t).clamp(-1.0, 1.0);
    final sampleInt = (sampleDouble * 32767).toInt();
    samples.add(sampleInt);
  }
  return samples;
}

void _writeWav(String path, List<int> samples, {int sampleRate = 22050}) {
  final numSamples = samples.length;
  final numBytes = numSamples * 2; // 16-bit mono

  final header = ByteData(44);
  // RIFF chunk descriptor
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, 36 + numBytes, Endian.little);
  header.setUint8(8, 0x57); // W
  header.setUint8(9, 0x41); // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E

  // "fmt " sub-chunk
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6D); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // ' '
  header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  header.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
  header.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  header.setUint32(24, sampleRate, Endian.little); // SampleRate
  header.setUint32(
    28,
    sampleRate * 2,
    Endian.little,
  ); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  header.setUint16(
    32,
    2,
    Endian.little,
  ); // BlockAlign (NumChannels * BitsPerSample/8)
  header.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

  // "data" sub-chunk
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, numBytes, Endian.little);

  final bytes = Uint8List(44 + numBytes);
  bytes.setRange(0, 44, header.buffer.asUint8List());

  final dataView = ByteData.view(bytes.buffer, 44, numBytes);
  for (int i = 0; i < numSamples; i++) {
    dataView.setInt16(i * 2, samples[i], Endian.little);
  }

  File(path).writeAsBytesSync(bytes);
}
