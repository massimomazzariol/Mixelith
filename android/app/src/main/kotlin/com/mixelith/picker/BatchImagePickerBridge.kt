package com.mixelith.picker

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class BatchImagePickerBridge(
    private val activity: Activity,
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingPickerApi: String? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickImage" -> pickImages(result, allowMultiple = false)
            "pickImages" -> pickImages(result, allowMultiple = true)
            else -> result.notImplemented()
        }
    }

    private fun pickImages(result: MethodChannel.Result, allowMultiple: Boolean) {
        if (pendingResult != null) {
            result.error("busy", "Another photo picker is already open.", null)
            return
        }

        pendingResult = result
        val modernIntent = photoPickerIntent(allowMultiple)
        val pickerApi = if (modernIntent != null) photoPickerApi else documentPickerApi
        val intent = modernIntent ?: documentPickerIntent(allowMultiple)
        pendingPickerApi = pickerApi

        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (error: Throwable) {
            if (modernIntent != null) {
                startDocumentPickerFallback(result, allowMultiple, error)
                return
            }
            pendingResult = null
            pendingPickerApi = null
            result.error("picker_unavailable", error.message ?: "Photo picker unavailable.", null)
        }
    }

    private fun startDocumentPickerFallback(
        result: MethodChannel.Result,
        allowMultiple: Boolean,
        originalError: Throwable,
    ) {
        val fallback = documentPickerIntent(allowMultiple)
        pendingPickerApi = documentPickerApi
        try {
            activity.startActivityForResult(fallback, requestCode)
        } catch (fallbackError: Throwable) {
            pendingResult = null
            pendingPickerApi = null
            result.error(
                "picker_unavailable",
                fallbackError.message ?: originalError.message ?: "Photo picker unavailable.",
                null,
            )
        }
    }

    private fun photoPickerIntent(allowMultiple: Boolean): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return null
        }
        val intent = Intent(MediaStore.ACTION_PICK_IMAGES).apply {
            type = "image/*"
            if (allowMultiple) {
                putExtra(
                    MediaStore.EXTRA_PICK_IMAGES_MAX,
                    minOf(defaultMaxSelection, MediaStore.getPickImagesMaxLimit()),
                )
            }
        }
        return if (intent.resolveActivity(activity.packageManager) == null) {
            null
        } else {
            intent
        }
    }

    private fun documentPickerIntent(allowMultiple: Boolean): Intent {
        return Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != BatchImagePickerBridge.requestCode) {
            return false
        }

        val result = pendingResult ?: return true
        val pickerApi = pendingPickerApi ?: unknownPickerApi
        pendingResult = null
        pendingPickerApi = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(cancelled(pickerApi))
            return true
        }

        val uris = selectedUris(data)
        if (uris.isEmpty()) {
            result.success(failed("No photos were selected.", pickerApi))
            return true
        }

        Thread {
            val response = importUris(uris, pickerApi)
            Handler(Looper.getMainLooper()).post {
                result.success(response)
            }
        }.start()

        return true
    }

    private fun selectedUris(data: Intent?): List<Uri> {
        if (data == null) {
            return emptyList()
        }

        val uris = mutableListOf<Uri>()
        val clipData = data.clipData
        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                clipData.getItemAt(index)?.uri?.let { uris.add(it) }
            }
        }
        data.data?.let { uri ->
            if (!uris.contains(uri)) {
                uris.add(uri)
            }
        }
        return uris
    }

    private fun importUris(uris: List<Uri>, pickerApi: String): Map<String, Any?> {
        val items = mutableListOf<Map<String, Any?>>()
        val errors = mutableListOf<String>()

        uris.forEachIndexed { index, uri ->
            try {
                items.add(importUri(uri, index))
            } catch (error: Throwable) {
                errors.add(error.message ?: "Unable to import selected photo.")
            }
        }

        if (items.isEmpty() && errors.isNotEmpty()) {
            return failed(errors.joinToString("\n"), pickerApi)
        }

        return mapOf(
            "success" to true,
            "status" to "picked",
            "pickerApi" to pickerApi,
            "items" to items,
            "errors" to errors,
            "message" to if (errors.isEmpty()) null else errors.joinToString("\n"),
        )
    }

    private fun importUri(uri: Uri, index: Int): Map<String, Any?> {
        val displayName = displayName(uri) ?: "photo_${index + 1}"
        val extension = extension(displayName, context.contentResolver.getType(uri))
        val directory = File(context.cacheDir, "batch_picker")
        directory.mkdirs()
        val target = File(
            directory,
            "batch_photo_${System.currentTimeMillis()}_${index + 1}.$extension",
        )

        context.contentResolver.openInputStream(uri).use { input ->
            if (input == null) {
                throw IllegalStateException("Unable to open $displayName.")
            }
            target.outputStream().use { output ->
                input.copyTo(output)
            }
        }

        val dimensions = dimensions(target)
        if (dimensions.first <= 0 || dimensions.second <= 0) {
            throw IllegalStateException("Unable to read image dimensions for $displayName.")
        }

        return mapOf(
            "id" to target.nameWithoutExtension,
            "path" to target.absolutePath,
            "displayName" to displayName,
            "extension" to extension,
            "width" to dimensions.first,
            "height" to dimensions.second,
        )
    }

    private fun dimensions(file: File): Pair<Int, Int> {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(file.absolutePath, options)
        return Pair(options.outWidth, options.outHeight)
    }

    private fun displayName(uri: Uri): String? {
        context.contentResolver.query(uri, null, null, null, null).use { cursor ->
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) {
                    return cursor.getString(index)
                }
            }
        }
        return uri.lastPathSegment
    }

    private fun extension(displayName: String, mimeType: String?): String {
        val nameExtension = displayName
            .substringAfterLast('.', "")
            .lowercase(Locale.US)
            .takeIf { it.isSafeExtension() }
        if (nameExtension != null) {
            return nameExtension
        }

        return when (mimeType?.lowercase(Locale.US)) {
            "image/jpeg", "image/jpg" -> "jpg"
            "image/png" -> "png"
            "image/webp" -> "webp"
            "image/heic" -> "heic"
            "image/heif" -> "heif"
            else -> "jpg"
        }
    }

    private fun String.isSafeExtension(): Boolean {
        return isNotEmpty() && all { character ->
            character in 'a'..'z' || character in '0'..'9'
        }
    }

    private fun cancelled(pickerApi: String): Map<String, Any?> {
        return mapOf(
            "success" to false,
            "status" to "cancelled",
            "pickerApi" to pickerApi,
            "message" to "Photo selection was cancelled.",
        )
    }

    private fun failed(message: String, pickerApi: String): Map<String, Any?> {
        return mapOf(
            "success" to false,
            "status" to "failed",
            "pickerApi" to pickerApi,
            "message" to message,
        )
    }

    companion object {
        const val channelName = "mixelith/batch_image_picker"
        private const val requestCode = 9053
        private const val defaultMaxSelection = 100
        private const val photoPickerApi = "android_photo_picker"
        private const val documentPickerApi = "action_open_document"
        private const val unknownPickerApi = "unknown"
    }
}
