package dev.glitch.alhuda

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

class AdhanPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.example.alhuda/adhan"
        private val channels = mutableSetOf<WeakReference<MethodChannel>>()
        private var applicationContext: Context? = null

        fun registerWith(flutterEngine: FlutterEngine) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            val plugin = AdhanPlugin()
            plugin.channel = channel
            channel.setMethodCallHandler(plugin)
            registerChannel(channel)
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

        fun notifyPersistentNotificationUpdate(prayerName: String) {
            val handler = Handler(Looper.getMainLooper())
            handler.post {
                synchronized(channels) {
                    val iterator = channels.iterator()
                    while (iterator.hasNext()) {
                        val ref = iterator.next()
                        val ch = ref.get()
                        if (ch != null) {
                            try {
                                ch.invokeMethod("onPersistentNotificationUpdate", prayerName)
                            } catch (_: Exception) {}
                        } else {
                            iterator.remove()
                        }
                    }
                }
            }
        }
    }

    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        channel?.let { registerChannel(it) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.let { unregisterChannel(it) }
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: applicationContext

        when (call.method) {
            "startAdhanService" -> {
                val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                val soundId = call.argument<String>("soundId") ?: "qatami"
                val rawRes = call.argument<String>("rawRes")
                val title = call.argument<String>("title")
                val muadhin = call.argument<String>("muadhin")
                val volume = call.argument<Double>("volume") ?: 1.0
                val isAlarmMode = call.argument<Boolean>("isAlarmMode") ?: true

                if (ctx != null) {
                    AdhanForegroundService.startAdhan(
                        context = ctx,
                        prayerName = prayerName,
                        soundId = soundId,
                        rawRes = rawRes,
                        title = title,
                        muadhin = muadhin,
                        volume = volume,
                        isAlarmMode = isAlarmMode
                    )
                    result.success(true)
                } else {
                    result.error("NO_CONTEXT", "Application context is null", null)
                }
            }

            "stopAdhan" -> {
                if (ctx != null) {
                    AdhanForegroundService.stopAdhan(ctx)
                }
                AdhanVolumeManager.stopAdhan(ctx, fromFlutter = true)
                result.success(true)
            }

            "startAdhanMonitoring" -> {
                if (ctx != null) {
                    AdhanVolumeManager.startAdhanMonitoring(ctx)
                }
                result.success(true)
            }

            "stopAdhanMonitoring" -> {
                if (ctx != null) {
                    AdhanVolumeManager.stopAdhanMonitoring(ctx)
                }
                result.success(true)
            }

            "isAdhanPlaying" -> {
                val isPlaying = AdhanForegroundService.isPlaying || AdhanVolumeManager.isAdhanActive(ctx)
                result.success(isPlaying)
            }

            "getCurrentAdhanPrayerName" -> {
                result.success(AdhanForegroundService.currentPrayerName)
            }

            "setPersistentNotificationEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                if (ctx != null) {
                    val prefs = ctx.getSharedPreferences("dev.glitch.alhuda.alarm_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("is_persistent_notification_enabled", enabled).apply()
                }
                result.success(true)
            }

            "setAdhanVolume" -> {
                val volume = call.argument<Double>("volume") ?: 1.0
                if (ctx != null) {
                    AdhanVolumeManager.setAdhanVolume(ctx, volume)
                }
                result.success(true)
            }

            "restoreAlarmVolume" -> {
                if (ctx != null) {
                    AdhanVolumeManager.restoreAlarmVolume(ctx)
                }
                result.success(true)
            }

            "isIgnoringBatteryOptimizations" -> {
                try {
                    val pm = ctx?.getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && ctx != null) {
                        pm?.isIgnoringBatteryOptimizations(ctx.packageName) ?: true
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
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && ctx != null) {
                        val pm = ctx.getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnoring = pm?.isIgnoringBatteryOptimizations(ctx.packageName) ?: false
                        if (!isIgnoring) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:${ctx.packageName}")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            ctx.startActivity(intent)
                        }
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                } catch (_: Exception) {
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        ctx?.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
            }

            "openAppSettings" -> {
                try {
                    if (ctx != null) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:${ctx.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        ctx.startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } catch (_: Exception) {
                    result.success(false)
                }
            }

            "scheduleNativeAlarms" -> {
                try {
                    if (ctx != null) {
                        val alarms = call.argument<List<Map<String, Any>>>("alarms") ?: emptyList()
                        AdhanAlarmScheduler.scheduleAlarms(ctx, alarms)
                        result.success(true)
                    } else {
                        result.error("NO_CONTEXT", "Context is null", null)
                    }
                } catch (e: Exception) {
                    result.error("ALARM_ERROR", e.message, null)
                }
            }

            "cancelNativeAlarms" -> {
                try {
                    if (ctx != null) {
                        AdhanAlarmScheduler.cancelAllAlarms(ctx)
                        result.success(true)
                    } else {
                        result.error("NO_CONTEXT", "Context is null", null)
                    }
                } catch (e: Exception) {
                    result.error("ALARM_ERROR", e.message, null)
                }
            }

            "scheduleNativeTestAlarm" -> {
                try {
                    if (ctx != null) {
                        val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                        val prayerName = call.argument<String>("prayerName") ?: "الظهر"
                        val soundId = call.argument<String>("soundId") ?: "qatami"
                        val rawRes = call.argument<String>("rawRes")
                        val title = call.argument<String>("title")
                        val muadhin = call.argument<String>("muadhin")
                        val volume = call.argument<Double>("volume") ?: 1.0
                        val isAlarmMode = call.argument<Boolean>("isAlarmMode") ?: true
                        val res = AdhanAlarmScheduler.scheduleTestAlarm(
                            context = ctx,
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
                    } else {
                        result.error("NO_CONTEXT", "Context is null", null)
                    }
                } catch (e: Exception) {
                    result.error("TEST_ALARM_ERROR", e.message, null)
                }
            }

            "scheduleNativeTestPrePrayerAlarm" -> {
                try {
                    if (ctx != null) {
                        val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                        val prayerName = call.argument<String>("prayerName") ?: "الظهر"
                        val rawRes = call.argument<String>("rawRes")
                        val volume = call.argument<Double>("volume") ?: 1.0
                        val res = AdhanAlarmScheduler.scheduleTestPrePrayerAlarm(
                            context = ctx,
                            delaySeconds = delaySeconds,
                            prayerName = prayerName,
                            rawRes = rawRes,
                            volume = volume
                        )
                        result.success(res)
                    } else {
                        result.error("NO_CONTEXT", "Context is null", null)
                    }
                } catch (e: Exception) {
                    result.error("TEST_PRE_ERROR", e.message, null)
                }
            }

            "saveNativeScheduleData" -> {
                try {
                    if (ctx != null) {
                        val data = call.argument<String>("scheduleData") ?: ""
                        AdhanAlarmScheduler.saveScheduleData(ctx, data)
                        result.success(true)
                    } else {
                        result.error("NO_CONTEXT", "Context is null", null)
                    }
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
