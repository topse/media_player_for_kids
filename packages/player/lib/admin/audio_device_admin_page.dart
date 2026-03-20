import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:player/audio_device_service.dart';
import 'package:player/audio_types.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('audio_device_admin_page');

/// Admin page for configuring audio output devices.
///
/// For each configurable output device entry the admin can set a volume-limit
/// slider (-18 dB … 0 dB). The app cannot switch Android media output
/// programmatically — routing is automatic — so only volume attenuation is
/// configurable.
class AudioDeviceAdminPage extends StatefulWidget {
  const AudioDeviceAdminPage({super.key});

  @override
  State<AudioDeviceAdminPage> createState() => _AudioDeviceAdminPageState();
}

class _AudioDeviceAdminPageState extends State<AudioDeviceAdminPage> {
  @override
  void initState() {
    super.initState();
    final svc = di<AudioDeviceService>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Always refresh on open so bonded Bluetooth list and named device info
      // are up-to-date without requiring a manual tap.
      await svc.refreshDevices();
      // If permission is still missing after refresh, request it now.
      if (mounted && svc.bluetoothPermissionRequired) {
        svc.requestBluetoothPermission();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: di<AudioDeviceService>(),
      builder: (context, _) {
        final svc = di<AudioDeviceService>();
        final entries = svc.adminVisibleDevices;

        return Scaffold(
          appBar: AppBar(title: const Text('Audio Output Devices')),
          body: Column(
            children: [
              if (svc.bluetoothPermissionRequired)
                _BluetoothPermissionBanner(
                  onGrant: () => svc.requestBluetoothPermission(),
                ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          'No audio devices found.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final cfg = svc.configForConfigKey(
                            entry.configKey,
                            fallbackType: entry.type,
                          );
                          return _DeviceConfigCard(
                            entry: entry,
                            config: cfg,
                            bluetoothPermissionRequired:
                                svc.bluetoothPermissionRequired,
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

// ---------------------------------------------------------------------------
// _BluetoothPermissionBanner
// ---------------------------------------------------------------------------

class _BluetoothPermissionBanner extends StatelessWidget {
  final VoidCallback onGrant;

  const _BluetoothPermissionBanner({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.bluetooth_disabled,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Allow Bluetooth access to list all paired devices, '
                'even when they are turned off.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onGrant, child: const Text('Allow')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DeviceConfigCard
// ---------------------------------------------------------------------------

class _DeviceConfigCard extends StatefulWidget {
  final AdminAudioDeviceEntry entry;
  final AudioDeviceConfig config;
  final bool bluetoothPermissionRequired;

  const _DeviceConfigCard({
    required this.entry,
    required this.config,
    required this.bluetoothPermissionRequired,
  });

  @override
  State<_DeviceConfigCard> createState() => _DeviceConfigCardState();
}

class _DeviceConfigCardState extends State<_DeviceConfigCard> {
  late AudioDeviceConfig _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.config;
  }

  @override
  void didUpdateWidget(_DeviceConfigCard old) {
    super.didUpdateWidget(old);
    if (old.config != widget.config) {
      _draft = widget.config;
    }
  }

  void _save(AudioDeviceConfig updated) {
    _log.info(
      '_save: key=${updated.configKey} volumeLimitDb=${updated.volumeLimitDb}',
    );
    setState(() => _draft = updated);
    di<AudioDeviceService>().saveConfig(updated);
  }

  IconData _iconForType(AudioSourceType type) {
    switch (type) {
      case AudioSourceType.bluetooth:
        return Icons.bluetooth_audio;
      case AudioSourceType.wiredHeadset:
        return Icons.headphones;
      case AudioSourceType.carAudio:
        return Icons.directions_car;
      case AudioSourceType.builtinSpeaker:
      case AudioSourceType.builtinReceiver:
        return Icons.volume_up;
      case AudioSourceType.airplay:
        return Icons.airplay;
      case AudioSourceType.unknown:
        return Icons.speaker;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[widget.entry.type.name];
    if (widget.entry.isCurrent) {
      subtitleParts.add('active');
    }
    if (widget.entry.isAvailable) {
      subtitleParts.add('available now');
    } else if (widget.entry.isBluetooth && widget.entry.address.isNotEmpty) {
      subtitleParts.add('paired, currently unavailable');
    } else {
      subtitleParts.add('currently unavailable');
    }

    return ExpansionTile(
      leading: Stack(
        children: [
          Icon(_iconForType(widget.entry.type), size: 28),
          if (widget.entry.isCurrent)
            const Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.circle, size: 10, color: Colors.green),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(child: Text(widget.entry.systemName)),
          if (widget.entry.isCurrent) ...[
            const SizedBox(width: 6),
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'active',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitleParts.join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.entry.isBluetooth)
                _BluetoothKnownDevicesSection(
                  systemName: widget.entry.systemName,
                  address: widget.entry.address,
                  isAvailable: widget.entry.isAvailable,
                  permissionRequired: widget.bluetoothPermissionRequired,
                ),
              if (widget.entry.isBluetooth) const SizedBox(height: 16),

              // Volume limit slider
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Volume limit',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    '${_draft.volumeLimitDb.toStringAsFixed(1)} dB',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Slider(
                value: _draft.volumeLimitDb,
                min: -24.0,
                max: 0.0,
                divisions: 36,
                label: '${_draft.volumeLimitDb.toStringAsFixed(1)} dB',
                onChanged: (v) => _save(_draft.copyWith(volumeLimitDb: v)),
              ),
              Text(
                _draft.volumeLimitDb == 0.0
                    ? 'No limit'
                    : 'Audio limited to ${_draft.volumeLimitDb.toStringAsFixed(1)} dB below maximum',
                style: theme.textTheme.bodySmall,
              ),

              if (!widget.entry.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.entry.isBluetooth && widget.entry.address.isNotEmpty
                        ? 'This output is known to Android but is not currently routeable. Volume limit will apply when it becomes available.'
                        : 'This output type is not currently routeable, but its settings are still saved.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BluetoothKnownDevicesSection extends StatelessWidget {
  final String systemName;
  final String address;
  final bool isAvailable;
  final bool permissionRequired;

  const _BluetoothKnownDevicesSection({
    required this.systemName,
    required this.address,
    required this.isAvailable,
    required this.permissionRequired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (permissionRequired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paired Bluetooth devices', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(
            'Allow Bluetooth access to show headphones and speakers that are paired with Android, even when they are currently off.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                di<AudioDeviceService>().requestBluetoothPermission(),
            icon: const Icon(Icons.bluetooth_audio),
            label: const Text('Allow Bluetooth Access'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bluetooth device', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        if (address.isEmpty)
          Text(
            'No specific paired Bluetooth device is known yet. Once Android reports a paired headset, it will get its own entry here.',
            style: theme.textTheme.bodySmall,
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              isAvailable ? Icons.headphones : Icons.headphones_outlined,
            ),
            title: Text(systemName),
            subtitle: Text(address),
          ),
      ],
    );
  }
}
