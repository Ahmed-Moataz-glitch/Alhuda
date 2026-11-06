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

    @Volatile
    private var internalTargetAlarmVolume: Int = -1

    private val channels = mutableSetOf<WeakReference<MethodChannel>>()
    private var volumeReceiver: BroadcastReceiver? = null
    private var appContext: Context? = null
    private var previousAlarmVolume: Int? = null

    fun isAdhanActive(context: Context?): Boolean {
        if (isAdhanPlaying || AdhanForegroundService.isPlaying) return true
        val ctx = context?.applicationContext ?: appContext ?: return false
        try {
            val notificationManager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
            val activeNotifications = notificationManager.activeNotifications ?: return false
            return activeNotifications.any { notif ->
                val hasAdhanAction = notif.notification.actions?.any { action ->
                    action.title?.toString()?.contains("الأذان") == true
                } == true
                val channelId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) notif.notification.channelId else null
                val isAdhanChannel = channelId != null && channelId.startsWith("adhan_")
                hasAdhanAction || notif.id == 9999 || notif.id == 9998 || (isAdhanChannel && notif.id != 8888)
            }
        } catch (_: Exception) {
            return false
        }
    }

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
        // Volume scaling is handled directly by MediaPlayer.setVolume and Flutter AudioPlayer.
        // We intentionally do not alter the system-wide STREAM_ALARM to avoid triggering spurious volume broadcasts.
    }

    fun restoreAlarmVolume(context: Context?) {
        // No-op since global STREAM_ALARM is not altered.
    }

    fun startAdhanMonitoring(context: Context) {
        val appCtx = context.applicationContext
        appContext = appCtx
        isAdhanPlaying = true
        playbackStartTime = System.currentTimeMillis()
        registerVolumeReceiver(appCtx)
    }

    fun stopAdhanMonitoring(context: Context?) {
        isAdhanPlaying = false
        val ctx = context?.applicationContext ?: appContext
        unregisterVolumeReceiver(ctx)
    }

    fun stopAdhan(context: Context?, fromFlutter: Boolean = false) {
        val ctx = context?.applicationContext ?: appContext
        isAdhanPlaying = false
        unregisterVolumeReceiver(ctx)

        if (ctx != null) {
            AdhanForegroundService.stopAdhan(ctx)
            AdhanAlarmReceiver.stopPrePrayerVoice()
        }

        // 1. Cancel Adhan notifications specifically via system NotificationManager
        try {
            val notificationManager = ctx?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(0)
            notificationManager?.cancel(9999)
            notificationManager?.cancel(9998)
            for (id in 1000..1999) {
                notificationManager?.cancel(id)
            }
        } catch (_: Exception) {}

        // 2. Only notify Flutter if the stop was NOT requested by Flutter itself
        if (!fromFlutter) {
            notifyFlutterToStop()
            AdhanPlugin.notifyFlutterToStop()
        }

        // 3. Send action to ActionBroadcastReceiver so background isolate cleans up if active
        try {
            val stopIntent = Intent(ctx, com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver::class.java).apply {
                action = com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_TAPPED
                putExtra("actionId", "stop_adhan")
                putExtra("notificationId", 0)
            }
            ctx?.sendBroadcast(stopIntent)
        } catch (_: Exception) {}
    }

    fun registerVolumeReceiver(context: Context) {
        if (volumeReceiver != null) return
        try {
            volumeReceiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context?, intent: Intent?) {
                    if (intent?.action != "android.media.VOLUME_CHANGED_ACTION") return
                    val ctx = c ?: context
                    if (!isAdhanActive(ctx)) return

                    val now = System.currentTimeMillis()
                    // 500ms initial guard to ignore initial broadcast at registration
                    if (playbackStartTime > 0L && now - playbackStartTime < 500L) return

                    val currVol = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", -1)
                    val prevVol = intent.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", -1)

                    // Ignore if volume didn't actually change
                    if (currVol == prevVol && currVol != -1) return

                    // User pressed hardware volume button while phone is locked or in background
                    stopAdhan(ctx)
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
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun onResume() {
        super.onResume()
        volumeControlStream = AudioManager.STREAM_MUSIC
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

        // Adhan Channel for Volume & Controls
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADHAN_CHANNEL)
        adhanMethodChannel = channel
        AdhanVolumeManager.registerChannel(channel)
        AdhanPlugin.registerChannel(channel)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdhanService" -> {
                    val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                    val soundId = call.argument<String>("soundId") ?: "qatami"
                    val rawRes = call.argument<String>("rawRes")
                    val title = call.argument<String>("title")
                    val muadhin = call.argument<String>("muadhin")
                    val volume = call.argument<Double>("volume") ?: 1.0
                    val isAlarmMode = call.argument<Boolean>("isAlarmMode") ?: true
                    AdhanForegroundService.startAdhan(
                        context = applicationContext,
                        prayerName = prayerName,
                        soundId = soundId,
                        rawRes = rawRes,
                        title = title,
                        muadhin = muadhin,
                        volume = volume,
                        isAlarmMode = isAlarmMode
                    )
                    result.success(true)
                }
                "startAdhanMonitoring" -> {
                    AdhanVolumeManager.startAdhanMonitoring(applicationContext)
                    result.success(true)
                }
                "stopAdhanMonitoring" -> {
                    AdhanVolumeManager.stopAdhanMonitoring(applicationContext)
                    result.success(true)
                }
                "stopAdhan" -> {
                    AdhanForegroundService.stopAdhan(applicationContext)
                    AdhanVolumeManager.stopAdhan(applicationContext, fromFlutter = true)
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
                    result.success(AdhanForegroundService.isPlaying || AdhanVolumeManager.isAdhanActive(applicationContext))
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
                            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                            val isIgnoring = powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                            if (!isIgnoring) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                            }
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
                "scheduleNativeAlarms" -> {
                    try {
                        val alarms = call.argument<List<Map<String, Any>>>("alarms") ?: emptyList()
                        AdhanAlarmScheduler.scheduleAlarms(applicationContext, alarms)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                "cancelNativeAlarms" -> {
                    try {
                        AdhanAlarmScheduler.cancelAllAlarms(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                "scheduleNativeTestAlarm" -> {
                    try {
                        val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                        val prayerName = call.argument<String>("prayerName") ?: "الظهر"
                        val soundId = call.argument<String>("soundId") ?: "qatami"
                        val rawRes = call.argument<String>("rawRes")
                        val title = call.argument<String>("title")
                        val muadhin = call.argument<String>("muadhin")
                        val volume = call.argument<Double>("volume") ?: 1.0
                        val isAlarmMode = call.argument<Boolean>("isAlarmMode") ?: true
                        val res = AdhanAlarmScheduler.scheduleTestAlarm(
                            context = applicationContext,
                            delaySeconds = delaySeconds,
                            prayerName = prayerName,
                            soundId = soundId,
                            rawRes = rawRes,
                            title = title,
                            muadhin = muadhin,
                            volume = volume,
                            isAlarmMode = isAlarmMode
                        )
                        result.success(res)
                    } catch (e: Exception) {
                        result.error("TEST_ALARM_ERROR", e.message, null)
                    }
                }
                "scheduleNativeTestPrePrayerAlarm" -> {
                    try {
                        val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                        val prayerName = call.argument<String>("prayerName") ?: "الظهر"
                        val rawRes = call.argument<String>("rawRes")
                        val volume = call.argument<Double>("volume") ?: 1.0
                        val res = AdhanAlarmScheduler.scheduleTestPrePrayerAlarm(
                            context = applicationContext,
                            delaySeconds = delaySeconds,
                            prayerName = prayerName,
                            rawRes = rawRes,
                            volume = volume
                        )
                        result.success(res)
                    } catch (e: Exception) {
                        result.error("TEST_PRE_ERROR", e.message, null)
                    }
                }
                "saveNativeScheduleData" -> {
                    try {
                        val data = call.argument<String>("scheduleData") ?: ""
                        AdhanAlarmScheduler.saveScheduleData(applicationContext, data)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.message, null)
                    }
                }
                "stopPrePrayerVoice" -> {
                    AdhanAlarmReceiver.stopPrePrayerVoice()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            val keyCode = event.keyCode
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                keyCode == KeyEvent.KEYCODE_VOLUME_DOWN ||
                keyCode == KeyEvent.KEYCODE_VOLUME_MUTE) {
                // Only silence if the native foreground Adhan alarm service is actively playing
                // Never intercept volume keys when the user is simply previewing audio in the app!
                if (AdhanForegroundService.isPlaying) {
                    stopAdhanLocally()
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            keyCode == KeyEvent.KEYCODE_VOLUME_DOWN ||
            keyCode == KeyEvent.KEYCODE_VOLUME_MUTE) {
            if (AdhanForegroundService.isPlaying) {
                stopAdhanLocally()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun stopAdhanLocally() {
        AdhanForegroundService.stopAdhan(applicationContext)
        AdhanVolumeManager.stopAdhan(applicationContext)
        AdhanAlarmReceiver.stopPrePrayerVoice()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        adhanMethodChannel?.let {
            AdhanVolumeManager.unregisterChannel(it)
            AdhanPlugin.unregisterChannel(it)
        }
        adhanMethodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
