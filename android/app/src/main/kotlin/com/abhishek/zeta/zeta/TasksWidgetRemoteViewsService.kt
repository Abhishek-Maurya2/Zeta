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
        views.setTextColor(R.id.widget_task_title, palette.onSecondaryContainer)
        if (row.due.isBlank()) {
            views.setViewVisibility(R.id.widget_due_container, View.GONE)
        } else {
            views.setTextViewText(R.id.widget_task_due, row.due)
            views.setTextColor(R.id.widget_task_due, palette.primary)
            views.setInt(R.id.widget_due_icon, "setColorFilter", palette.primary)
            views.setViewVisibility(R.id.widget_due_container, View.VISIBLE)
        }

        if (row.completed) {
            views.setImageViewResource(R.id.widget_checkbox, R.drawable.widget_checkbox_filled)
            views.setInt(R.id.widget_checkbox, "setColorFilter", palette.primary)
            views.setImageViewResource(R.id.widget_checkbox_check, R.drawable.widget_check_icon)
            views.setInt(R.id.widget_checkbox_check, "setColorFilter", palette.onPrimary)
            views.setViewVisibility(R.id.widget_checkbox_check, View.VISIBLE)
        } else {
            views.setImageViewResource(R.id.widget_checkbox, R.drawable.widget_checkbox_outline)
            views.setInt(R.id.widget_checkbox, "setColorFilter", palette.onSecondaryContainer)
            views.setViewVisibility(R.id.widget_checkbox_check, View.GONE)
        }

        // Checkbox: toggle action (handled as broadcast, no app launch)
        views.setOnClickFillInIntent(
            R.id.widget_checkbox_touch,
            TasksWidgetProvider.fillInIntent(TasksWidgetContract.ACTION_TOGGLE, row.id),
        )
        // Title area: edit action (opens the app with task edit sheet)
        views.setOnClickFillInIntent(
            R.id.widget_title_touch,
            TasksWidgetProvider.fillInIntent(TasksWidgetContract.ACTION_EDIT, row.id),
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
