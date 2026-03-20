package org.appsfrommeforyou.media_player_for_kids

import android.Manifest
import android.bluetooth.BluetoothManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    private val adminAudioDevicesChannelName = "player/admin_audio_devices"
    private val audioDeviceEventsChannelName = "player/audio_device_events"
    private val bluetoothConnectPermissionRequestCode = 30101
    private var pendingBluetoothPermissionResult: MethodChannel.Result? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var audioDeviceCallback: AudioDeviceCallback? = null

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            adminAudioDevicesChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableMediaDevices" -> {
                    result.success(getAvailableMediaDevices())
                }

                "getBondedBluetoothDevices" -> {
                    if (!hasBluetoothConnectPermission()) {
                        result.error(
                            "BLUETOOTH_PERMISSION_DENIED",
                            "Bluetooth permission is required to list paired devices.",
                            null,
                        )
                    } else {
                        result.success(getBondedBluetoothDevices())
                    }
                }

                "requestBluetoothConnectPermission" -> {
                    requestBluetoothConnectPermission(result)
                }

                "setPreferredMediaDevice" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("INVALID_ARGUMENT", "deviceId is required", null)
                    } else {
                        result.success(setPreferredMediaDevice(deviceId))
                    }
                }

                "clearPreferredMediaDevice" -> {
                    result.success(clearPreferredMediaDevice())
                }

                "getPreferredMediaDevice" -> {
                    result.success(getPreferredMediaDevice())
                }

                else -> result.notImplemented()
            }
        }

        // EventChannel for device add/remove notifications
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            audioDeviceEventsChannelName,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                registerAudioDeviceCallback()
            }

            override fun onCancel(arguments: Any?) {
                unregisterAudioDeviceCallback()
                eventSink = null
            }
        })
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != bluetoothConnectPermissionRequestCode) {
            return
        }

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingBluetoothPermissionResult?.success(granted)
        pendingBluetoothPermissionResult = null
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.BLUETOOTH_CONNECT,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestBluetoothConnectPermission(result: MethodChannel.Result) {
        if (hasBluetoothConnectPermission()) {
            result.success(true)
            return
        }

        if (pendingBluetoothPermissionResult != null) {
            result.error(
                "PERMISSION_REQUEST_IN_PROGRESS",
                "A Bluetooth permission request is already in progress.",
                null,
            )
            return
        }

        pendingBluetoothPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
            bluetoothConnectPermissionRequestCode,
        )
    }

    private fun getBondedBluetoothDevices(): List<Map<String, String>> {
        val bluetoothManager = getSystemService(BluetoothManager::class.java)
        val adapter = bluetoothManager?.adapter ?: return emptyList()

        return adapter.bondedDevices
            .sortedBy { it.name?.lowercase() ?: "" }
            .map { device ->
                mapOf(
                    "name" to (device.name ?: "Bluetooth device"),
                    "address" to device.address,
                )
            }
    }

    private fun getAvailableMediaDevices(): List<Map<String, String>> {
        val audioManager = getSystemService(AudioManager::class.java) ?: return emptyList()

        return audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .mapNotNull { device ->
                val type = mapAudioDeviceType(device.type) ?: return@mapNotNull null
                mapOf(
                    "id" to device.id.toString(),
                    "type" to type,
                    "androidType" to device.type.toString(),
                    "name" to (device.productName?.toString()?.takeIf { it.isNotBlank() }
                        ?: defaultNameForType(type)),
                    "address" to device.address,
                )
            }
    }

    private fun mapAudioDeviceType(type: Int): String? {
        return when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "builtinSpeaker"
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "builtinReceiver"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bluetooth"
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_USB_ACCESSORY -> "wiredHeadset"
            AudioDeviceInfo.TYPE_LINE_ANALOG,
            AudioDeviceInfo.TYPE_LINE_DIGITAL,
            AudioDeviceInfo.TYPE_HDMI,
            AudioDeviceInfo.TYPE_HDMI_ARC,
            AudioDeviceInfo.TYPE_HDMI_EARC -> "unknown"
            AudioDeviceInfo.TYPE_BUS -> "carAudio"
            else -> null
        }
    }

    private fun defaultNameForType(type: String): String {
        return when (type) {
            "builtinSpeaker" -> "Speaker"
            "builtinReceiver" -> "Phone Speaker"
            "bluetooth" -> "Bluetooth"
            "wiredHeadset" -> "Headphones"
            "carAudio" -> "Car Audio"
            else -> "Audio device"
        }
    }

    // -----------------------------------------------------------------------
    // Media device preference tracking
    // -----------------------------------------------------------------------
    //
    // Android has no public API to force media audio to a specific output
    // device at the system level (setPreferredDeviceForStrategy is @SystemApi).
    // Media routing is automatic: A2DP when BT connects, wired when plugged in,
    // speaker as fallback.
    //
    // We track the user's preferred device here so the Dart side can apply the
    // matching volume limit. The actual audio routing follows Android's automatic
    // priority rules.

    private var preferredDeviceId: Int? = null

    private fun setPreferredMediaDevice(deviceId: Int): Boolean {
        val audioManager = getSystemService(AudioManager::class.java) ?: return false
        val device = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .firstOrNull { it.id == deviceId }
        if (device == null) {
            Log.w(TAG, "setPreferredMediaDevice: device $deviceId not found in outputs")
            return false
        }

        preferredDeviceId = deviceId
        Log.i(TAG, "setPreferredMediaDevice($deviceId) type=${device.type} " +
            "product=${device.productName}")
        return true
    }

    private fun clearPreferredMediaDevice(): Boolean {
        preferredDeviceId = null
        Log.i(TAG, "clearPreferredMediaDevice")
        return true
    }

    private fun getPreferredMediaDevice(): Map<String, String>? {
        val id = preferredDeviceId ?: return null
        val audioManager = getSystemService(AudioManager::class.java) ?: return null
        val device = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .firstOrNull { it.id == id }
        if (device == null) {
            // Device disappeared — clear stale preference
            preferredDeviceId = null
            return null
        }
        val type = mapAudioDeviceType(device.type) ?: return null
        return mapOf(
            "id" to device.id.toString(),
            "type" to type,
        )
    }

    // -----------------------------------------------------------------------
    // Device change event stream
    // -----------------------------------------------------------------------

    private fun registerAudioDeviceCallback() {
        val audioManager = getSystemService(AudioManager::class.java) ?: return
        audioDeviceCallback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                Log.i(TAG, "onAudioDevicesAdded: ${addedDevices.map { "${it.id}/${it.type}" }}")
                sendDeviceStateEvent()
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                Log.i(TAG, "onAudioDevicesRemoved: ${removedDevices.map { "${it.id}/${it.type}" }}")
                sendDeviceStateEvent()
            }
        }
        audioManager.registerAudioDeviceCallback(audioDeviceCallback, mainHandler)
    }

    private fun unregisterAudioDeviceCallback() {
        val audioManager = getSystemService(AudioManager::class.java) ?: return
        audioDeviceCallback?.let { audioManager.unregisterAudioDeviceCallback(it) }
        audioDeviceCallback = null
    }

    private fun sendDeviceStateEvent() {
        val devices = getAvailableMediaDevices()
        val preferred = getPreferredMediaDevice()
        val state = mapOf(
            "availableDevices" to devices,
            "selectedDevice" to preferred,
        )
        mainHandler.post { eventSink?.success(state) }
    }
}
