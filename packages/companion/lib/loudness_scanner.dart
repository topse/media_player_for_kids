import 'dart:io';

import 'package:flutter/foundation.dart';

/// Returns the path to the ffmpeg executable.
/// Prefers the bundled copy next to the app executable, falls back to system PATH.
String _ffmpegPath() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final bundled = File('$exeDir/ffmpeg.exe');
  if (bundled.existsSync()) return bundled.path;
  return 'ffmpeg'; // fall back to system PATH
}

class AudioAnalysis {
  final double lufs;
  final double lra;
  final double truePeak;
  final int durationMs;

  const AudioAnalysis({
    required this.lufs,
    required this.lra,
    required this.truePeak,
    required this.durationMs,
  });

  @override
  String toString() =>
      'AudioAnalysis(lufs: $lufs, lra: $lra, truePeak: $truePeak, durationMs: $durationMs)';
}

/// Measures EBU R128 loudness values and duration of an audio file using ffmpeg.
/// Returns null if ffmpeg is not available or measurement fails.
Future<AudioAnalysis?> analyzeAudio(String filePath) async {
  try {
    final result = await Process.run(_ffmpegPath(), [
      '-i', filePath,
      '-af', 'ebur128=peak=true',
      '-f', 'null',
      '-',
    ], stderrEncoding: const SystemEncoding());

    final stderr = result.stderr as String;

    // Parse from the Summary section only (not per-frame log lines).
    // Summary lines are indented with leading whitespace and on their own line.
    final lufs = _parseDouble(stderr, RegExp(r'^\s+I:\s+(-?\d+\.?\d*)\s+LUFS', multiLine: true));
    final lra = _parseDouble(stderr, RegExp(r'^\s+LRA:\s+(-?\d+\.?\d*)\s+LU$', multiLine: true));
    final truePeak =
        _parseDouble(stderr, RegExp(r'^\s+Peak:\s+(-?\d+\.?\d*)\s+dBFS', multiLine: true));
    final durationMs = _parseDuration(stderr);

    if (lufs == null || lra == null || truePeak == null || durationMs == null) {
      debugPrint(
          'Failed to parse ffmpeg output. lufs=$lufs, lra=$lra, truePeak=$truePeak, durationMs=$durationMs');
      return null;
    }

    return AudioAnalysis(
      lufs: lufs,
      lra: lra,
      truePeak: truePeak,
      durationMs: durationMs,
    );
  } catch (e) {
    debugPrint('ffmpeg analysis failed: $e');
    return null;
  }
}

double? _parseDouble(String text, RegExp regex) {
  final match = regex.firstMatch(text);
  if (match != null) {
    return double.tryParse(match.group(1)!);
  }
  return null;
}

/// Parses duration from ffmpeg output: "Duration: HH:MM:SS.CC"
int? _parseDuration(String text) {
  final regex = RegExp(r'Duration:\s+(\d+):(\d+):(\d+)\.(\d+)');
  final match = regex.firstMatch(text);
  if (match == null) return null;

  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  final seconds = int.parse(match.group(3)!);
  final centiseconds = int.parse(match.group(4)!);

  return (hours * 3600 + minutes * 60 + seconds) * 1000 +
      centiseconds * 10;
}
