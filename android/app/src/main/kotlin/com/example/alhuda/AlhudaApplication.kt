package com.example.alhuda

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver
import io.flutter.app.FlutterApplication

class AlhudaApplication : FlutterApplication() {
    private var volumeReceiver: BroadcastReceiver? = null
    private var contentObserver: ContentObserver? = null

    override fun onCreate() {
        super.onCreate()
        setupVolumeMonitoring(this)
    }

    private fun setupVolumeMonitoring(context: Context) {
        val appCtx = context.applicationContext

        // 1. BroadcastReceiver for VOLUME_CHANGED_ACTION
        try {
            volumeReceiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context?, intent: Intent?) {
                    if (intent?.action == "android.media.VOLUME_CHANGED_ACTION") {
                        handleVolumeButtonPressed(appCtx)
                    }
                }
            }
            val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                appCtx.registerReceiver(volumeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                appCtx.registerReceiver(volumeReceiver, filter)
            }
        } catch (_: Exception) {}

        // 2. ContentObserver for Settings.System.CONTENT_URI (volume changes)
        try {
            contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    super.onChange(selfChange)
                    handleVolumeButtonPressed(appCtx)
                }
            }
            appCtx.contentResolver.registerContentObserver(
                Settings.System.CONTENT_URI,
                true,
                contentObserver!!
            )
        } catch (_: Exception) {}
    }

    companion object {
        private var lastTriggerTime: Long = 0

        fun handleVolumeButtonPressed(context: Context) {
            val now = System.currentTimeMillis()
            if (now - lastTriggerTime < 800) return // Debounce duplicate events

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return

            // Check if any Adhan notification is currently active
            val activeNotifications = try {
                notificationManager.activeNotifications
            } catch (_: Exception) {
                null
            } ?: return

            val adhanNotif = activeNotifications.find {
                it.id == 9998 || it.id == 9999 || it.id in 1001..1005
            }

            if (adhanNotif != null) {
                lastTriggerTime = now

                val audioManager =
                    context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

                // 1. Instantly mute audio streams in 0ms to cut sound immediately
                try {
                    audioManager?.adjustStreamVolume(AudioManager.STREAM_ALARM, AudioManager.ADJUST_MUTE, 0)
                    audioManager?.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0)
                } catch (_: Exception) {}

                // 2. Steal audio focus with AUDIOFOCUS_GAIN so audioplayers receives AUDIOFOCUS_LOSS and stops
                try {
                    if (audioManager != null) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                                .setAudioAttributes(
                                    AudioAttributes.Builder()
                                        .setUsage(AudioAttributes.USAGE_ALARM)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                        .build()
                                )
                                .build()
                            audioManager.requestAudioFocus(request)
                        } else {
                            @Suppress("DEPRECATION")
                            audioManager.requestAudioFocus(
                                null,
                                AudioManager.STREAM_ALARM,
                                AudioManager.AUDIOFOCUS_GAIN
                            )
                        }
                    }
                } catch (_: Exception) {}

                // 3. Immediately cancel the notification from system tray
                try {
                    notificationManager.cancel(adhanNotif.id)
                    notificationManager.cancelAll()
                } catch (_: Exception) {}

                // 4. Safely restore stream volume after player stops so future alarms are not muted
                Handler(Looper.getMainLooper()).postDelayed({
                    try {
                        audioManager?.adjustStreamVolume(AudioManager.STREAM_ALARM, AudioManager.ADJUST_UNMUTE, 0)
                        audioManager?.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0)
                    } catch (_: Exception) {}
                }, 1500)

                // 5. Send action to ActionBroadcastReceiver so Dart background isolate cleans up
                try {
                    val stopIntent = Intent(context, ActionBroadcastReceiver::class.java).apply {
                        action = ActionBroadcastReceiver.ACTION_TAPPED
                        putExtra("actionId", "stop_adhan")
                        putExtra("notificationId", adhanNotif.id)
                    }
                    context.sendBroadcast(stopIntent)
                } catch (_: Exception) {}

                // 6. Notify AdhanVolumeManager in case MainActivity is alive
                try {
                    AdhanVolumeManager.stopAdhan(context)
                } catch (_: Exception) {}
            }
        }
    }
}
