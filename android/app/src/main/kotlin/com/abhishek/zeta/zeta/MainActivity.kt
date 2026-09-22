package com.abhishek.zeta.zeta

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zeta/android_shortcuts"
    private var initialShortcut: String? = null
    private var channel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        extractShortcut(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractShortcut(intent)
        val s = initialShortcut
        if (s != null) {
            channel?.invokeMethod("onShortcut", s)
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

        // If a shortcut was captured during cold start before engine attached, dispatch it
        if (initialShortcut != null) {
            channel?.invokeMethod("onShortcut", initialShortcut)
        }
    }
}
