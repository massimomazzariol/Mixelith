package com.mixelith.image

import android.content.Context
import android.graphics.ImageDecoder
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.max

class ImageNormalizerBridge(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "normalizeHeif" -> normalizeHeif(call, result)
            else -> result.notImplemented()
        }
    }

    private fun normalizeHeif(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val previewMaxLongSide = call.argument<Int>("previewMaxLongSide") ?: 1080
        if (sourcePath.isNullOrBlank()) {
            result.error("invalid_source", "This HEIC photo could not be imported on this device.", null)
            return
        }

        Thread {
            try {
                val response = normalize(sourcePath, previewMaxLongSide)
                Handler(Looper.getMainLooper()).post {
                    result.success(response)
                }
            } catch (error: Throwable) {
                Handler(Looper.getMainLooper()).post {
                    result.error(
                        "heif_import_failed",
                        "This HEIC photo could not be imported on this device.",
                        null,
                    )
                }
            }
        }.start()
    }

    private fun normalize(sourcePath: String, previewMaxLongSide: Int): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            throw IllegalStateException("HEIC import requires Android 9 or newer.")
        }
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            throw IllegalStateException("Source file does not exist.")
        }

        val bitmap = decodeBitmap(sourceFile)
        try {
            val directory = File(context.cacheDir, "image_normalizer")
            directory.mkdirs()
            val timestamp = System.currentTimeMillis()
            val originalFile = File(directory, "heif_original_$timestamp.jpg")
            val previewFile = File(directory, "heif_preview_$timestamp.jpg")

            saveJpeg(bitmap, originalFile, 92)
            val preview = previewBitmap(bitmap, previewMaxLongSide)
            try {
                saveJpeg(preview.bitmap, previewFile, 88)
            } finally {
                if (preview.bitmap !== bitmap) {
                    preview.bitmap.recycle()
                }
            }

            return mapOf(
                "originalPath" to originalFile.absolutePath,
                "previewPath" to previewFile.absolutePath,
                "originalWidth" to bitmap.width,
                "originalHeight" to bitmap.height,
                "previewWidth" to preview.width,
                "previewHeight" to preview.height,
                "wasPreviewDownscaled" to preview.wasDownscaled,
            )
        } finally {
            bitmap.recycle()
        }
    }

    private fun decodeBitmap(file: File): android.graphics.Bitmap {
        return ImageDecoder.decodeBitmap(ImageDecoder.createSource(file)) { decoder, _, _ ->
            decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE)
        }
    }

    private fun saveJpeg(bitmap: android.graphics.Bitmap, file: File, quality: Int) {
        file.outputStream().use { output ->
            if (!bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, quality.coerceIn(1, 100), output)) {
                throw IllegalStateException("Unable to write JPEG normalization file.")
            }
        }
    }

    private fun previewBitmap(bitmap: android.graphics.Bitmap, maxLongSide: Int): PreviewBitmap {
        val longestSide = max(bitmap.width, bitmap.height)
        if (maxLongSide <= 0 || longestSide <= maxLongSide) {
            return PreviewBitmap(
                bitmap = bitmap,
                width = bitmap.width,
                height = bitmap.height,
                wasDownscaled = false,
            )
        }

        val scale = maxLongSide.toDouble() / longestSide.toDouble()
        val targetWidth = max(1, (bitmap.width * scale).toInt())
        val targetHeight = max(1, (bitmap.height * scale).toInt())
        val preview = android.graphics.Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
        return PreviewBitmap(
            bitmap = preview,
            width = targetWidth,
            height = targetHeight,
            wasDownscaled = true,
        )
    }

    private data class PreviewBitmap(
        val bitmap: android.graphics.Bitmap,
        val width: Int,
        val height: Int,
        val wasDownscaled: Boolean,
    )

    companion object {
        const val channelName = "mixelith/image_normalizer"
    }
}
