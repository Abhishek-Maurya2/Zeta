package com.abhishek.zeta.zeta

import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.view.View
import org.json.JSONArray

class TasksWidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = TasksWidgetFactory(this)
}

private class TasksWidgetFactory(private val context: TasksWidgetRemoteViewsService) :
    RemoteViewsService.RemoteViewsFactory {
    private var rows: List<WidgetTaskRow> = emptyList()
    private var palette = TasksWidgetProvider.widgetPalette(context)

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        rows = TasksWidgetProvider.taskRows(context)
        palette = TasksWidgetProvider.widgetPalette(context)
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews? {
        val row = rows.getOrNull(position) ?: return null
        val views = RemoteViews(context.packageName, R.layout.tasks_widget_row)

        views.setTextViewText(R.id.widget_task_title, row.title)
        views.setTextColor(R.id.widget_task_title, palette.foreground)
        if (row.due.isBlank()) {
            views.setViewVisibility(R.id.widget_task_due, View.GONE)
        } else {
            views.setTextViewText(R.id.widget_task_due, row.due)
            views.setTextColor(R.id.widget_task_due, (palette.foreground and 0x00FFFFFF) or (0xD9 shl 24))
            views.setViewVisibility(R.id.widget_task_due, View.VISIBLE)
        }

        if (row.completed) {
            views.setImageViewResource(R.id.widget_checkbox, R.drawable.widget_checkbox_filled)
            views.setInt(R.id.widget_checkbox, "setColorFilter", palette.accent)
            views.setTextViewText(R.id.widget_checkbox_check, "✓")
            views.setTextColor(R.id.widget_checkbox_check, palette.accentForeground)
            views.setViewVisibility(R.id.widget_checkbox_check, View.VISIBLE)
        } else {
            views.setImageViewResource(R.id.widget_checkbox, R.drawable.widget_checkbox_outline)
            views.setInt(R.id.widget_checkbox, "setColorFilter", palette.foreground)
            views.setViewVisibility(R.id.widget_checkbox_check, View.GONE)
        }

        views.setOnClickFillInIntent(
            R.id.widget_task_row,
            TasksWidgetProvider.fillInIntent(TasksWidgetContract.ACTION_EDIT, row.id),
        )
        views.setOnClickFillInIntent(
            R.id.widget_checkbox_touch,
            TasksWidgetProvider.fillInIntent(TasksWidgetContract.ACTION_TOGGLE, row.id),
        )
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = rows.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()
    override fun hasStableIds(): Boolean = true
}

internal data class WidgetTaskRow(
    val id: String,
    val title: String,
    val due: String,
    val completed: Boolean,
) {
    companion object {
        fun decode(json: String): List<WidgetTaskRow> = runCatching {
            val array = JSONArray(json)
            (0 until array.length()).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                val id = item.optString("id")
                if (id.isBlank()) return@mapNotNull null
                WidgetTaskRow(
                    id = id,
                    title = item.optString("title", "Task"),
                    due = item.optString("due", ""),
                    completed = item.optBoolean("completed", false),
                )
            }
        }.getOrDefault(emptyList())
    }
}
