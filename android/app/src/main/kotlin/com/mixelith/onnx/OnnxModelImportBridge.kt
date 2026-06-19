package com.mixelith.onnx

import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class OnnxModelImportBridge(
    private val activity: Activity,
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private var pendingResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickAndImportModel" -> pickAndImportModel(result)
            else -> result.notImplemented()
        }
    }

    private fun pickAndImportModel(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another ONNX model import is already open.", null)
            return
        }

        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "application/octet-stream",
                    "application/x-onnx",
                    "model/onnx",
                ),
            )
        }

        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (error: Throwable) {
            pendingResult = null
            result.error("picker_unavailable", error.message ?: "ONNX picker unavailable.", null)
        }
    }

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != OnnxModelImportBridge.requestCode) {
            return false
        }

        val result = pendingResult ?: return true
        pendingResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(cancelled())
            return true
        }

        val uri = data?.data
        if (uri == null) {
            result.success(failed("No ONNX file was selected."))
            return true
        }

        Thread {
            val response = try {
                importUri(uri)
            } catch (error: Throwable) {
                failed(error.message ?: "Unable to import ONNX model.")
            }
            Handler(Looper.getMainLooper()).post {
                result.success(response)
            }
        }.start()

        return true
    }

    private fun importUri(uri: Uri): Map<String, Any?> {
        val displayName = displayName(uri) ?: "selected.onnx"
        if (!displayName.lowercase().endsWith(".onnx")) {
            return rejected("Select an .onnx model file.")
        }

        val directory = File(context.filesDir, "onnx_models")
        directory.mkdirs()
        val target = File(directory, "local_onnx_${System.currentTimeMillis()}.onnx")

        context.contentResolver.openInputStream(uri).use { input ->
            if (input == null) {
                return failed("Unable to open the selected ONNX model.")
            }
            target.outputStream().use { output ->
                input.copyTo(output)
            }
        }

        val inspection = inspectModel(target)
        val status = inspection.rejectionReason?.let { "rejected" } ?: "inspected"
        val reason = inspection.rejectionReason

        return mapOf(
            "success" to true,
            "status" to status,
            "id" to target.nameWithoutExtension,
            "storedPath" to target.absolutePath,
            "displayName" to displayName,
            "fileSizeBytes" to target.length(),
            "inputShape" to inspection.inputShape,
            "outputShape" to inspection.outputShape,
            "message" to reason,
        )
    }

    private fun inspectModel(modelFile: File): ModelInspection {
        val env = OrtEnvironment.getEnvironment()
        OrtSession.SessionOptions().use { options ->
            env.createSession(modelFile.absolutePath, options).use { session ->
                val inputName = session.inputNames.firstOrNull()
                val outputName = session.outputNames.firstOrNull()
                val inputShape = tensorShape(inputName?.let { session.inputInfo[it]?.info })
                val outputShape = tensorShape(outputName?.let { session.outputInfo[it]?.info })
                return ModelInspection(
                    inputShape = inputShape,
                    outputShape = outputShape,
                    rejectionReason = fixedShapeRejection(inputShape),
                )
            }
        }
    }

    private fun tensorShape(info: Any?): List<Long> {
        val tensorInfo = info as? TensorInfo ?: return emptyList()
        return tensorInfo.shape.toList()
    }

    private fun fixedShapeRejection(shape: List<Long>): String? {
        if (shape.size < 4) {
            return "ONNX input tensor shape must include batch, channel, height, and width."
        }

        val height = shape[2]
        val width = shape[3]
        if (height <= 0 || width <= 0) {
            return null
        }

        return "ONNX model input is fixed to ${width}x${height}; Mixelith requires dynamic full-frame input."
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

    private fun cancelled(): Map<String, Any?> {
        return mapOf(
            "success" to false,
            "status" to "cancelled",
            "message" to "ONNX model import was cancelled.",
        )
    }

    private fun rejected(message: String): Map<String, Any?> {
        return mapOf(
            "success" to true,
            "status" to "rejected",
            "message" to message,
        )
    }

    private fun failed(message: String): Map<String, Any?> {
        return mapOf(
            "success" to false,
            "status" to "failed_validation",
            "message" to message,
        )
    }

    private data class ModelInspection(
        val inputShape: List<Long>,
        val outputShape: List<Long>,
        val rejectionReason: String?,
    )

    companion object {
        const val channelName = "mixelith/onnx_model_import"
        private const val requestCode = 9042
    }
}
