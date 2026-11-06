package dev.glitch.alhuda

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AdhanAlarmActivity : Activity() {

    private var stopReceiver: BroadcastReceiver? = null
    private var createTime: Long = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createTime = System.currentTimeMillis()

        // Ensure activity wakes up screen and shows over lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        volumeControlStream = AudioManager.STREAM_ALARM

        setContentView(R.layout.activity_adhan_alarm)

        val prayerName = intent.getStringExtra(AdhanForegroundService.EXTRA_PRAYER_NAME)
            ?: AdhanForegroundService.currentPrayerName.ifEmpty { "الصلاة" }

        val muadhin = intent.getStringExtra(AdhanForegroundService.EXTRA_MUADHIN)
            ?: AdhanForegroundService.currentMuadhin.ifEmpty { "حي على الصلاة .. حي على الفلاح" }

        val tvTitle = findViewById<TextView>(R.id.tv_prayer_title)
        val tvMuadhin = findViewById<TextView>(R.id.tv_muadhin_name)
        val btnStop = findViewById<Button>(R.id.btn_stop_adhan)
        val btnOpen = findViewById<Button>(R.id.btn_open_app)

        tvTitle?.text = if (prayerName.isNotEmpty() && prayerName != "الصلاة") {
            "حان الآن موعد أذان $prayerName"
        } else {
            "حان الآن موعد أذان الصلاة"
        }

        if (muadhin.isNotEmpty()) {
            tvMuadhin?.text = if (muadhin.startsWith("الشيخ") || muadhin.startsWith("مؤذن")) {
                "بصوت: $muadhin"
            } else {
                muadhin
            }
        }

        btnStop?.setOnClickListener {
            stopAllAdhan()
            finish()
        }

        btnOpen?.setOnClickListener {
            stopAllAdhan()
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                startActivity(launchIntent)
            }
            finish()
        }

        // Register receiver for when adhan finishes or is stopped elsewhere
        stopReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == AdhanForegroundService.BROADCAST_ADHAN_STOPPED) {
                    finish()
                }
            }
        }
        val filter = IntentFilter(AdhanForegroundService.BROADCAST_ADHAN_STOPPED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, filter)
        }
    }

    private fun stopAllAdhan() {
        AdhanForegroundService.stopAdhan(applicationContext)
        AdhanVolumeManager.stopAdhan(applicationContext)
        AdhanAlarmReceiver.stopPrePrayerVoice()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP,
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_VOLUME_MUTE -> {
                    stopAllAdhan()
                    finish()
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_VOLUME_MUTE -> {
                stopAllAdhan()
                finish()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        if (stopReceiver != null) {
            try {
                unregisterReceiver(stopReceiver)
            } catch (_: Exception) {}
            stopReceiver = null
        }
        super.onDestroy()
    }
}
