package com.mixelith.image

import android.graphics.ImageDecoder
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.heifwriter.HeifWriter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class HeifExportBridge : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "encodeHeif" -> encodeHeif(call, result)
            else -> result.notImplemented()
        }
    }

    private fun encodeHeif(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
        val outputPath = call.argument<String>("outputPath")
        val quality = call.argument<Int>("quality") ?: 90
        if (inputPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
            result.error("invalid_export", "HEIC export is not available on this device.", null)
            return
        }

        Thread {
            try {
                val response = encode(inputPath, outputPath, quality)
                Handler(Looper.getMainLooper()).post {
                    result.success(response)
                }
            } catch (error: Throwable) {
                Handler(Looper.getMainLooper()).post {
                    result.error(
                        "heif_export_failed",
                        "HEIC export is not available on this device.",
                        null,
                    )
                }
            }
        }.start()
    }

    private fun encode(inputPath: String, outputPath: String, quality: Int): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            throw IllegalStateException("HEIC export requires Android 9 or newer.")
        }
        val inputFile = File(inputPath)
        if (!inputFile.exists()) {
            throw IllegalStateException("Input file does not exist.")
        }

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) {
            outputFile.delete()
        }

        val bitmap = decodeBitmap(inputFile)
        var writer: HeifWriter? = null
        try {
            writer = HeifWriter.Builder(
                outputFile.absolutePath,
                bitmap.width,
                bitmap.height,
                HeifWriter.INPUT_MODE_BITMAP,
            )
                .setQuality(quality.coerceIn(1, 100))
                .build()
            writer.start()
            writer.addBitmap(bitmap)
            writer.stop(10_000)

            if (!outputFile.exists() || outputFile.length() <= 0) {
                throw IllegalStateException("HEIC encoder did not produce a file.")
            }

            return mapOf(
                "path" to outputFile.absolutePath,
                "width" to bitmap.width,
                "height" to bitmap.height,
            )
        } catch (error: Throwable) {
            if (outputFile.exists()) {
                outputFile.delete()
            }
            throw error
        } finally {
            writer?.close()
            bitmap.recycle()
        }
    }

    private fun decodeBitmap(file: File): android.graphics.Bitmap {
        return ImageDecoder.decodeBitmap(ImageDecoder.createSource(file)) { decoder, _, _ ->
            decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE)
        }
    }

    companion object {
        const val channelName = "mixelith/heif_export"
    }
}
