package dev.tukiapp.tuki_little_adventures

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.tukiapp.tuki_little_adventures/external_url",
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val rawUrl = call.argument<String>("url")
            if (rawUrl != PRIVACY_POLICY_URL) {
                result.error("invalid_url", "Only the TUKI privacy policy is allowed", null)
                return@setMethodCallHandler
            }
            val uri = Uri.parse(rawUrl)
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addCategory(Intent.CATEGORY_BROWSABLE)
            }
            if (intent.resolveActivity(packageManager) == null) {
                result.success(false)
                return@setMethodCallHandler
            }
            startActivity(intent)
            result.success(true)
        }
    }

    private companion object {
        const val PRIVACY_POLICY_URL = "https://tuki.artwebcr.com/privacy"
    }
}
