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
import org.json.JSONArray

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
        when (intent.action) {
            Intent.ACTION_WALLPAPER_CHANGED,
            Intent.ACTION_CONFIGURATION_CHANGED -> refreshAll(context)
            ACTION_WIDGET_CLICK -> {
                val widgetAction = intent.getStringExtra(TasksWidgetContract.EXTRA_ACTION) ?: return
                val taskId = intent.getStringExtra(TasksWidgetContract.EXTRA_TASK_ID) ?: return
                when (widgetAction) {
                    TasksWidgetContract.ACTION_TOGGLE -> {
                        toggleTaskLocally(context, taskId)
                        refreshAll(context)
                        // Forward to Flutter engine (if running) so the DB is updated too.
                        MainActivity.activeWidgetChannel?.invokeMethod(
                            "onWidgetAction",
                            mapOf("action" to TasksWidgetContract.ACTION_TOGGLE, "taskId" to taskId),
                        )
                    }
                    TasksWidgetContract.ACTION_EDIT -> {
                        // Launch the app with the edit action
                        val launchIntent = widgetActionIntent(context, TasksWidgetContract.ACTION_EDIT)
                            .putExtra(TasksWidgetContract.EXTRA_TASK_ID, taskId)
                        context.startActivity(launchIntent)
                    }
                }
            }
        }
    }

    companion object {
        internal const val ACTION_WIDGET_CLICK = "com.abhishek.zeta.WIDGET_CLICK"

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

                tintBackground(views, R.id.widget_root, palette.secondaryContainer)
                views.setTextColor(R.id.widget_title, palette.onSecondaryContainer)
                views.setTextColor(R.id.widget_empty, palette.onSecondaryContainer)
                tintBackground(views, R.id.widget_add, palette.primary)
                views.setInt(R.id.widget_add, "setColorFilter", palette.onPrimary)

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

                // --- Row interactions: broadcast-based (checkbox toggles silently, title edits open app) ---
                val clickTemplate = Intent(context, TasksWidgetProvider::class.java)
                    .setAction(ACTION_WIDGET_CLICK)
                val clickPendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 3 + 2,
                    clickTemplate,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0),
                )
                views.setPendingIntentTemplate(R.id.widget_task_list, clickPendingIntent)

                manager.updateAppWidget(appWidgetId, views)
            }

            if (appWidgetIds.isNotEmpty()) {
                manager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_task_list)
            }
        }

        /** Toggle a task's completed state in SharedPreferences (widget-local). */
        private fun toggleTaskLocally(context: Context, taskId: String) {
            val prefs = context.getSharedPreferences(TasksWidgetContract.PREFERENCES, Context.MODE_PRIVATE)
            val raw = prefs.getString(TasksWidgetContract.KEY_TASKS, "[]") ?: "[]"
            try {
                val array = JSONArray(raw)
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    if (obj.optString("id") == taskId) {
                        obj.put("completed", !obj.optBoolean("completed", false))
                        break
                    }
                }
                prefs.edit().putString(TasksWidgetContract.KEY_TASKS, array.toString()).apply()
            } catch (_: Exception) {
                // Malformed JSON — ignore, the next Flutter push will fix it.
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
            val fallbackSecondaryContainer = prefs.getInt(
                TasksWidgetContract.KEY_SECONDARY_CONTAINER,
                0xFF7D5260.toInt(),
            )
            val fallbackOnSecondaryContainer = prefs.getInt(
                TasksWidgetContract.KEY_ON_SECONDARY_CONTAINER,
                Color.WHITE,
            )
            val fallbackPrimary = prefs.getInt(TasksWidgetContract.KEY_PRIMARY, 0xFF6750A4.toInt())
            val fallbackOnPrimary = prefs.getInt(TasksWidgetContract.KEY_ON_PRIMARY, Color.WHITE)
            val fallbackOnSurface = prefs.getInt(TasksWidgetContract.KEY_ON_SURFACE, Color.WHITE)
            return WidgetPalette(
                secondaryContainer = fallbackSecondaryContainer,
                onSecondaryContainer = fallbackOnSecondaryContainer,
                primary = fallbackPrimary,
                onPrimary = fallbackOnPrimary,
                onSurface = fallbackOnSurface,
            )
        }

        internal fun deviceAccentColor(context: Context): Int? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
            return runCatching {
                context.getColor(android.R.color.system_accent1_500)
            }.getOrElse {
                val resourceId = context.resources.getIdentifier("system_accent1_500", "color", "android")
                if (resourceId != 0) context.resources.getColor(resourceId, context.theme) else null
            }
        }

        private fun tintBackground(views: RemoteViews, viewId: Int, color: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(viewId, "setBackgroundTintList", ColorStateList.valueOf(color))
            } else {
                views.setInt(viewId, "setBackgroundColor", color)
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
    val secondaryContainer: Int,
    val onSecondaryContainer: Int,
    val primary: Int,
    val onPrimary: Int,
    val onSurface: Int,
) {
    val tertiaryContainer: Int get() = secondaryContainer
    val onTertiaryContainer: Int get() = onSecondaryContainer
}
