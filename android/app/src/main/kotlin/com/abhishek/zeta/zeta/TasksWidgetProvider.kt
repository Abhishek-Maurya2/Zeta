package com.abhishek.zeta.zeta

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews

class TasksWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        refresh(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        refresh(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_WALLPAPER_CHANGED) {
            refreshAll(context)
        }
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TasksWidgetProvider::class.java)
            refresh(context, manager, manager.getAppWidgetIds(component))
        }

        private fun refresh(
            context: Context,
            manager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.tasks_widget)
                val palette = widgetPalette(context)

                tintBackground(views, R.id.widget_root, palette.background)
                views.setTextColor(R.id.widget_title, palette.foreground)
                views.setTextColor(R.id.widget_empty, palette.foreground)
                tintBackground(views, R.id.widget_add, palette.accent)
                views.setInt(R.id.widget_add, "setColorFilter", palette.accentForeground)

                val addIntent = widgetActionIntent(context, TasksWidgetContract.ACTION_CREATE)
                val addPendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId * 3,
                    addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_add, addPendingIntent)

                val adapterIntent = Intent(context, TasksWidgetRemoteViewsService::class.java)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    .setData(Uri.parse("zeta://tasks-widget/$appWidgetId"))
                views.setRemoteAdapter(R.id.widget_task_list, adapterIntent)
                views.setEmptyView(R.id.widget_task_list, R.id.widget_empty)

                val rowIntent = widgetActionIntent(context, "")
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                val rowPendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId * 3 + 1,
                    rowIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0),
                )
                views.setPendingIntentTemplate(R.id.widget_task_list, rowPendingIntent)
                manager.updateAppWidget(appWidgetId, views)
            }

            if (appWidgetIds.isNotEmpty()) {
                manager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_task_list)
            }
        }

        internal fun taskRows(context: Context): List<WidgetTaskRow> {
            val raw = context.getSharedPreferences(
                TasksWidgetContract.PREFERENCES,
                Context.MODE_PRIVATE,
            ).getString(TasksWidgetContract.KEY_TASKS, "[]") ?: "[]"
            return WidgetTaskRow.decode(raw)
        }

        internal fun widgetPalette(context: Context): WidgetPalette {
            val prefs = context.getSharedPreferences(TasksWidgetContract.PREFERENCES, Context.MODE_PRIVATE)
            val fallbackBackground = prefs.getInt(TasksWidgetContract.KEY_BACKGROUND, 0xFF6750A4.toInt())
            val fallbackForeground = prefs.getInt(TasksWidgetContract.KEY_FOREGROUND, Color.WHITE)
            val fallbackAccent = prefs.getInt(TasksWidgetContract.KEY_ACCENT, 0xFFD0BCFF.toInt())
            val fallbackAccentForeground = prefs.getInt(TasksWidgetContract.KEY_ACCENT_FOREGROUND, 0xFF381E72.toInt())
            return WidgetPalette(fallbackBackground, fallbackForeground, fallbackAccent, fallbackAccentForeground)
        }

        internal fun deviceSeedColor(context: Context): Int? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
            val resourceId = context.resources.getIdentifier("system_accent1_500", "color", "android")
            if (resourceId == 0) return null
            return runCatching { context.resources.getColor(resourceId, context.theme) }.getOrNull()
        }

        private fun tintBackground(views: RemoteViews, viewId: Int, color: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(viewId, "setBackgroundTintList", ColorStateList.valueOf(color))
            }
        }

        internal fun widgetActionIntent(context: Context, action: String): Intent =
            Intent(context, MainActivity::class.java)
                .setAction("com.abhishek.zeta.WIDGET.$action")
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .also { if (action.isNotEmpty()) it.putExtra(TasksWidgetContract.EXTRA_ACTION, action) }

        internal fun fillInIntent(action: String, taskId: String): Intent =
            Intent().putExtra(TasksWidgetContract.EXTRA_ACTION, action)
                .putExtra(TasksWidgetContract.EXTRA_TASK_ID, taskId)
    }
}

internal data class WidgetPalette(
    val background: Int,
    val foreground: Int,
    val accent: Int,
    val accentForeground: Int,
)
