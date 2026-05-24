package com.example.jobtime_proof

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "jobtime_proof/share"
    private var pendingSharedUrl: String? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getAndClearSharedUrl") {
                result.success(pendingSharedUrl)
                pendingSharedUrl = null
            } else {
                result.notImplemented()
            }
        }
        handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return

        val text = buildString {
            append(intent.getStringExtra(Intent.EXTRA_TEXT) ?: "")
            append(" ")
            append(intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "")
        }

        val url = extractFirstUrl(text)
        if (url.isNullOrBlank()) return

        pendingSharedUrl = url
        channel?.invokeMethod("onSharedUrl", url)
    }

    private fun extractFirstUrl(text: String?): String? {
        if (text.isNullOrBlank()) return null
        val regex = Regex("""https?://[^\s]+""", RegexOption.IGNORE_CASE)
        return regex.find(text)?.value
    }
}
