package com.mixelith.onnx

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.roundToInt

class OnnxStyleTransferBridge(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "runStyleTransfer" -> runStyleTransfer(call, result)
            else -> result.notImplemented()
        }
    }

    private fun runStyleTransfer(call: MethodCall, result: MethodChannel.Result) {
        val modelPath = call.argument<String>("modelPath")
        val inputPath = call.argument<String>("inputPath")
        val outputPath = call.argument<String>("outputPath")
        val modelName = call.argument<String>("modelName") ?: "unknown"

        if (modelPath.isNullOrBlank() || inputPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
            result.success(
                unavailable("Missing model, input, or output path.", modelName),
            )
            return
        }

        Thread {
            val response = try {
                execute(modelName, modelPath, inputPath, outputPath)
            } catch (error: Throwable) {
                mapOf(
                    "success" to false,
                    "status" to "error",
                    "message" to (error.message ?: "ONNX inference failed."),
                    "modelName" to modelName,
                )
            }
            Handler(Looper.getMainLooper()).post {
                result.success(response)
            }
        }.start()
    }

    private fun execute(
        modelName: String,
        modelPath: String,
        inputPath: String,
        outputPath: String,
    ): Map<String, Any?> {
        val modelFile = File(modelPath)
        if (!modelFile.exists()) {
            return unavailable("ONNX model file is not installed for local evaluation.", modelName)
        }

        val inputFile = File(inputPath)
        if (!inputFile.exists()) {
            return unavailable("Input image file is missing.", modelName)
        }

        val bitmap = BitmapFactory.decodeFile(inputFile.absolutePath)
            ?: return unavailable("Input image could not be decoded.", modelName)
        val source = bitmap.copy(Bitmap.Config.ARGB_8888, false)
        if (source !== bitmap) {
            bitmap.recycle()
        }

        val started = System.nanoTime()
        val env = OrtEnvironment.getEnvironment()
        OrtSession.SessionOptions().use { options ->
            env.createSession(modelFile.absolutePath, options).use { session ->
                val inputName = session.inputNames.first()
                val inputShape = tensorShape(session.inputInfo[inputName]?.info)
                val outputName = session.outputNames.first()
                val outputShape = tensorShape(session.outputInfo[outputName]?.info)
                fixedInputMismatch(inputShape, source.width, source.height)?.let { message ->
                    return mapOf(
                        "success" to false,
                        "status" to "fixed_size_rejected",
                        "message" to message,
                        "modelName" to modelName,
                        "inputWidth" to source.width,
                        "inputHeight" to source.height,
                        "inputShape" to inputShape,
                        "outputShape" to outputShape,
                    )
                }
                val inputTensorShape = longArrayOf(
                    1L,
                    3L,
                    source.height.toLong(),
                    source.width.toLong(),
                )
                val input = OnnxTensorImageCodec.preprocess(source)

                OnnxTensor.createTensor(env, input, inputTensorShape).use { tensor ->
                    session.run(mapOf(inputName to tensor)).use { outputs ->
                        val output = outputs[0] as? OnnxTensor
                            ?: return mapOf(
                                "success" to false,
                                "status" to "error",
                                "message" to "ONNX output was not a tensor.",
                                "modelName" to modelName,
                                "inputWidth" to source.width,
                                "inputHeight" to source.height,
                                "inputShape" to inputShape,
                                "outputShape" to outputShape,
                            )
                        val outputBuffer = output.floatBuffer
                            ?: return mapOf(
                                "success" to false,
                                "status" to "error",
                                "message" to "ONNX output was not a float tensor.",
                                "modelName" to modelName,
                                "inputWidth" to source.width,
                                "inputHeight" to source.height,
                                "inputShape" to inputShape,
                                "outputShape" to outputShape,
                            )
                        val resultBitmap = OnnxTensorImageCodec.postprocess(
                            outputBuffer,
                            source.width,
                            source.height,
                        )
                        saveJpeg(resultBitmap, outputPath)
                        val elapsedMs = ((System.nanoTime() - started) / 1_000_000.0).roundToInt()

                        return mapOf(
                            "success" to true,
                            "status" to "success",
                            "message" to "ONNX style transfer completed.",
                            "modelName" to modelName,
                            "outputPath" to outputPath,
                            "inputWidth" to source.width,
                            "inputHeight" to source.height,
                            "outputWidth" to resultBitmap.width,
                            "outputHeight" to resultBitmap.height,
                            "processingTimeMs" to elapsedMs,
                            "inputShape" to inputShape,
                            "outputShape" to outputShape,
                            "providers" to OrtEnvironment.getAvailableProviders().map { it.name },
                        )
                    }
                }
            }
        }
    }

    private fun saveJpeg(bitmap: Bitmap, outputPath: String) {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        FileOutputStream(outputFile).use { stream ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 92, stream)
        }
    }

    private fun unavailable(message: String, modelName: String): Map<String, Any?> {
        return mapOf(
            "success" to false,
            "status" to "unavailable",
            "message" to message,
            "modelName" to modelName,
        )
    }

    private fun tensorShape(info: Any?): List<Long> {
        val tensorInfo = info as? TensorInfo ?: return emptyList()
        return tensorInfo.shape.toList()
    }

    private fun fixedInputMismatch(shape: List<Long>, width: Int, height: Int): String? {
        if (shape.size < 4) {
            return null
        }
        val expectedHeight = shape[2]
        val expectedWidth = shape[3]
        val hasFixedHeight = expectedHeight > 0
        val hasFixedWidth = expectedWidth > 0
        if (!hasFixedHeight || !hasFixedWidth) {
            return null
        }
        if (expectedHeight == height.toLong() && expectedWidth == width.toLong()) {
            return null
        }
        return "ONNX model input is fixed to ${expectedWidth}x${expectedHeight}; " +
            "Mixelith requires full-frame shape-preserving output, so this model is rejected."
    }

    companion object {
        const val channelName = "mixelith/onnx_style_transfer"
    }
}
