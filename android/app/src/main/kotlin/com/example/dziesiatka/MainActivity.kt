package com.example.dziesiatka

import android.content.ComponentName
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "shareImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    shareImage(call)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_failed", error.message, null)
                }
            }
    }

    private fun shareImage(call: MethodCall) {
        val folder = File(cacheDir, "shared_images").apply { mkdirs() }
        val file = File(folder, call.argument<String>("fileName")!!)
        file.writeBytes(call.argument<ByteArray>("bytes")!!)
        val uri = FileProvider.getUriForFile(this, "$packageName.share_images", file)

        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(send, call.argument<String>("title")).apply {
            putExtra(Intent.EXTRA_EXCLUDE_COMPONENTS, REELS_TARGETS)
        }
        startActivity(chooser)
    }

    private companion object {
        const val SHARE_CHANNEL = "dziesiatka/share"

        // Reels is a video format, so these targets turn the image into a video.
        // The names are internal to those apps and can change with their updates.
        val REELS_TARGETS = arrayOf(
            ComponentName(
                "com.instagram.android",
                "com.instagram.share.handleractivity.ReelShareHandlerActivity",
            ),
            ComponentName(
                "com.facebook.katana",
                "com.facebook.inspiration.fbshorts.shareintent.InpirationFbShortsSharePhotoAlias",
            ),
            ComponentName(
                "com.facebook.katana",
                "com.facebook.inspiration.fbshorts.shareintent.InpirationFbShortsShareAlias",
            ),
        )
    }
}
