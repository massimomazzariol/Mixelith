package com.mixelith.onnx

import android.graphics.Bitmap
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

internal object OnnxTensorImageCodec {
    fun preprocess(bitmap: Bitmap): FloatBuffer {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        return preprocessPixels(pixels, width, height)
    }

    fun preprocessPixels(pixels: IntArray, width: Int, height: Int): FloatBuffer {
        require(pixels.size == width * height) {
            "Pixel count must match width x height."
        }

        val buffer = ByteBuffer
            .allocateDirect(width * height * 3 * java.lang.Float.BYTES)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        for (channel in 0 until 3) {
            for (pixel in pixels) {
                val value = when (channel) {
                    0 -> (pixel shr 16) and 0xff
                    1 -> (pixel shr 8) and 0xff
                    else -> pixel and 0xff
                }
                buffer.put(value.toFloat())
            }
        }
        buffer.rewind()
        return buffer
    }

    fun postprocess(output: FloatBuffer, width: Int, height: Int): Bitmap {
        val pixels = postprocessPixels(output, width, height)
        return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
    }

    fun postprocessPixels(output: FloatBuffer, width: Int, height: Int): IntArray {
        output.rewind()
        val channelSize = width * height
        val values = FloatArray(channelSize * 3)
        output.get(values)
        val pixels = IntArray(channelSize)

        for (index in 0 until channelSize) {
            val r = values[index].clipByte()
            val g = values[channelSize + index].clipByte()
            val b = values[channelSize * 2 + index].clipByte()
            pixels[index] = (0xff shl 24) or (r shl 16) or (g shl 8) or b
        }

        return pixels
    }

    private fun Float.clipByte(): Int {
        return max(0f, min(255f, this)).roundToInt()
    }
}
