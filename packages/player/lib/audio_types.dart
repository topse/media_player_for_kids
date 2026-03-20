/// Audio device types and models, replacing the `audio_router` package.
///
/// These types are used throughout the app for device selection, admin
/// configuration, and playback routing.
library;

/// Logical audio output device type.
enum AudioSourceType {
  builtinSpeaker,
  builtinReceiver,
  bluetooth,
  wiredHeadset,
  carAudio,
  airplay,
  unknown;

  /// Parses a type name string (e.g. `"builtinSpeaker"`) into the enum value.
  static AudioSourceType fromString(String value) {
    for (final t in AudioSourceType.values) {
      if (t.name == value) return t;
    }
    return AudioSourceType.unknown;
  }
}

/// A single audio output device with an OS-level [id] and a logical [type].
class AudioDevice {
  final String id;
  final AudioSourceType type;

  const AudioDevice({required this.id, required this.type});

  factory AudioDevice.fromMap(Map<dynamic, dynamic> map) {
    return AudioDevice(
      id: (map['id'] ?? '').toString(),
      type: AudioSourceType.fromString(map['type'] as String? ?? 'unknown'),
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'type': type.name};

  @override
  String toString() => 'AudioDevice(id: $id, type: ${type.name})';
}

/// Snapshot of audio output state: available devices and the selected device.
class AudioState {
  final List<AudioDevice> availableDevices;
  final AudioDevice? selectedDevice;

  const AudioState({required this.availableDevices, this.selectedDevice});

  factory AudioState.fromMap(Map<dynamic, dynamic> map) {
    final rawDevices = map['availableDevices'] as List<dynamic>? ?? [];
    final rawSelected = map['selectedDevice'];
    return AudioState(
      availableDevices: rawDevices
          .whereType<Map<dynamic, dynamic>>()
          .map(AudioDevice.fromMap)
          .toList(),
      selectedDevice: rawSelected is Map<dynamic, dynamic>
          ? AudioDevice.fromMap(rawSelected)
          : null,
    );
  }
}
