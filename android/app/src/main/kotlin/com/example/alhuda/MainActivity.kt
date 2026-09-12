package com.example.alhuda

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.hardware.Sensor
import android.hardware.SensorManager
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
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

    private val channels = mutableSetOf<WeakReference<MethodChannel>>()
    private var volumeReceiver: BroadcastReceiver? = null
    private var contentObserver: ContentObserver? = null
    private var appContext: Context? = null

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

    fun startAdhanMonitoring(context: Context) {
        val appCtx = context.applicationContext
        appContext = appCtx
        isAdhanPlaying = true

        registerVolumeReceiver(appCtx)
        registerContentObserver(appCtx)
    }

    fun stopAdhanMonitoring(context: Context?) {
        isAdhanPlaying = false
        val ctx = context?.applicationContext ?: appContext
        unregisterVolumeReceiver(ctx)
        unregisterContentObserver(ctx)
    }

    fun stopAdhan(context: Context?) {
        if (!isAdhanPlaying) return
        isAdhanPlaying = false

        val ctx = context?.applicationContext ?: appContext
        unregisterVolumeReceiver(ctx)
        unregisterContentObserver(ctx)

        // 1. Cancel Adhan notification via system NotificationManager
        try {
            val notificationManager = ctx?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancelAll()
        } catch (_: Exception) {}

        // 2. Abandon audio focus if possible
        try {
            val audioManager = ctx?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            audioManager?.abandonAudioFocus(null)
        } catch (_: Exception) {}

        // 3. Notify all active Flutter isolates/engines
        notifyFlutterToStop()
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

    private fun registerVolumeReceiver(context: Context) {
        if (volumeReceiver != null) return
        try {
            volumeReceiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context?, intent: Intent?) {
                    if (isAdhanPlaying && intent?.action == "android.media.VOLUME_CHANGED_ACTION") {
                        stopAdhan(c ?: context)
                    }
                }
            }
            val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(volumeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(volumeReceiver, filter)
            }
        } catch (_: Exception) {
            // Receiver registration fallback to ContentObserver
        }
    }

    private fun unregisterVolumeReceiver(context: Context?) {
        if (volumeReceiver != null && context != null) {
            try {
                context.unregisterReceiver(volumeReceiver)
            } catch (_: Exception) {}
            volumeReceiver = null
        }
    }

    private fun registerContentObserver(context: Context) {
        if (contentObserver != null) return
        try {
            contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    super.onChange(selfChange)
                    if (isAdhanPlaying) {
                        stopAdhan(context)
                    }
                }
            }
            context.contentResolver.registerContentObserver(
                Settings.System.CONTENT_URI,
                true,
                contentObserver!!
            )
        } catch (_: Exception) {}
    }

    private fun unregisterContentObserver(context: Context?) {
        if (contentObserver != null && context != null) {
            try {
                context.contentResolver.unregisterContentObserver(contentObserver!!)
            } catch (_: Exception) {}
            contentObserver = null
        }
    }
}

class MainActivity : FlutterActivity() {
    private val SENSOR_CHANNEL = "com.example.alhuda/sensors"
    private val ADHAN_CHANNEL = "com.example.alhuda/adhan"
    private var adhanMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Sensor Channel for Qibla
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hasMagnetometer") {
                try {
                    val sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
                    val magSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
                    result.success(magSensor != null)
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
                "isAdhanPlaying" -> {
                    result.success(AdhanVolumeManager.isAdhanPlaying)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            val keyCode = event.keyCode
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                if (AdhanVolumeManager.isAdhanPlaying) {
                    AdhanVolumeManager.stopAdhan(applicationContext)
                    return true // Consume key event to silence without altering volume level
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
