import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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
  /// Maximum momentary loudness (400 ms window). Null for files shorter than
  /// 400 ms or where every frame contained only silence (ffmpeg outputs 'nan').
  final double? momentary;
  /// Maximum short-term loudness (3 s window). Null for files shorter than 3 s
  /// or where every frame contained only silence (ffmpeg outputs 'nan').
  final double? shortTerm;
  final double lra;
  final double truePeak;
  final int durationMs;

  const AudioAnalysis({
    required this.lufs,
    required this.momentary,
    required this.shortTerm,
    required this.lra,
    required this.truePeak,
    required this.durationMs,
  });

  @override
  String toString() =>
      'AudioAnalysis(lufs: $lufs, momentary: $momentary, shortTerm: $shortTerm, '
      'lra: $lra, truePeak: $truePeak, durationMs: $durationMs)';
}

/// Measures EBU R128 loudness values and duration of an audio file using ffmpeg.
/// Returns null if ffmpeg is not available or measurement fails.
///
/// Runs in a background isolate so the Flutter UI thread is never blocked,
/// regardless of how long the analysis takes or how ffmpeg buffers its output.
///
/// Parses values from the per-frame ebur128 progress lines:
///   [Parsed_ebur128_0 @ ...] t: 1204.9  TARGET:-23 LUFS  M: -22.3  S: -22.3
///       I: -23.4 LUFS  LRA: 3.6 LU  FTPK: -36.2 -35.5 dBFS  TPK: -4.9 -5.8 dBFS
///
/// I (integrated loudness) and LRA are cumulative metrics — taken from the
/// last progress line which covers the full file.
/// M (momentary), S (short-term) and TPK are peak metrics — the maximum value
/// seen across all progress lines is stored.
/// M/S can be 'nan' or '-inf' during silence; those frames are skipped.
/// TPK is only printed when the running maximum is updated; the last occurrence
/// equals the file-level true peak. Multiple channel values are reduced to the
/// highest (least negative).
Future<AudioAnalysis?> analyzeAudio(String filePath) =>
    Isolate.run(() => _analyzeAudioInIsolate(filePath));

Future<AudioAnalysis?> _analyzeAudioInIsolate(String filePath) async {
  try {
    final process = await Process.start(_ffmpegPath(), [
      '-i', filePath,
      '-af', 'ebur128=peak=true',
      '-f', 'null',
      '-',
    ]);

    // stdout is empty for null output — drain it so the process doesn't stall.
    process.stdout.drain<void>();

    // I (integrated) and LRA are cumulative over the whole file → last line.
    // M (momentary), S (short-term) and TPK are per-frame peaks → maximum seen.
    // M/S can be 'nan' or '-inf' during silence — _parseField returns null for
    // those, so they are simply skipped when updating the running maximum.
    String? lastProgressLine;
    double? maxMomentary;
    double? maxShortTerm;
    double? maxTruePeak;
    int? durationMs;

    await process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach((line) {
      if (durationMs == null && line.contains('Duration:')) {
        durationMs = _parseDuration(line);
      }
      if (line.contains('Parsed_ebur128')) {
        if (line.contains('I:') && line.contains('LRA:')) {
          lastProgressLine = line;
          final m = _parseField(line, RegExp(r'\bM:\s*(-?\d+\.?\d*)'));
          if (m != null && (maxMomentary == null || m > maxMomentary!)) {
            maxMomentary = m;
          }
          final s = _parseField(line, RegExp(r'\bS:\s*(-?\d+\.?\d*)'));
          if (s != null && (maxShortTerm == null || s > maxShortTerm!)) {
            maxShortTerm = s;
          }
        }
        // TPK is only printed when the running maximum is updated.
        final tpk = _parseTruePeak(line);
        if (tpk != null && (maxTruePeak == null || tpk > maxTruePeak!)) {
          maxTruePeak = tpk;
        }
      }
    });

    await process.exitCode;

    if (lastProgressLine == null) {
      debugPrint('[analyzeAudio] No ebur128 progress lines found in ffmpeg output.');
      return null;
    }

    final line = lastProgressLine!;
    final momentary = maxMomentary;
    final shortTerm = maxShortTerm;
    final truePeak  = maxTruePeak;
    final lufs      = _parseField(line, RegExp(r'\bI:\s*(-?\d+\.?\d*)\s+LUFS'));
    final lra       = _parseField(line, RegExp(r'\bLRA:\s*(-?\d+\.?\d*)\s+LU'));

    if (lufs == null || lra == null || truePeak == null || durationMs == null) {
      debugPrint(
        '[analyzeAudio] Failed to parse ffmpeg output.\n'
        '  lastProgressLine: $line\n'
        '  lufs=$lufs, momentary=$momentary, shortTerm=$shortTerm, '
        'lra=$lra, truePeak=$truePeak, durationMs=$durationMs',
      );
      return null;
    }

    return AudioAnalysis(
      lufs: lufs,
      momentary: momentary,
      shortTerm: shortTerm,
      lra: lra,
      truePeak: truePeak,
      durationMs: durationMs!,
    );
  } catch (e) {
    debugPrint('[analyzeAudio] ffmpeg analysis failed: $e');
    return null;
  }
}

double? _parseField(String text, RegExp regex) {
  final match = regex.firstMatch(text);
  if (match != null) return double.tryParse(match.group(1)!);
  return null;
}

/// Parses the TPK (true peak) field which has one value per channel.
/// Returns the highest value across all channels.
double? _parseTruePeak(String line) {
  final match = RegExp(r'\bTPK:\s*((?:-?\d+\.?\d*\s*)+)dBFS').firstMatch(line);
  if (match == null) return null;
  final values = RegExp(r'-?\d+\.?\d*')
      .allMatches(match.group(1)!)
      .map((m) => double.tryParse(m.group(0)!))
      .whereType<double>()
      .toList();
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a > b ? a : b);
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

/// Compresses an audio file to AAC format using FFmpeg.
/// Returns the path to the compressed file, or null if compression fails.
/// Uses 160kbps for stereo files, 80kbps for mono files.
Future<String?> compressAudioFile(String inputPath, String outputPath) async {
  try {
    // First, check if the input file is mono or stereo
    final probeResult = await Process.run(_ffmpegPath(), [
      '-i', inputPath,
      '-hide_banner',
    ], stderrEncoding: const SystemEncoding());

    final probeOutput = probeResult.stderr as String;
    bool isMono = probeOutput.contains('mono') || probeOutput.contains('1 channel');
    int bitrate = isMono ? 80 : 160; // 80kbps for mono, 160kbps for stereo

    // Compress to AAC using the determined bitrate
    final result = await Process.run(_ffmpegPath(), [
      '-i', inputPath,
      '-c:a', 'aac',
      '-b:a', '${bitrate}k',
      '-y', // overwrite output file if it exists
      outputPath,
    ], stderrEncoding: const SystemEncoding());

    if (result.exitCode == 0) {
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        return outputPath;
      }
    } else {
      debugPrint('FFmpeg compression failed: ${result.stderr}');
    }
  } catch (e) {
    debugPrint('FFmpeg compression error: $e');
  }
  return null;
}
