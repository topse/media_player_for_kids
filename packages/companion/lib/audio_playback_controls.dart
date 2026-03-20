import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'audio_player_service.dart';

class AudioPlaybackControls extends StatelessWidget {
  const AudioPlaybackControls({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = di<AudioPlayerService>();

    return ValueListenableBuilder<String?>(
      valueListenable: audioPlayer.currentTrackName,
      builder: (context, trackName, _) {
        if (trackName == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track name
              Text(
                trackName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),

              // Play/Pause button
              ValueListenableBuilder<bool>(
                valueListenable: audioPlayer.isPlaying,
                builder: (context, isPlaying, _) {
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () async {
                      if (isPlaying) {
                        await audioPlayer.pause();
                      } else {
                        await audioPlayer.resume();
                      }
                    },
                  );
                },
              ),

              // Stop button
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () async {
                  await audioPlayer.stop();
                },
              ),

              const SizedBox(width: 8),

              // Time display
              ValueListenableBuilder<Duration>(
                valueListenable: audioPlayer.currentPosition,
                builder: (context, currentPos, _) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: audioPlayer.duration,
                    builder: (context, duration, _) {
                      return Text(
                        '${_formatDuration(currentPos)} / ${_formatDuration(duration)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  );
                },
              ),

              const SizedBox(width: 8),

              // Seek slider
              SizedBox(
                width: 200,
                child: ValueListenableBuilder<Duration>(
                  valueListenable: audioPlayer.currentPosition,
                  builder: (context, currentPos, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: audioPlayer.duration,
                      builder: (context, duration, _) {
                        return Slider(
                          value: duration.inMilliseconds > 0
                              ? currentPos.inMilliseconds.toDouble()
                              : 0.0,
                          min: 0.0,
                          max: duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) async {
                            await audioPlayer.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
