package dev.glitch.alhuda

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.PowerManager
import android.util.Log

class AdhanAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "AdhanAlarmReceiver"

        const val ACTION_PRAYER_ALARM = "dev.glitch.alhuda.ACTION_PRAYER_ALARM"
        const val ACTION_PRE_PRAYER_ALARM = "dev.glitch.alhuda.ACTION_PRE_PRAYER_ALARM"
        const val ACTION_UPDATE_NOTIFICATION = "dev.glitch.alhuda.ACTION_UPDATE_NOTIFICATION"

        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_TYPE = "type"
        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_SOUND_ID = "sound_id"
        const val EXTRA_RAW_RES = "raw_res"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MUADHIN = "muadhin"
        const val EXTRA_VOLUME = "volume"
        const val EXTRA_IS_ALARM_MODE = "is_alarm_mode"
        const val EXTRA_PRE_MINUTES = "pre_prayer_minutes"

        @Volatile
        private var prePrayerPlayer: MediaPlayer? = null
        @Volatile
        private var prePrayerAfd: android.content.res.AssetFileDescriptor? = null
        @Volatile
        private var prePrayerWakeLock: PowerManager.WakeLock? = null
        @Volatile
        private var prePrayerVolumeReceiver: BroadcastReceiver? = null
        @Volatile
        private var prePrayerAppContext: Context? = null
        @Volatile
        private var lastPrePrayerPrayerName: String = ""
        @Volatile
        private var lastPrePrayerTime: Long = 0L

        fun stopPrePrayerVoice() {
            try {
                prePrayerPlayer?.stop()
                prePrayerPlayer?.release()
            } catch (_: Exception) {}
            prePrayerPlayer = null

            try {
                prePrayerAfd?.close()
            } catch (_: Exception) {}
            prePrayerAfd = null

            try {
                if (prePrayerWakeLock?.isHeld == true) {
                    prePrayerWakeLock?.release()
                }
            } catch (_: Exception) {}
            prePrayerWakeLock = null

            prePrayerVolumeReceiver?.let { receiver ->
                try {
                    prePrayerAppContext?.unregisterReceiver(receiver)
                } catch (_: Exception) {}
            }
            prePrayerVolumeReceiver = null
            prePrayerAppContext = null
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val appContext = context.applicationContext

        // Acquire WakeLock so CPU doesn't sleep while starting service or audio
        val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = try {
            powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Alhuda:AdhanReceiverWakeLock"
            )?.apply {
                setReferenceCounted(false)
                acquire(30_000L) // 30 seconds
            }
        } catch (_: Exception) { null }

        try {
            when (action) {
                ACTION_PRAYER_ALARM -> {
                    val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
                    val soundId = intent.getStringExtra(EXTRA_SOUND_ID) ?: "qatami"
                    val rawRes = intent.getStringExtra(EXTRA_RAW_RES)
                    val title = intent.getStringExtra(EXTRA_TITLE)
                    val muadhin = intent.getStringExtra(EXTRA_MUADHIN)
                    val volume = intent.getDoubleExtra(EXTRA_VOLUME, 1.0)
                    val isAlarmMode = intent.getBooleanExtra(EXTRA_IS_ALARM_MODE, true)

                    Log.i(TAG, "Adhan exact alarm fired for $prayerName! Starting Foreground Service immediately.")

                    AdhanForegroundService.startAdhan(
                        context = appContext,
                        prayerName = prayerName,
                        soundId = soundId,
                        rawRes = rawRes,
                        title = title,
                        muadhin = muadhin,
                        volume = volume,
                        isAlarmMode = isAlarmMode
                    )

                    if (isAlarmMode) {
                        try {
                            val alarmActivityIntent = Intent(appContext, AdhanAlarmActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                                putExtra(AdhanForegroundService.EXTRA_PRAYER_NAME, prayerName)
                                putExtra(AdhanForegroundService.EXTRA_TITLE, title)
                                putExtra(AdhanForegroundService.EXTRA_MUADHIN, muadhin)
                            }
                            appContext.startActivity(alarmActivityIntent)
                        } catch (e: Exception) {
                            Log.e(TAG, "Could not start AdhanAlarmActivity from receiver: $e")
                        }
                    }
                }

                ACTION_PRE_PRAYER_ALARM -> {
                    val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
                    val rawRes = intent.getStringExtra(EXTRA_RAW_RES)
                    val volume = intent.getDoubleExtra(EXTRA_VOLUME, 1.0)

                    Log.i(TAG, "Pre-prayer exact voice alarm fired for $prayerName!")

                    playPrePrayerVoice(appContext, prayerName, rawRes, volume)
                }

                ACTION_UPDATE_NOTIFICATION -> {
                    val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: ""
                    Log.i(TAG, "Notification transition alarm fired for prayer: $prayerName")
                    // Notify Flutter if alive
                    AdhanPlugin.notifyPersistentNotificationUpdate(prayerName)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in AdhanAlarmReceiver.onReceive: $e")
        } finally {
            try {
                if (wakeLock?.isHeld == true) {
                    wakeLock.release()
                }
            } catch (_: Exception) {}
        }
    }

    private fun playPrePrayerVoice(
        context: Context,
        prayerName: String,
        rawResName: String?,
        volume: Double
    ) {
        val now = System.currentTimeMillis()
        if (prePrayerPlayer?.isPlaying == true ||
            (lastPrePrayerPrayerName == prayerName && (now - lastPrePrayerTime) < 30_000L)
        ) {
            Log.i(TAG, "Pre-prayer voice for $prayerName is already playing or triggered recently. Ignoring duplicate.")
            return
        }
        lastPrePrayerPrayerName = prayerName
        lastPrePrayerTime = now

        stopPrePrayerVoice()

        val soundName = rawResName ?: run {
            val key = when (prayerName) {
                "الفجر" -> "fajr"
                "الظهر" -> "dhuhr"
                "العصر" -> "asr"
                "المغرب" -> "maghrib"
                "العشاء" -> "isha"
                else -> "dhuhr"
            }
            "pre_prayer_$key"
        }

        val resId = context.resources.getIdentifier(soundName, "raw", context.packageName)
        if (resId == 0) {
            Log.w(TAG, "Pre-prayer raw resource not found for: $soundName")
            return
        }

        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            prePrayerWakeLock = try {
                powerManager?.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Alhuda:PrePrayerVoiceWakeLock"
                )?.apply {
                    setReferenceCounted(false)
                    acquire(15_000L) // 15 seconds
                }
            } catch (_: Exception) { null }

            val afd = context.resources.openRawResourceFd(resId)
            prePrayerAfd = afd
            prePrayerAppContext = context.applicationContext

            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setWakeMode(context.applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)

                val vol = volume.toFloat().coerceIn(0.1f, 1.0f)
                setVolume(vol, vol)

                setOnCompletionListener {
                    stopPrePrayerVoice()
                }
                setOnErrorListener { _, _, _ ->
                    stopPrePrayerVoice()
                    true
                }
                prepare()
                start()
            }
            prePrayerPlayer = player

            // Register volume receiver to stop pre-prayer if volume button is pressed
            try {
                val startTime = System.currentTimeMillis()
                val receiver = object : BroadcastReceiver() {
                    override fun onReceive(c: Context?, i: Intent?) {
                        if (i?.action != "android.media.VOLUME_CHANGED_ACTION") return
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - startTime < 500L) return

                        val currVol = i.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", -1)
                        val prevVol = i.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", -1)
                        if (currVol == prevVol && currVol != -1) return

                        stopPrePrayerVoice()
                    }
                }
                prePrayerVolumeReceiver = receiver
                val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.applicationContext.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
                } else {
                    context.applicationContext.registerReceiver(receiver, filter)
                }
            } catch (_: Exception) {}

        } catch (e: Exception) {
            Log.e(TAG, "Error playing native pre-prayer voice: $e")
            stopPrePrayerVoice()
        }
    }
}
