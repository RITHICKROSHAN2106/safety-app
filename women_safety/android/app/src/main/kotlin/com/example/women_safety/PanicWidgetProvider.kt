package com.example.women_safety

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

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
        // Widget is added for the first time
    }

    override fun onDisabled(context: Context) {
        // Last widget is removed
    }

    companion object {
        private const val PANIC_ACTION = "com.example.women_safety.PANIC_BUTTON_CLICKED"
        
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val userName = widgetData.getString("user_name", "User")
            val contactCount = widgetData.getInt("contact_count", 0)
            val isEnabled = widgetData.getBoolean("is_enabled", true)
            val statusText = widgetData.getString("status_text", "Tap for Emergency")

            // Create views
            val views = RemoteViews(context.packageName, R.layout.panic_widget)
            
            // Update text
            views.setTextViewText(R.id.widget_title, "🚨 PANIC SOS")
            views.setTextViewText(R.id.widget_status, statusText)
            views.setTextViewText(R.id.contact_count, "$contactCount contacts")
            
            // Set button enabled/disabled state
            views.setBoolean(R.id.panic_button, "setEnabled", isEnabled)
            
            // Create panic button intent
            val panicIntent = Intent(context, PanicWidgetProvider::class.java).apply {
                action = PANIC_ACTION
                data = Uri.parse("homewidget://panic")
            }
            
            val panicPendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                panicIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            views.setOnClickPendingIntent(R.id.panic_button, panicPendingIntent)
            
            // Update widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        
        if (intent?.action == PANIC_ACTION) {
            // Panic button clicked
            context?.let { ctx ->
                // Store panic trigger in SharedPreferences
                val prefs = ctx.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putBoolean("panic_triggered", true)
                    putLong("panic_timestamp", System.currentTimeMillis())
                    apply()
                }
                
                // Launch app
                val launchIntent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
                launchIntent?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    data = Uri.parse("homewidget://panic")
                }
                ctx.startActivity(launchIntent)
            }
        }
    }
}
