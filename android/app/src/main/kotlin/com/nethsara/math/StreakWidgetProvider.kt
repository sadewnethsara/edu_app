package com.nethsara.math

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.concurrent.TimeUnit

class StreakWidgetProvider : AppWidgetProvider() {

    // Runs when the user adds the *first* widget
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d("StreakWidgetProvider", "Widget enabled, scheduling worker.")

        // Create a periodic work request (runs ~every 24 hours)
        val streakWorkRequest = PeriodicWorkRequestBuilder<StreakCheckWorker>(
            24, TimeUnit.HOURS,
            1, TimeUnit.HOURS
        ).build()

        // Enqueue the work
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            "DailyStreakCheck",
            androidx.work.ExistingPeriodicWorkPolicy.KEEP,
            streakWorkRequest
        )
    }

    // This runs when your Flutter app tells the widget to update
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Loop through all widgets
        for (appWidgetId in appWidgetIds) {
            // 1. Get the data saved by Flutter
            val widgetData = HomeWidgetPlugin.getData(context)
            val streakCount = widgetData.getInt("streak_count", 0)

            // 2. Get the layout and update it
            val views = RemoteViews(context.packageName, R.layout.streak_widget).apply {
                // Update text
                val label = if (streakCount == 1) "day streak" else "days streak"
                setTextViewText(R.id.tv_streak_count, streakCount.toString())
                setTextViewText(R.id.tv_streak_label, label)

                // 3. Set a "safe" UI (orange flame)
                // The worker will set the "danger" UI
                setInt(R.id.iv_flame, "setColorFilter", 0xFFF76B1C.toInt()) // Orange

                // 4. Set click handler
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            // 5. Tell the manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    // Runs when the user removes the *last* widget
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d("StreakWidgetProvider", "Widget disabled, cancelling worker.")
        WorkManager.getInstance(context).cancelUniqueWork("DailyStreakCheck")
    }
}