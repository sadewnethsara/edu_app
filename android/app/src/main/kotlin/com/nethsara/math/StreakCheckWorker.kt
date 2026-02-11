package com.nethsara.math

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZonedDateTime
import java.time.format.DateTimeParseException

class StreakCheckWorker(val context: Context, params: WorkerParameters) : Worker(context, params) {

    // Keys MUST match your Dart service
    private val PREFS_FILE_NAME = "FlutterSharedPreferences"
    private val STREAK_KEY = "flutter.current_streak"
    private val LAST_LOGIN_KEY = "flutter.last_login_date"

    override fun doWork(): Result {
        Log.d("StreakCheckWorker", "Worker is running... (Safe Mode)")

        try {
            val prefs = context.getSharedPreferences(PREFS_FILE_NAME, Context.MODE_PRIVATE)

            // 1. GET SAVED DATA
            val currentStreak = prefs.getInt(STREAK_KEY, 0)
            val lastLoginString = prefs.getString(LAST_LOGIN_KEY, null)
            val today = LocalDate.now()

            var isStreakInDanger = false

            // 2. --- START READ-ONLY LOGIC ---
            if (lastLoginString != null) {
                val lastLoginDate = try {
                    ZonedDateTime.parse(lastLoginString).toLocalDate()
                } catch (e: DateTimeParseException) {
                    LocalDateTime.parse(lastLoginString).toLocalDate()
                }

                val yesterday = today.minusDays(1)

                if (!lastLoginDate.isEqual(today) && !lastLoginDate.isEqual(yesterday)) {
                    // Last login was 2 or more days ago. Streak is lost!
                    isStreakInDanger = true
                }
            }
            // --- END OF LOGIC ---

            // 3. UPDATE THE WIDGET'S STYLE
            updateWidgetStyle(context, currentStreak, isStreakInDanger)

            return Result.success()

        } catch (e: Exception) {
            Log.e("StreakCheckWorker", "Worker failed", e)
            return Result.failure()
        }
    }

    // Helper to update the widget's appearance
    private fun updateWidgetStyle(context: Context, streak: Int, inDanger: Boolean) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, StreakWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget)

            if (inDanger) {
                // Lost streak
                views.setTextViewText(R.id.tv_streak_count, "0")
                views.setTextViewText(R.id.tv_streak_label, "Streak lost!")
                views.setImageViewResource(R.id.iv_flame, R.drawable.deactive)
            } else {
                // Safe / active streak
                val label = if (streak == 1) "day streak" else "days streak"
                views.setTextViewText(R.id.tv_streak_count, streak.toString())
                views.setTextViewText(R.id.tv_streak_label, label)

                when {
                    streak >= 2 -> {
                        // Good streak
                        views.setImageViewResource(R.id.iv_flame, R.drawable.arcon_orange)
                    }
                    streak == 1 -> {
                        // Slightly inactive
                        views.setImageViewResource(R.id.iv_flame, R.drawable.arcon_blue)
                    }
                    else -> {
                        // Inactive
                        views.setImageViewResource(R.id.iv_flame, R.drawable.deactive)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        Log.d("StreakCheckWorker", "Widget style updated. InDanger=$inDanger")
    }

}