package dev.glitch.alhuda

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.hardware.Sensor
import android.hardware.SensorManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

object AdhanVolumeManager {
    @Volatile
    var isAdhanPlaying: Boolean = false
        private set

    @Volatile
    var playbackStartTime: Long = 0L
        private set

    @Volatile
    private var lastInternalVolumeChangeTime: Long = 0L

    private val channels = mutableSetOf<WeakReference<MethodChannel>>()
    private var volumeReceiver: BroadcastReceiver? = null
    private var appContext: Context? = null
    private var previousAlarmVolume: Int? = null

    fun registerChannel(channel: MethodChannel) {
        synchronized(channels) {
            channels.removeAll { it.get() == null || it.get() == channel }
            channels.add(WeakReference(channel))
        }
    }

    fun unregisterChannel(channel: MethodChannel) {
        synchronized(channels) {
            channels.removeAll { it.get() == null || it.get() == channel }
        }
    }

    fun setAdhanVolume(context: Context, volumePercent: Double) {
        lastInternalVolumeChangeTime = System.currentTimeMillis()
        val appCtx = context.applicationContext ?: appContext ?: return
        try {
            val audioManager = appCtx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            if (previousAlarmVolume == null) {
                previousAlarmVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            }
            val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            val target = (maxVol * volumePercent.coerceIn(0.1, 1.0)).toInt().coerceIn(1, maxVol)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, target, 0)
        } catch (_: Exception) {}
    }

    fun restoreAlarmVolume(context: Context?) {
        lastInternalVolumeChangeTime = System.currentTimeMillis()
        val prev = previousAlarmVolume ?: return
        val appCtx = context?.applicationContext ?: appContext ?: return
        try {
            val audioManager = appCtx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            audioManager?.setStreamVolume(AudioManager.STREAM_ALARM, prev, 0)
        } catch (_: Exception) {}
        previousAlarmVolume = null
    }

    fun startAdhanMonitoring(context: Context) {
        val appCtx = context.applicationContext
        appContext = appCtx
        isAdhanPlaying = true
        playbackStartTime = System.currentTimeMillis()
        lastInternalVolumeChangeTime = System.currentTimeMillis()
        registerVolumeReceiver(appCtx)
    }

    fun stopAdhanMonitoring(context: Context?) {
        isAdhanPlaying = false
        val ctx = context?.applicationContext ?: appContext
        unregisterVolumeReceiver(ctx)
        restoreAlarmVolume(ctx)
    }

    fun stopAdhan(context: Context?) {
        if (!isAdhanPlaying) return
        isAdhanPlaying = false

        val ctx = context?.applicationContext ?: appContext
        unregisterVolumeReceiver(ctx)
        restoreAlarmVolume(ctx)

        // 1. Cancel Adhan notifications specifically via system NotificationManager
        try {
            val notificationManager = ctx?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(9999)
            notificationManager?.cancel(9998)
            for (id in 1000..1999) {
                notificationManager?.cancel(id)
            }
        } catch (_: Exception) {}

        // 2. Abandon audio focus if possible
        try {
            val audioManager = ctx?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            audioManager?.abandonAudioFocus(null)
        } catch (_: Exception) {}

        // 3. Notify all active Flutter isolates/engines
        notifyFlutterToStop()

        // 4. Send action to ActionBroadcastReceiver so background isolate cleans up if active
        try {
            val stopIntent = Intent(ctx, com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver::class.java).apply {
                action = com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_TAPPED
                putExtra("actionId", "stop_adhan")
                putExtra("notificationId", 9999)
            }
            ctx?.sendBroadcast(stopIntent)
        } catch (_: Exception) {}
    }

    private fun registerVolumeReceiver(context: Context) {
        if (volumeReceiver != null) return
        try {
            volumeReceiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context?, intent: Intent?) {
                    if (!isAdhanPlaying) return
                    if (intent?.action != "android.media.VOLUME_CHANGED_ACTION") return

                    val now = System.currentTimeMillis()
                    // 1. Grace period: Ignore volume events during first 2 seconds of playback
                    if (now - playbackStartTime < 2000L) return

                    // 2. Ignore volume events triggered by app's own setAdhanVolume (e.g. volume slider)
                    if (now - lastInternalVolumeChangeTime < 2000L) return

                    // 3. Verify that volume value actually changed
                    val prevVol = intent.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", -1)
                    val currVol = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", -1)
                    if (prevVol != -1 && currVol != -1 && prevVol == currVol) {
                        return
                    }

                    stopAdhan(c ?: context)
                }
            }
            val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(volumeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(volumeReceiver, filter)
            }
        } catch (_: Exception) {}
    }

    private fun unregisterVolumeReceiver(context: Context?) {
        if (volumeReceiver != null && context != null) {
            try {
                context.unregisterReceiver(volumeReceiver)
            } catch (_: Exception) {}
            volumeReceiver = null
        }
    }

    fun notifyFlutterToStop() {
        val handler = Handler(Looper.getMainLooper())
        handler.post {
            synchronized(channels) {
                val iterator = channels.iterator()
                while (iterator.hasNext()) {
                    val ref = iterator.next()
                    val ch = ref.get()
                    if (ch != null) {
                        try {
                            ch.invokeMethod("stopAdhan", null)
                        } catch (_: Exception) {}
                    } else {
                        iterator.remove()
                    }
                }
            }
        }
    }

    fun pauseAdhan() {
        val handler = Handler(Looper.getMainLooper())
        handler.post {
            synchronized(channels) {
                val iterator = channels.iterator()
                while (iterator.hasNext()) {
                    val ref = iterator.next()
                    val ch = ref.get()
                    if (ch != null) {
                        try {
                            ch.invokeMethod("pauseAdhan", null)
                        } catch (_: Exception) {}
                    } else {
                        iterator.remove()
                    }
                }
            }
        }
    }

    fun resumeAdhan() {
        val handler = Handler(Looper.getMainLooper())
        handler.post {
            synchronized(channels) {
                val iterator = channels.iterator()
                while (iterator.hasNext()) {
                    val ref = iterator.next()
                    val ch = ref.get()
                    if (ch != null) {
                        try {
                            ch.invokeMethod("resumeAdhan", null)
                        } catch (_: Exception) {}
                    } else {
                        iterator.remove()
                    }
                }
            }
        }
    }
}

class MainActivity : FlutterActivity() {
    private val SENSOR_CHANNEL = "com.example.alhuda/sensors"
    private val ADHAN_CHANNEL = "com.example.alhuda/adhan"
    private var adhanMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Sensor Channel for Qibla
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hasMagnetometer" || call.method == "hasCompassSensor") {
                try {
                    val sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
                    val magSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
                    val rotSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
                    result.success(magSensor != null || rotSensor != null)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }

        // Adhan Channel for Volume Buttons & Stop Controls
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADHAN_CHANNEL)
        adhanMethodChannel = channel
        AdhanVolumeManager.registerChannel(channel)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdhanMonitoring" -> {
                    AdhanVolumeManager.startAdhanMonitoring(applicationContext)
                    result.success(true)
                }
                "stopAdhanMonitoring" -> {
                    AdhanVolumeManager.stopAdhanMonitoring(applicationContext)
                    result.success(true)
                }
                "stopAdhan" -> {
                    AdhanVolumeManager.stopAdhan(applicationContext)
                    result.success(true)
                }
                "pauseAdhan" -> {
                    AdhanVolumeManager.pauseAdhan()
                    result.success(true)
                }
                "resumeAdhan" -> {
                    AdhanVolumeManager.resumeAdhan()
                    result.success(true)
                }
                "isAdhanPlaying" -> {
                    result.success(AdhanVolumeManager.isAdhanPlaying)
                }
                "setAdhanVolume" -> {
                    val volume = (call.argument<Double>("volume") ?: 1.0)
                    AdhanVolumeManager.setAdhanVolume(applicationContext, volume)
                    result.success(true)
                }
                "restoreAlarmVolume" -> {
                    AdhanVolumeManager.restoreAlarmVolume(applicationContext)
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            powerManager?.isIgnoringBatteryOptimizations(packageName) ?: true
                        } else {
                            true
                        }
                        result.success(isIgnoring)
                    } catch (_: Exception) {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (_: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            val keyCode = event.keyCode
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                if (AdhanVolumeManager.isAdhanPlaying &&
                    System.currentTimeMillis() - AdhanVolumeManager.playbackStartTime > 800L
                ) {
                    AdhanVolumeManager.stopAdhan(applicationContext)
                    return true // Consume key event to silence Adhan without altering system volume
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        adhanMethodChannel?.let { AdhanVolumeManager.unregisterChannel(it) }
        adhanMethodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
