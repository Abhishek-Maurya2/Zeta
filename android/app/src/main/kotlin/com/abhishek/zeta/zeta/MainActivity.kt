package com.abhishek.zeta.zeta

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zeta/android_shortcuts"
    private val WIDGET_CHANNEL = "zeta/tasks_widget"
    private var initialShortcut: String? = null
    private var initialWidgetAction: Map<String, String>? = null
    private var channel: MethodChannel? = null
    private var widgetChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        extractShortcut(intent)
        extractWidgetAction(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractShortcut(intent)
        extractWidgetAction(intent)
        val s = initialShortcut
        if (s != null) {
            channel?.invokeMethod("onShortcut", s)
        }
        val widgetAction = initialWidgetAction
        if (widgetAction != null && widgetChannel != null) {
            widgetChannel?.invokeMethod("onWidgetAction", widgetAction, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (initialWidgetAction == widgetAction) initialWidgetAction = null
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit
                override fun notImplemented() = Unit
            })
        }
    }

    private fun extractShortcut(intent: Intent?) {
        if (intent == null) return
        val shortcut = intent.getStringExtra("route")
            ?: intent.getStringExtra("some unique action key")
            ?: intent.getStringExtra("shortcut_type")
            ?: intent.data?.getQueryParameter("route")

        if (shortcut != null) {
            initialShortcut = shortcut
            // Ensure the intent contains the extra key expected by the quick_actions plugin
            intent.putExtra("some unique action key", shortcut)
        }
    }

    private fun extractWidgetAction(intent: Intent?) {
        val action = intent?.getStringExtra(TasksWidgetContract.EXTRA_ACTION) ?: return
        initialWidgetAction = mapOf(
            "action" to action,
            "taskId" to (intent.getStringExtra(TasksWidgetContract.EXTRA_TASK_ID) ?: ""),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialShortcut") {
                val s = initialShortcut
                initialShortcut = null
                result.success(s)
            } else {
                result.notImplemented()
            }
        }

        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceSeedColor" -> result.success(TasksWidgetProvider.deviceSeedColor(this))
                "getInitialWidgetAction" -> {
                    result.success(initialWidgetAction)
                    initialWidgetAction = null
                }
                "updateWidget" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("invalid_arguments", "Widget data is missing", null)
                    } else {
                        val tasks = args["tasks"]?.toString() ?: "[]"
                        val prefs = getSharedPreferences(TasksWidgetContract.PREFERENCES, MODE_PRIVATE)
                        prefs.edit()
                            .putString(TasksWidgetContract.KEY_TASKS, tasks)
                            .putInt(TasksWidgetContract.KEY_BACKGROUND, (args["background"] as? Number)?.toInt() ?: 0xFF6750A4.toInt())
                            .putInt(TasksWidgetContract.KEY_FOREGROUND, (args["foreground"] as? Number)?.toInt() ?: 0xFFFFFFFF.toInt())
                            .putInt(TasksWidgetContract.KEY_ACCENT, (args["accent"] as? Number)?.toInt() ?: 0xFFD0BCFF.toInt())
                            .putInt(TasksWidgetContract.KEY_ACCENT_FOREGROUND, (args["accentForeground"] as? Number)?.toInt() ?: 0xFF381E72.toInt())
                            .apply()
                        TasksWidgetProvider.refreshAll(this)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // If a shortcut was captured during cold start before engine attached, dispatch it
        if (initialShortcut != null) {
            channel?.invokeMethod("onShortcut", initialShortcut)
        }
    }
}
