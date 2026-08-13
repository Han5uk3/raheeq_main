package com.rahiq.app

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.rahiq.app/downloads"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> saveToDownloads(
                        call.argument("path"),
                        call.argument("fileName"),
                        call.argument("mimeType"),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Copies an already downloaded file into the phone's public Downloads
     * collection, where the Files app and the notification shade's download
     * list can see it.
     *
     * Scoped storage blocks a plain write to that folder, so it goes through
     * MediaStore instead — which also means no storage permission is needed.
     * Returns null when it cannot be done, and the Dart side falls back to the
     * share sheet rather than leaving the user with nothing.
     */
    private fun saveToDownloads(
        sourcePath: String?,
        fileName: String?,
        mimeType: String?,
        result: MethodChannel.Result,
    ) {
        // MediaStore.Downloads only exists from API 29. Writing to the public
        // folder before that needs WRITE_EXTERNAL_STORAGE, which this app
        // deliberately does not ask for.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(null)
            return
        }

        if (sourcePath == null || fileName == null) {
            result.success(null)
            return
        }

        val source = File(sourcePath)
        if (!source.exists()) {
            result.success(null)
            return
        }

        val resolver = contentResolver
        var uri: android.net.Uri? = null

        try {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                if (mimeType != null) {
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                }
                // Keeps the entry hidden until the bytes are all there, so
                // nothing can open a half written file.
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            if (uri == null) {
                result.success(null)
                return
            }

            val stream = resolver.openOutputStream(uri)
            if (stream == null) {
                resolver.delete(uri, null, null)
                result.success(null)
                return
            }

            stream.use { out -> source.inputStream().use { input -> input.copyTo(out) } }

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            result.success(fileName)
        } catch (e: Exception) {
            // A half written entry would show up as a broken file, so drop it.
            uri?.let { runCatching { resolver.delete(it, null, null) } }
            result.success(null)
        }
    }
}
