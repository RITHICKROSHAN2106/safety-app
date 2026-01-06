package com.example.women_safety_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.app.PendingIntent
import android.net.Uri

/**
 * Panic Widget Provider
 * Home screen widget for quick SOS access
 */
class PanicWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget added for the first time
    }

    override fun onDisabled(context: Context) {
        // Last widget removed
    }

    companion object {
        private const val SOS_ACTION = "com.example.women_safety_app.SOS_ACTION"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Get shared preferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val userName = prefs.getString("flutter.user_name", "User") ?: "User"
            val guardianCount = prefs.getInt("flutter.guardian_count", 0)
            val safetyStatus = prefs.getString("flutter.safety_status", "Safe") ?: "Safe"

            // Create RemoteViews
            val views = RemoteViews(context.packageName, R.layout.panic_widget)

            // Set widget data
            views.setTextViewText(R.id.widget_user_name, userName)
            views.setTextViewText(R.id.widget_guardian_count, "$guardianCount Guardians")
            views.setTextViewText(R.id.widget_safety_status, safetyStatus)

            // SOS Button click intent
            val sosIntent = Intent(context, PanicWidgetProvider::class.java).apply {
                action = SOS_ACTION
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }

            val sosPendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                sosIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_sos_button, sosPendingIntent)

            // Widget click to open app
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

            // Update widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == SOS_ACTION) {
            // SOS button clicked - open app and trigger SOS
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("trigger_sos", true)
            }
            context.startActivity(openAppIntent)
        }
    }
}
