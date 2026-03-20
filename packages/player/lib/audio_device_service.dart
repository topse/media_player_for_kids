import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player/audio_types.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('audio_device_service');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Default human-readable label for a given [AudioSourceType].
String _defaultLabel(AudioSourceType type) {
  switch (type) {
    case AudioSourceType.builtinSpeaker:
      return 'Speaker';
    case AudioSourceType.builtinReceiver:
      return 'Phone Speaker';
    case AudioSourceType.bluetooth:
      return 'Bluetooth';
    case AudioSourceType.wiredHeadset:
      return 'Headphones';
    case AudioSourceType.carAudio:
      return 'Car Audio';
    case AudioSourceType.airplay:
      return 'AirPlay';
    case AudioSourceType.unknown:
      return 'Audio Device';
  }
}

String _typeConfigKey(AudioSourceType type) => 'type:${type.name}';

String _normalizeBluetoothAddress(String address) =>
    address.trim().toUpperCase();

String _bluetoothConfigKey(String address) =>
    'bluetooth:${_normalizeBluetoothAddress(address)}';

bool _isBluetoothSpecificConfigKey(String configKey) =>
    configKey.startsWith('bluetooth:');

AudioSourceType _typeForConfigKey(String configKey) {
  if (_isBluetoothSpecificConfigKey(configKey)) {
    return AudioSourceType.bluetooth;
  }

  if (configKey.startsWith('type:')) {
    return AudioSourceType.fromString(configKey.substring(5));
  }

  return AudioSourceType.fromString(configKey);
}

String _normalizeStoredConfigKey(String rawKey) {
  if (rawKey.startsWith('type:')) {
    return rawKey;
  }
  if (rawKey.startsWith('bluetooth:')) {
    return _bluetoothConfigKey(rawKey.substring('bluetooth:'.length));
  }

  final type = AudioSourceType.fromString(rawKey);
  return _typeConfigKey(type);
}

// ---------------------------------------------------------------------------
// AudioDeviceConfig
// ---------------------------------------------------------------------------

/// Admin-controlled configuration for one audio output device type.
@immutable
class AudioDeviceConfig {
  /// Stable config key, e.g. `type:builtinSpeaker` or `bluetooth:AA:BB:...`.
  final String configKey;

  /// Logical output type.
  final AudioSourceType type;

  /// Volume limit in dB relative to nominal (0.0 = no limit, -18.0 = very quiet).
  final double volumeLimitDb;

  const AudioDeviceConfig({
    required this.configKey,
    required this.type,
    required this.volumeLimitDb,
  });

  AudioDeviceConfig copyWith({
    String? configKey,
    AudioSourceType? type,
    double? volumeLimitDb,
  }) {
    return AudioDeviceConfig(
      configKey: configKey ?? this.configKey,
      type: type ?? this.type,
      volumeLimitDb: volumeLimitDb ?? this.volumeLimitDb,
    );
  }

  Map<String, dynamic> toJson() => {
    'configKey': configKey,
    'type': type.name,
    'volumeLimitDb': volumeLimitDb,
  };

  factory AudioDeviceConfig.fromJson(Map<String, dynamic> json) {
    final rawKey =
        json['configKey'] as String? ?? json['typeKey'] as String? ?? '';
    final configKey = _normalizeStoredConfigKey(rawKey);
    final type = _typeForConfigKey(configKey);

    return AudioDeviceConfig(
      configKey: configKey,
      type: json['type'] is String
          ? AudioSourceType.fromString(json['type'] as String)
          : type,
      volumeLimitDb: (json['volumeLimitDb'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Default config for a given [AudioSourceType].
  factory AudioDeviceConfig.defaultFor(
    AudioSourceType type, {
    String? configKey,
  }) {
    return AudioDeviceConfig(
      configKey: configKey ?? _typeConfigKey(type),
      type: type,
      volumeLimitDb: 0.0,
    );
  }

  /// Linear volume factor for this device's volume limit.
  ///
  /// 0.0 dB → 1.0 (no change); -18.0 dB → ≈0.126.
  double get volumeLimitFactor => pow(10.0, volumeLimitDb / 20.0).toDouble();
}

// ---------------------------------------------------------------------------
// AudioDeviceService
// ---------------------------------------------------------------------------

const String _kPrefsConfigsKey = 'audio_device_configs';
const MethodChannel _adminAudioDevicesChannel = MethodChannel(
  'player/admin_audio_devices',
);

@immutable
class NamedAvailableAudioDevice {
  final String id;
  final AudioSourceType type;

  /// Raw Android AudioDeviceInfo.TYPE_* integer.
  /// Used to distinguish BLUETOOTH_A2DP (8) from BLUETOOTH_SCO (7).
  final int androidType;

  final String name;
  final String address;

  const NamedAvailableAudioDevice({
    required this.id,
    required this.type,
    required this.androidType,
    required this.name,
    required this.address,
  });

  factory NamedAvailableAudioDevice.fromMap(Map<dynamic, dynamic> map) {
    return NamedAvailableAudioDevice(
      id: map['id'] as String? ?? '',
      type: AudioSourceType.fromString(map['type'] as String? ?? 'unknown'),
      androidType: int.tryParse(map['androidType']?.toString() ?? '') ?? 0,
      name: map['name'] as String? ?? 'Audio device',
      address: map['address'] as String? ?? '',
    );
  }

  String get normalizedAddress => _normalizeBluetoothAddress(address);

  /// True when this is a high-quality stereo Bluetooth profile (A2DP).
  /// Prefer A2DP (type 8) over SCO (type 7) for media playback.
  bool get isBluetoothA2dp => androidType == 8;
}

@immutable
class KnownBluetoothDevice {
  final String name;
  final String address;

  const KnownBluetoothDevice({required this.name, required this.address});

  factory KnownBluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return KnownBluetoothDevice(
      name: map['name'] as String? ?? 'Bluetooth device',
      address: map['address'] as String? ?? '',
    );
  }

  String get normalizedAddress => _normalizeBluetoothAddress(address);
}

@immutable
class AdminAudioDeviceEntry {
  final String configKey;
  final AudioSourceType type;
  final String systemName;
  final String address;
  final AudioDevice? availableDevice;
  final bool isCurrent;

  const AdminAudioDeviceEntry({
    required this.configKey,
    required this.type,
    required this.systemName,
    required this.address,
    required this.availableDevice,
    required this.isCurrent,
  });

  bool get isAvailable => availableDevice != null;
  bool get isBluetooth => type == AudioSourceType.bluetooth;
}

/// Manages audio output device detection and per-device volume limits.
///
/// The app cannot programmatically switch Android media output — Android
/// auto-routes media audio (Bluetooth A2DP > wired > speaker). This service
/// detects which device is currently active and applies the matching
/// admin-configured volume limit.
///
/// Usage:
/// 1. Call [AudioDeviceService.create] at startup.
/// 2. Listen via [addListener] / [ChangeNotifier] for UI rebuilds.
/// 3. Access [currentDeviceVolumeLimitFactor] for the active device's volume.
/// 4. Admin calls [saveConfig] after changing a device's volume limit.
class AudioDeviceService extends ChangeNotifier {
  static const _audioDeviceEventsChannel = EventChannel(
    'player/audio_device_events',
  );

  List<AudioDevice> _availableDevices = [];
  List<NamedAvailableAudioDevice> _namedAvailableDevices = [];
  AudioDevice? _currentDevice;
  Map<String, AudioDeviceConfig> _configs = {};
  List<KnownBluetoothDevice> _knownBluetoothDevices = [];
  bool _bluetoothPermissionRequired = false;
  StreamSubscription<dynamic>? _streamSub;

  AudioDeviceService._();

  /// Creates and initializes the service (loads prefs + fetches devices).
  static Future<AudioDeviceService> create() async {
    final svc = AudioDeviceService._();
    await svc._loadConfigs();
    await svc.refreshDevices();
    svc._subscribeToDeviceStream();
    return svc;
  }

  // -------------------------------------------------------------------------
  // Public state
  // -------------------------------------------------------------------------

  /// All audio output devices currently visible to the OS.
  List<AudioDevice> get availableDevices =>
      List.unmodifiable(_availableDevices);

  /// The device the audio is currently routed to (null = system default).
  AudioDevice? get currentDevice => _currentDevice;

  /// Paired Bluetooth devices known to Android, even if they are currently off.
  List<KnownBluetoothDevice> get knownBluetoothDevices =>
      List.unmodifiable(_knownBluetoothDevices);

  List<NamedAvailableAudioDevice> get namedAvailableDevices =>
      List.unmodifiable(_namedAvailableDevices);

  /// True when Android requires BLUETOOTH_CONNECT permission to list paired
  /// devices and the permission has not been granted yet.
  bool get bluetoothPermissionRequired => _bluetoothPermissionRequired;

  /// Entries shown in the admin UI.
  ///
  /// Non-Bluetooth outputs are configured per logical type. Bluetooth outputs
  /// are configured per bonded device address whenever Android knows that
  /// address, even if the headset is currently turned off.
  List<AdminAudioDeviceEntry> get adminVisibleDevices {
    final entries = <AdminAudioDeviceEntry>[];
    final seenKeys = <String>{};

    void addEntry(AdminAudioDeviceEntry entry) {
      if (seenKeys.add(entry.configKey)) {
        entries.add(entry);
      }
    }

    const nonBluetoothOrder = [
      AudioSourceType.builtinSpeaker,
      AudioSourceType.builtinReceiver,
      AudioSourceType.wiredHeadset,
      AudioSourceType.carAudio,
      AudioSourceType.airplay,
      AudioSourceType.unknown,
    ];

    for (final type in nonBluetoothOrder) {
      if (!_shouldExposeTypeEntry(type)) continue;

      final availableDevice = _firstAvailableDeviceForType(type);
      final configKey = _typeConfigKey(type);
      addEntry(
        AdminAudioDeviceEntry(
          configKey: configKey,
          type: type,
          systemName:
              _preferredSystemLabelForConfigKey(
                configKey,
                fallbackType: type,
              ) ??
              _defaultLabel(type),
          address: '',
          availableDevice: availableDevice,
          isCurrent: _isCurrentConfigKey(configKey),
        ),
      );
    }

    for (final device in _knownBluetoothDevices) {
      final configKey = _bluetoothConfigKey(device.address);
      final availableDevice = _availableBluetoothDeviceForAddress(
        device.normalizedAddress,
      );
      addEntry(
        AdminAudioDeviceEntry(
          configKey: configKey,
          type: AudioSourceType.bluetooth,
          systemName: device.name,
          address: device.normalizedAddress,
          availableDevice: availableDevice,
          isCurrent: _isCurrentConfigKey(configKey),
        ),
      );
    }

    for (final config in _configs.values) {
      if (!_isBluetoothSpecificConfigKey(config.configKey)) continue;
      addEntry(
        AdminAudioDeviceEntry(
          configKey: config.configKey,
          type: AudioSourceType.bluetooth,
          systemName:
              _preferredSystemLabelForConfigKey(
                config.configKey,
                fallbackType: AudioSourceType.bluetooth,
              ) ??
              _defaultLabel(AudioSourceType.bluetooth),
          address: config.configKey.substring('bluetooth:'.length),
          availableDevice: _availableBluetoothDeviceForConfigKey(
            config.configKey,
          ),
          isCurrent: _isCurrentConfigKey(config.configKey),
        ),
      );
    }

    if ((entries
            .where((entry) => entry.type == AudioSourceType.bluetooth)
            .isEmpty) &&
        (_shouldExposeTypeEntry(AudioSourceType.bluetooth) ||
            _bluetoothPermissionRequired)) {
      final configKey = _typeConfigKey(AudioSourceType.bluetooth);
      addEntry(
        AdminAudioDeviceEntry(
          configKey: configKey,
          type: AudioSourceType.bluetooth,
          systemName:
              _preferredSystemLabelForConfigKey(
                configKey,
                fallbackType: AudioSourceType.bluetooth,
              ) ??
              _defaultLabel(AudioSourceType.bluetooth),
          address: '',
          availableDevice: _firstAvailableDeviceForType(
            AudioSourceType.bluetooth,
          ),
          isCurrent: _isCurrentConfigKey(configKey),
        ),
      );
    }

    return entries;
  }

  /// Linear volume factor that should be applied for the currently active
  /// output device (derived from admin's dB limit slider).
  double get currentDeviceVolumeLimitFactor {
    if (_currentDevice == null) {
      // Fallback: determine best match from available devices.
      if (_availableDevices.isEmpty) {
        _log.info(
          'currentDeviceVolumeLimitFactor: no current device, no available devices → 1.0',
        );
        return 1.0;
      }
      // Use builtinSpeaker config as default if present.
      final speaker = _availableDevices.firstWhere(
        (d) => d.type == AudioSourceType.builtinSpeaker,
        orElse: () => _availableDevices.first,
      );
      final cfg = configForAvailableDevice(speaker);
      _log.info(
        'currentDeviceVolumeLimitFactor: no current device, fallback to ${speaker.type.name} '
        'key=${cfg.configKey} volumeLimitDb=${cfg.volumeLimitDb} → ${cfg.volumeLimitFactor.toStringAsFixed(4)}',
      );
      return cfg.volumeLimitFactor;
    }
    final configKey = configKeyForAvailableDevice(_currentDevice!);
    final cfg = configForAvailableDevice(_currentDevice!);
    _log.info(
      'currentDeviceVolumeLimitFactor: currentDevice=${_currentDevice!.type.name}(${_currentDevice!.id}) '
      'configKey=$configKey volumeLimitDb=${cfg.volumeLimitDb} → ${cfg.volumeLimitFactor.toStringAsFixed(4)} '
      '_configs keys: ${_configs.keys.join(", ")}',
    );
    return cfg.volumeLimitFactor;
  }

  /// Returns the config for a currently available output device.
  AudioDeviceConfig configForAvailableDevice(AudioDevice device) {
    return configForConfigKey(
      configKeyForAvailableDevice(device),
      fallbackType: device.type,
    );
  }

  /// Returns the config for a specific stable config key.
  AudioDeviceConfig configForConfigKey(
    String configKey, {
    AudioSourceType? fallbackType,
  }) {
    final normalizedKey = _normalizeStoredConfigKey(configKey);
    final type = fallbackType ?? _typeForConfigKey(normalizedKey);
    final stored = _configs[normalizedKey];

    if (stored != null) {
      _log.fine(
        'configForConfigKey: key=$normalizedKey → FOUND volumeLimitDb=${stored.volumeLimitDb}',
      );
      return stored;
    }
    _log.info(
      'configForConfigKey: key=$normalizedKey → NOT FOUND in _configs (keys: ${_configs.keys.join(", ")})',
    );

    if (_isBluetoothSpecificConfigKey(normalizedKey)) {
      final legacyBluetooth =
          _configs[_typeConfigKey(AudioSourceType.bluetooth)];
      if (legacyBluetooth != null) {
        return legacyBluetooth.copyWith(
          configKey: normalizedKey,
          type: AudioSourceType.bluetooth,
        );
      }
    }

    return AudioDeviceConfig.defaultFor(type, configKey: normalizedKey);
  }

  String configKeyForAvailableDevice(AudioDevice device) {
    if (device.type == AudioSourceType.bluetooth) {
      final named = _namedAvailableDeviceForAudioDevice(device);
      if (named != null && named.normalizedAddress.isNotEmpty) {
        final key = _bluetoothConfigKey(named.normalizedAddress);
        _log.fine(
          'configKeyForAvailableDevice: bluetooth id=${device.id} address=${named.normalizedAddress} → $key',
        );
        return key;
      }
      _log.info(
        'configKeyForAvailableDevice: bluetooth id=${device.id} no named device found → fallback to type key',
      );
    }

    final key = _typeConfigKey(device.type);
    _log.fine(
      'configKeyForAvailableDevice: ${device.type.name} id=${device.id} → $key',
    );
    return key;
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Re-queries the OS for available output devices.
  Future<void> refreshDevices() async {
    try {
      await _refreshKnownBluetoothDevices();
      await _refreshNamedAvailableDevices();

      _availableDevices = _namedAvailableDevices
          .map((n) => AudioDevice(id: n.id, type: n.type))
          .toList();
      _currentDevice = _resolveCurrentDevice();
      _log.info(
        'refreshDevices: ${_availableDevices.length} devices '
        '(${_availableDevices.map((d) => d.type.name).join(", ")}), '
        'current=${_currentDevice?.type.name}',
      );
      notifyListeners();
    } catch (e) {
      _log.warning('refreshDevices failed: $e');
    }
  }

  /// Requests Bluetooth permission on Android so the admin page can list paired
  /// Bluetooth devices that are currently turned off.
  Future<bool> requestBluetoothPermission() async {
    try {
      final granted =
          await _adminAudioDevicesChannel.invokeMethod<bool>(
            'requestBluetoothConnectPermission',
          ) ??
          false;
      _bluetoothPermissionRequired = !granted;
      if (granted) {
        await refreshDevices();
      } else {
        notifyListeners();
      }
      return granted;
    } on PlatformException catch (e) {
      _log.warning('requestBluetoothPermission failed: ${e.code} ${e.message}');
      _bluetoothPermissionRequired = true;
      notifyListeners();
      return false;
    }
  }

  /// Updates and persists the config for one admin-visible device entry.
  Future<void> saveConfig(AudioDeviceConfig config) async {
    _log.info(
      'saveConfig: key=${config.configKey} '
      'volumeLimitDb=${config.volumeLimitDb} volumeLimitFactor=${config.volumeLimitFactor.toStringAsFixed(4)}',
    );
    _configs[config.configKey] = config;
    await _persistConfigs();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------

  Future<void> _loadConfigs() async {
    final prefs = di<SharedPreferencesWithCache>();
    final raw = prefs.getString(_kPrefsConfigsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _configs = {
          for (final item in list)
            AudioDeviceConfig.fromJson(item as Map<String, dynamic>).configKey:
                AudioDeviceConfig.fromJson(item),
        };
        _log.info('_loadConfigs: loaded ${_configs.length} configs');
      } catch (e) {
        _log.warning('_loadConfigs: parse error: $e');
      }
    }
  }

  Future<void> _persistConfigs() async {
    final prefs = di<SharedPreferencesWithCache>();
    final json = jsonEncode(_configs.values.map((c) => c.toJson()).toList());
    await prefs.setString(_kPrefsConfigsKey, json);
  }

  Future<void> _refreshKnownBluetoothDevices() async {
    try {
      final result =
          await _adminAudioDevicesChannel.invokeListMethod<dynamic>(
            'getBondedBluetoothDevices',
          ) ??
          const [];

      _knownBluetoothDevices =
          result
              .whereType<Map<dynamic, dynamic>>()
              .map(KnownBluetoothDevice.fromMap)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      _bluetoothPermissionRequired = false;
    } on PlatformException catch (e) {
      if (e.code == 'BLUETOOTH_PERMISSION_DENIED') {
        _bluetoothPermissionRequired = true;
        _knownBluetoothDevices = [];
        return;
      }
      _log.warning(
        '_refreshKnownBluetoothDevices failed: ${e.code} ${e.message}',
      );
    }
  }

  Future<void> _refreshNamedAvailableDevices() async {
    try {
      final result =
          await _adminAudioDevicesChannel.invokeListMethod<dynamic>(
            'getAvailableMediaDevices',
          ) ??
          const [];

      _namedAvailableDevices = result
          .whereType<Map<dynamic, dynamic>>()
          .map(NamedAvailableAudioDevice.fromMap)
          .toList();
    } on PlatformException catch (e) {
      _log.warning(
        '_refreshNamedAvailableDevices failed: ${e.code} ${e.message}',
      );
      _namedAvailableDevices = [];
    }
  }

  // -------------------------------------------------------------------------
  // Live device change stream
  // -------------------------------------------------------------------------

  void _subscribeToDeviceStream() {
    _streamSub = _audioDeviceEventsChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          unawaited(_handleAudioStateChanged(AudioState.fromMap(event)));
        }
      },
      onError: (Object e) => _log.warning('audioDeviceEventsStream error: $e'),
    );
  }

  Future<void> _handleAudioStateChanged(AudioState state) async {
    // Refresh secondary data so Bluetooth address → config key matching works.
    await Future.wait([
      _refreshNamedAvailableDevices(),
      _refreshKnownBluetoothDevices(),
    ]);

    final freshDevices = _namedAvailableDevices
        .map((n) => AudioDevice(id: n.id, type: n.type))
        .toList();
    _availableDevices = freshDevices.isNotEmpty
        ? freshDevices
        : state.availableDevices;

    _currentDevice = _resolveCurrentDevice();
    _log.info(
      'audioStateStream: ${_availableDevices.length} devices '
      '(${_availableDevices.map((d) => d.type.name).join(", ")}), '
      'current=${_currentDevice?.type.name}',
    );
    notifyListeners();
  }

  /// Determines which output device Android is most likely routing media to.
  ///
  /// Android automatically routes media audio by priority:
  /// Bluetooth A2DP > wired headset > built-in speaker.
  AudioDevice? _resolveCurrentDevice() {
    if (_availableDevices.isEmpty) return null;

    // Prefer Bluetooth A2DP (high-quality stereo) for media playback.
    for (final named in _namedAvailableDevices) {
      if (named.type == AudioSourceType.bluetooth && named.isBluetoothA2dp) {
        return AudioDevice(id: named.id, type: named.type);
      }
    }

    // Android media routing priority.
    const typePriority = [
      AudioSourceType.bluetooth,
      AudioSourceType.wiredHeadset,
      AudioSourceType.carAudio,
      AudioSourceType.builtinSpeaker,
      AudioSourceType.builtinReceiver,
      AudioSourceType.unknown,
    ];
    for (final type in typePriority) {
      final device = _firstAvailableDeviceForType(type);
      if (device != null) return device;
    }
    return _availableDevices.first;
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  bool _shouldExposeTypeEntry(AudioSourceType type) {
    if (type == AudioSourceType.builtinSpeaker) return true;
    if (_configs.containsKey(_typeConfigKey(type))) return true;
    return _firstAvailableDeviceForType(type) != null;
  }

  AudioDevice? _firstAvailableDeviceForType(AudioSourceType type) {
    for (final device in _availableDevices) {
      if (device.type == type) return device;
    }
    return null;
  }

  NamedAvailableAudioDevice? _namedAvailableDeviceForAudioDevice(
    AudioDevice device,
  ) {
    for (final named in _namedAvailableDevices) {
      if (named.id == device.id && named.type == device.type) {
        return named;
      }
    }
    return null;
  }

  AudioDevice? _availableBluetoothDeviceForAddress(String normalizedAddress) {
    for (final named in _namedAvailableDevices) {
      if (named.type == AudioSourceType.bluetooth &&
          named.normalizedAddress == normalizedAddress) {
        for (final device in _availableDevices) {
          if (device.id == named.id &&
              device.type == AudioSourceType.bluetooth) {
            return device;
          }
        }
      }
    }
    return null;
  }

  AudioDevice? _availableBluetoothDeviceForConfigKey(String configKey) {
    if (!_isBluetoothSpecificConfigKey(configKey)) return null;
    return _availableBluetoothDeviceForAddress(
      configKey.substring('bluetooth:'.length),
    );
  }

  bool _isCurrentConfigKey(String configKey) {
    if (_currentDevice == null) return false;
    return configKeyForAvailableDevice(_currentDevice!) ==
        _normalizeStoredConfigKey(configKey);
  }

  String? _preferredSystemLabelForAvailableDevice(AudioDevice device) {
    final named = _namedAvailableDeviceForAudioDevice(device);
    final name = named?.name.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return null;
  }

  String? _preferredSystemLabelForConfigKey(
    String configKey, {
    AudioSourceType? fallbackType,
  }) {
    final normalizedConfigKey = _normalizeStoredConfigKey(configKey);
    if (_isBluetoothSpecificConfigKey(normalizedConfigKey)) {
      final address = normalizedConfigKey.substring('bluetooth:'.length);
      for (final known in _knownBluetoothDevices) {
        if (known.normalizedAddress == address &&
            known.name.trim().isNotEmpty) {
          return known.name.trim();
        }
      }
      final available = _availableBluetoothDeviceForAddress(address);
      if (available != null) {
        return _preferredSystemLabelForAvailableDevice(available);
      }
      return null;
    }

    final type = fallbackType ?? _typeForConfigKey(normalizedConfigKey);
    final namedMatches = _namedAvailableDevices
        .where((device) => device.type == type)
        .toList();

    if (_currentDevice != null) {
      for (final device in namedMatches) {
        if (device.id == _currentDevice!.id && device.name.trim().isNotEmpty) {
          return device.name.trim();
        }
      }
    }

    if (namedMatches.length == 1) {
      final name = namedMatches.first.name.trim();
      if (name.isNotEmpty) return name;
    }

    return null;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
