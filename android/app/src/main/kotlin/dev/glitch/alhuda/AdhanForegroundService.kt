package dev.glitch.alhuda

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class AdhanForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "adhan_alarm_high_priority_v1"
        const val NOTIFICATION_ID = 8888

        const val ACTION_START_ADHAN = "dev.glitch.alhuda.ACTION_START_ADHAN"
        const val ACTION_STOP_ADHAN = "dev.glitch.alhuda.ACTION_STOP_ADHAN"
        const val BROADCAST_ADHAN_STOPPED = "dev.glitch.alhuda.ADHAN_STOPPED"

        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_SOUND_ID = "sound_id"
        const val EXTRA_RAW_RES = "raw_res"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MUADHIN = "muadhin"
        const val EXTRA_VOLUME = "volume"
        const val EXTRA_IS_ALARM_MODE = "is_alarm_mode"

        @Volatile
        var isPlaying: Boolean = false
            private set

        @Volatile
        var currentPrayerName: String = ""
            private set

        @Volatile
        var currentMuadhin: String = ""
            private set

        @Volatile
        var currentTitle: String = ""
            private set

        fun startAdhan(
            context: Context,
            prayerName: String,
            soundId: String,
            rawRes: String? = null,
            title: String? = null,
            muadhin: String? = null,
            volume: Double = 1.0,
            isAlarmMode: Boolean = true
        ) {
            val intent = Intent(context, AdhanForegroundService::class.java).apply {
                action = ACTION_START_ADHAN
                putExtra(EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_SOUND_ID, soundId)
                putExtra(EXTRA_RAW_RES, rawRes)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_MUADHIN, muadhin)
                putExtra(EXTRA_VOLUME, volume)
                putExtra(EXTRA_IS_ALARM_MODE, isAlarmMode)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                try {
                    context.startService(intent)
                } catch (_: Exception) {}
            }
        }

        fun stopAdhan(context: Context) {
            val intent = Intent(context, AdhanForegroundService::class.java).apply {
                action = ACTION_STOP_ADHAN
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {}
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var assetFileDescriptor: android.content.res.AssetFileDescriptor? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var screenWakeLock: PowerManager.WakeLock? = null
    private var volumeReceiver: BroadcastReceiver? = null
    private var playbackStartTime: Long = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_STOP_ADHAN) {
            handleStop()
            stopSelf()
            return START_NOT_STICKY
        }

        if (action == ACTION_START_ADHAN) {
            val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
            val soundId = intent.getStringExtra(EXTRA_SOUND_ID) ?: "qatami"
            val rawRes = intent.getStringExtra(EXTRA_RAW_RES)
            val title = intent.getStringExtra(EXTRA_TITLE)
            val muadhin = intent.getStringExtra(EXTRA_MUADHIN)
            val volume = intent.getDoubleExtra(EXTRA_VOLUME, 1.0)
            val isAlarmMode = intent.getBooleanExtra(EXTRA_IS_ALARM_MODE, true)

            handleStart(
                prayerName = prayerName,
                soundId = soundId,
                rawRes = rawRes,
                title = title,
                muadhin = muadhin,
                volume = volume,
                isAlarmMode = isAlarmMode
            )
            return START_NOT_STICKY
        }

        return START_NOT_STICKY
    }

    private fun handleStart(
        prayerName: String,
        soundId: String,
        rawRes: String?,
        title: String?,
        muadhin: String?,
        volume: Double,
        isAlarmMode: Boolean
    ) {
        // If this exact prayer is already actively playing and started recently, ignore duplicate trigger
        if (isPlaying && currentPrayerName == prayerName && (System.currentTimeMillis() - playbackStartTime) < 60_000L) {
            return
        }

        // Clean any previous playback player without firing stop broadcast
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null
        try {
            assetFileDescriptor?.close()
        } catch (_: Exception) {}
        assetFileDescriptor = null

        // Clean up legacy adhan notification channels and IDs if any exist
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(9999)
            nm?.cancel(9991)
            nm?.cancel(7777)
            nm?.cancel(0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm?.deleteNotificationChannel("adhan_alarm_channel_v9")
            }
        } catch (_: Exception) {}

        isPlaying = true
        currentPrayerName = prayerName
        currentMuadhin = muadhin ?: ""
        currentTitle = title ?: ""
        playbackStartTime = System.currentTimeMillis()

        // 1. Acquire CPU WakeLock safely so CPU never goes to sleep during Adhan
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = try {
                powerManager?.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Alhuda:AdhanForegroundWakeLock"
                )?.apply {
                    setReferenceCounted(false)
                    acquire(10 * 60 * 1000L) // 10 minutes max
                }
            } catch (_: Exception) { null }

            // If in alarm mode, turn screen on immediately
            if (isAlarmMode) {
                @Suppress("DEPRECATION")
                screenWakeLock = try {
                    powerManager?.newWakeLock(
                        PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                        "Alhuda:AdhanScreenWakeLock"
                    )?.apply {
                        setReferenceCounted(false)
                        acquire(8000L) // 8 seconds to allow screen turn on and activity render
                    }
                } catch (_: Exception) { null }
            }
        } catch (_: Exception) {}

        // 2. Setup Notification Channel
        createNotificationChannel()

        // 3. Build High-Priority Alarm Notification
        val stopIntent = Intent(this, AdhanForegroundService::class.java).apply {
            action = ACTION_STOP_ADHAN
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openPendingIntent = if (openIntent != null) {
            PendingIntent.getActivity(
                this,
                2,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val fullScreenIntent = Intent(this, AdhanAlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_PRAYER_NAME, prayerName)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_MUADHIN, muadhin)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notifTitle = if (prayerName.isNotEmpty() && prayerName != "الصلاة") {
            "حان الآن موعد أذان $prayerName"
        } else {
            "حان الآن موعد أذان الصلاة"
        }
        val notifBody = if (!muadhin.isNullOrEmpty()) {
            "حي على الصلاة .. حي على الفلاح ($muadhin)"
        } else {
            "حي على الصلاة .. حي على الفلاح"
        }

        val largeIconBitmap = try {
            android.graphics.BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        } catch (_: Exception) { null }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(notifTitle)
            .setContentText(notifBody)
            .setSubText("حان وقت الأذان")
            .setColor(android.graphics.Color.parseColor("#5D4037"))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(0, "إيقاف الأذان", stopPendingIntent)

        if (largeIconBitmap != null) {
            builder.setLargeIcon(largeIconBitmap)
        }

        if (openPendingIntent != null) {
            builder.addAction(0, "فتح التطبيق", openPendingIntent)
            builder.setContentIntent(openPendingIntent)
        }

        if (isAlarmMode) {
            builder.setFullScreenIntent(fullScreenPendingIntent, true)
        }

        val notification = builder.build()

        // 4. Start Foreground immediately
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            startForeground(NOTIFICATION_ID, notification)
        }

        // 5. Initialize Native MediaPlayer on ALARM stream
        try {
            val resourceId = getRawResourceId(rawRes, soundId)
            val afd = resources.openRawResourceFd(resourceId)
            assetFileDescriptor = afd
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)

                val vol = volume.toFloat().coerceIn(0.1f, 1.0f)
                setVolume(vol, vol)

                setOnCompletionListener {
                    handleStop()
                    stopSelf()
                }
                setOnErrorListener { _, _, _ ->
                    handleStop()
                    stopSelf()
                    true
                }
                prepare()
                start()
            }
        } catch (e: Exception) {
            handleStop()
            stopSelf()
            return
        }

        // 6. Register Hardware Volume Broadcast Receiver (silences adhan when volume buttons pressed)
        registerVolumeReceiver()

        // 7. If isAlarmMode, launch AlarmActivity directly as well to ensure display
        if (isAlarmMode) {
            try {
                startActivity(fullScreenIntent)
            } catch (_: Exception) {}
        }
    }

    private fun registerVolumeReceiver() {
        if (volumeReceiver != null) return
        try {
            volumeReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action != "android.media.VOLUME_CHANGED_ACTION") return
                    val now = System.currentTimeMillis()
                    // 500ms initial guard to ignore initial broadcast at registration
                    if (playbackStartTime > 0L && now - playbackStartTime < 500L) {
                        return
                    }

                    val currVol = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", -1)
                    val prevVol = intent.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", -1)

                    // Ignore if volume didn't actually change
                    if (currVol == prevVol && currVol != -1) return

                    // Volume button pressed while Adhan is ringing -> Stop immediately!
                    handleStop()
                    stopSelf()
                }
            }
            val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(volumeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(volumeReceiver, filter)
            }
        } catch (_: Exception) {}
    }

    private fun unregisterVolumeReceiver() {
        if (volumeReceiver != null) {
            try {
                unregisterReceiver(volumeReceiver)
            } catch (_: Exception) {}
            volumeReceiver = null
        }
    }

    private fun handleStop() {
        isPlaying = false

        // Unregister volume receiver immediately
        unregisterVolumeReceiver()

        // Release AssetFileDescriptor
        try {
            assetFileDescriptor?.close()
        } catch (_: Exception) {}
        assetFileDescriptor = null

        // Stop and release MediaPlayer
        if (mediaPlayer != null) {
            try {
                if (mediaPlayer?.isPlaying == true) {
                    mediaPlayer?.stop()
                }
                mediaPlayer?.release()
            } catch (_: Exception) {}
            mediaPlayer = null
        }

        // Release WakeLocks safely
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        wakeLock = null

        try {
            if (screenWakeLock?.isHeld == true) {
                screenWakeLock?.release()
            }
        } catch (_: Exception) {}
        screenWakeLock = null

        // Check if persistent notification is enabled
        val isPersistentEnabled = try {
            val prefs = getSharedPreferences("dev.glitch.alhuda.alarm_prefs", Context.MODE_PRIVATE)
            prefs.getBoolean("is_persistent_notification_enabled", true)
        } catch (_: Exception) { true }

        // Stop foreground: If persistent notification is enabled, detach it so ID 8888 remains
        // and transitions back smoothly to the upcoming prayer countdown without disappearing or duplicating.
        // If disabled, remove it immediately.
        try {
            if (isPersistentEnabled) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_DETACH)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(false)
                }
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
            }
        } catch (_: Exception) {}

        // Broadcast to close AdhanAlarmActivity if visible
        try {
            val stopBroadcast = Intent(BROADCAST_ADHAN_STOPPED).apply {
                setPackage(packageName)
            }
            sendBroadcast(stopBroadcast)
        } catch (_: Exception) {}

        // Notify Flutter engine/channel so UI updates and persistent notification refreshes
        AdhanVolumeManager.notifyFlutterToStop()
        AdhanPlugin.notifyFlutterToStop()
        AdhanPlugin.notifyPersistentNotificationUpdate("")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                "منبه الأذان (عالي الأولوية)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تنبيهات الأذان عند حلول موعد الصلاة"
                setSound(null, null)
                enableVibration(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            nm?.createNotificationChannel(channel)
        }
    }

    private fun getRawResourceId(rawResName: String?, soundId: String?): Int {
        if (!rawResName.isNullOrEmpty()) {
            val id = resources.getIdentifier(rawResName, "raw", packageName)
            if (id != 0) return id
        }

        val soundIdMap = mapOf(
            "rifaat" to "mohamed_rifaat",
            "mostafa_ismail" to "mostafa_ismail",
            "abdulbasit" to "abdulbasit_abdulsamad",
            "minshawi" to "mohamed_siddiq_elminshawi",
            "shuaisha" to "abul_aynayn_shuaisha",
            "hussary" to "mahmoud_khalil_alhussary",
            "mahmoud_ramadan" to "mahmoud_mohamed_ramadan",
            "banna" to "mohamed_ali_elbanna",
            "qatami" to "nasser_al_qatami",
            "makkah" to "makkah_ali_mullah",
            "madinah" to "madinah",
            "alafasy" to "mishary_alafasy",
            "basnawi" to "ahmed_basnawi",
            "essam_khan" to "essam_khan",
            "ahmad_khoja" to "ahmad_khoja",
            "dubai" to "dubai"
        )

        val resName = soundIdMap[soundId] ?: soundId ?: "nasser_al_qatami"
        val id = resources.getIdentifier(resName, "raw", packageName)
        return if (id != 0) id else R.raw.nasser_al_qatami
    }

    override fun onDestroy() {
        handleStop()
        super.onDestroy()
    }
}
