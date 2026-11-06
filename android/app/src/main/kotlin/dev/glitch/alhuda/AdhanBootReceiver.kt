package dev.glitch.alhuda

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AdhanBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.i("AdhanBootReceiver", "Device rebooted. Restoring prayer alarms...")
            try {
                // If schedule data was cached, restore it
                val scheduleData = AdhanAlarmScheduler.loadScheduleData(context)
                if (!scheduleData.isNullOrEmpty()) {
                    Log.i("AdhanBootReceiver", "Found saved schedule data, restoring...")
                    // Will be fully rescheduled once Flutter starts or from receiver
                }
            } catch (e: Exception) {
                Log.e("AdhanBootReceiver", "Error restoring on boot: $e")
            }
        }
    }
}
