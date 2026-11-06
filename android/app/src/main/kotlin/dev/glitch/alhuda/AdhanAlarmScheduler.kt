package dev.glitch.alhuda

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object AdhanAlarmScheduler {

    private const val TAG = "AdhanAlarmScheduler"
    private const val PREFS_NAME = "dev.glitch.alhuda.alarm_prefs"
    private const val KEY_SCHEDULED_IDS = "scheduled_alarm_ids"
    private const val KEY_SCHEDULE_DATA = "saved_schedule_data"

    fun scheduleAlarms(context: Context, alarms: List<Map<String, Any>>) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        // Cancel previous alarms first to prevent ghost/duplicate alarms
        cancelAllAlarms(appContext)

        val scheduledIds = mutableSetOf<Int>()

        for (map in alarms) {
            try {
                val id = (map["id"] as? Number)?.toInt() ?: continue
                val type = map["type"] as? String ?: "ADHAN"
                val triggerAtMillis = (map["triggerAtMillis"] as? Number)?.toLong() ?: continue
                val prayerName = map["prayerName"] as? String ?: "الصلاة"
                val soundId = map["soundId"] as? String ?: "qatami"
                val rawRes = map["rawRes"] as? String
                val title = map["title"] as? String
                val muadhin = map["muadhin"] as? String
                val volume = (map["volume"] as? Number)?.toDouble() ?: 1.0
                val isAlarmMode = (map["isAlarmMode"] as? Boolean) ?: true
                val prePrayerMinutes = (map["prePrayerMinutes"] as? Number)?.toInt() ?: 15

                val intent = Intent(appContext, AdhanAlarmReceiver::class.java).apply {
                    action = when (type) {
                        "PRE_PRAYER" -> AdhanAlarmReceiver.ACTION_PRE_PRAYER_ALARM
                        "NOTIFICATION_UPDATE" -> AdhanAlarmReceiver.ACTION_UPDATE_NOTIFICATION
                        else -> AdhanAlarmReceiver.ACTION_PRAYER_ALARM
                    }
                    putExtra(AdhanAlarmReceiver.EXTRA_ALARM_ID, id)
                    putExtra(AdhanAlarmReceiver.EXTRA_TYPE, type)
                    putExtra(AdhanAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
                    putExtra(AdhanAlarmReceiver.EXTRA_SOUND_ID, soundId)
                    putExtra(AdhanAlarmReceiver.EXTRA_RAW_RES, rawRes)
                    putExtra(AdhanAlarmReceiver.EXTRA_TITLE, title)
                    putExtra(AdhanAlarmReceiver.EXTRA_MUADHIN, muadhin)
                    putExtra(AdhanAlarmReceiver.EXTRA_VOLUME, volume)
                    putExtra(AdhanAlarmReceiver.EXTRA_IS_ALARM_MODE, isAlarmMode)
                    putExtra(AdhanAlarmReceiver.EXTRA_PRE_MINUTES, prePrayerMinutes)
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    appContext,
                    id,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                scheduleExact(alarmManager, appContext, id, triggerAtMillis, pendingIntent)
                scheduledIds.add(id)
            } catch (e: Exception) {
                Log.e(TAG, "Error scheduling alarm: $e")
            }
        }

        saveScheduledAlarmIds(appContext, scheduledIds)
    }

    fun scheduleTestAlarm(
        context: Context,
        delaySeconds: Int,
        prayerName: String,
        soundId: String,
        rawRes: String?,
        title: String?,
        muadhin: String?,
        volume: Double,
        isAlarmMode: Boolean
    ): Boolean {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        val triggerAtMillis = System.currentTimeMillis() + (delaySeconds * 1000L)
        val id = 9998

        val intent = Intent(appContext, AdhanAlarmReceiver::class.java).apply {
            action = AdhanAlarmReceiver.ACTION_PRAYER_ALARM
            putExtra(AdhanAlarmReceiver.EXTRA_ALARM_ID, id)
            putExtra(AdhanAlarmReceiver.EXTRA_TYPE, "ADHAN")
            putExtra(AdhanAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanAlarmReceiver.EXTRA_SOUND_ID, soundId)
            putExtra(AdhanAlarmReceiver.EXTRA_RAW_RES, rawRes)
            putExtra(AdhanAlarmReceiver.EXTRA_TITLE, title)
            putExtra(AdhanAlarmReceiver.EXTRA_MUADHIN, muadhin)
            putExtra(AdhanAlarmReceiver.EXTRA_VOLUME, volume)
            putExtra(AdhanAlarmReceiver.EXTRA_IS_ALARM_MODE, isAlarmMode)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            appContext,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        scheduleExact(alarmManager, appContext, id, triggerAtMillis, pendingIntent)
        return true
    }

    fun scheduleTestPrePrayerAlarm(
        context: Context,
        delaySeconds: Int,
        prayerName: String,
        rawRes: String?,
        volume: Double
    ): Boolean {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        val triggerAtMillis = System.currentTimeMillis() + (delaySeconds * 1000L)
        val id = 9997

        val intent = Intent(appContext, AdhanAlarmReceiver::class.java).apply {
            action = AdhanAlarmReceiver.ACTION_PRE_PRAYER_ALARM
            putExtra(AdhanAlarmReceiver.EXTRA_ALARM_ID, id)
            putExtra(AdhanAlarmReceiver.EXTRA_TYPE, "PRE_PRAYER")
            putExtra(AdhanAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanAlarmReceiver.EXTRA_RAW_RES, rawRes ?: "pre_prayer_dhuhr")
            putExtra(AdhanAlarmReceiver.EXTRA_VOLUME, volume)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            appContext,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        scheduleExact(alarmManager, appContext, id, triggerAtMillis, pendingIntent)
        return true
    }

    private fun scheduleExact(
        alarmManager: AlarmManager,
        context: Context,
        requestCode: Int,
        triggerAtMillis: Long,
        pendingIntent: PendingIntent
    ) {
        val showIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val showPendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            showIntent ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent),
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent),
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
        } catch (e: Exception) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } catch (e2: Exception) {
                Log.e(TAG, "Failed all exact alarm options: $e2")
            }
        }
    }

    fun cancelAlarm(context: Context, id: Int) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(appContext, AdhanAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            appContext,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (_: Exception) {}

        val scheduledIds = getScheduledAlarmIds(appContext).toMutableSet()
        scheduledIds.remove(id)
        saveScheduledAlarmIds(appContext, scheduledIds)
    }

    fun cancelAllAlarms(context: Context) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val scheduledIds = getScheduledAlarmIds(appContext)

        for (id in scheduledIds) {
            val intent = Intent(appContext, AdhanAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                appContext,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            try {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            } catch (_: Exception) {}
        }

        saveScheduledAlarmIds(appContext, emptySet())
    }

    fun saveScheduleData(context: Context, json: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_SCHEDULE_DATA, json).apply()
    }

    fun loadScheduleData(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_SCHEDULE_DATA, null)
    }

    private fun getScheduledAlarmIds(context: Context): Set<Int> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val set = prefs.getStringSet(KEY_SCHEDULED_IDS, emptySet()) ?: emptySet()
        return set.mapNotNull { it.toIntOrNull() }.toSet()
    }

    private fun saveScheduledAlarmIds(context: Context, ids: Set<Int>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_SCHEDULED_IDS, ids.map { it.toString() }.toSet()).apply()
    }
}
